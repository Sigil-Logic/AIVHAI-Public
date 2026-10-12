#!/usr/bin/env bash
# pin-images.sh --- resolve every upstream image to an immutable digest.
#
# Status:  Living script
# Version: 1.0.0
# Date:    2026-09-22
# Project: AIVHAI
# Issue:   https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/67
#
# Usage:  infra/containers/pin-images.sh          # resolve and rewrite the manifest
#         infra/containers/pin-images.sh --check  # fail if the manifest has drifted
#
# WHY.  PLAT-D28 requires every image this platform depends on to be named by
# digest.  A tag is a moving target: `ghcr.io/galoisinc/cryptol:nightly` is a
# different image every day, so a proof recorded against it cannot be
# reproduced and a proof budget measured against it means nothing.
#
# IT RESOLVES FOR linux/amd64 SPECIFICALLY.  PLAT-D03 makes the amd64
# container the authoritative toolchain, and a multi-arch tag resolves to a
# different digest per platform -- so pinning "the" digest of a manifest list
# would pin something that is not what runs.  The per-platform digest is what
# goes in the manifest, and the list digest is recorded beside it so a reader
# can tell which is which.
#
# --check IS THE CI SHAPE.  It re-resolves and compares, so a tag that has
# moved is reported rather than silently followed.  Movement is expected for
# :nightly and is not itself a failure of ours; it is a prompt to re-pin
# deliberately and record that a tool version changed under an evidence
# artifact.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$HERE/images.json"
PLATFORM="${AIVHAI_PLATFORM:-linux/amd64}"
CHECK=false
[ "${1:-}" = "--check" ] && CHECK=true

command -v docker >/dev/null || { echo "pin-images: docker is not installed" >&2; exit 2; }
command -v jq >/dev/null     || { echo "pin-images: jq is not installed" >&2; exit 2; }

# resolve <ref> -> "<platform-digest> <list-digest>"; empty on failure.
resolve() {
  local ref="$1" raw mt list plat
  raw=$(docker manifest inspect "$ref" 2>/dev/null) || return 1
  mt=$(jq -r '.mediaType // ""' <<<"$raw")
  case "$mt" in
    *manifest.list*|*image.index*)
      list=$(docker manifest inspect -v "$ref" 2>/dev/null \
             | jq -r 'if type=="array" then .[0].Descriptor.digest else .Descriptor.digest end' 2>/dev/null)
      plat=$(jq -r --arg os "${PLATFORM%%/*}" --arg arch "${PLATFORM##*/}" '
               .manifests[] | select(.platform.os==$os and .platform.architecture==$arch)
               | .digest' <<<"$raw" | head -1)
      ;;
    *)
      # A single-platform image: the tag resolves straight to one manifest.
      plat=$(docker manifest inspect -v "$ref" 2>/dev/null \
             | jq -r 'if type=="array" then .[0].Descriptor.digest else .Descriptor.digest end' 2>/dev/null)
      list=""
      ;;
  esac
  [ -n "$plat" ] && [ "$plat" != "null" ] || return 1
  printf '%s %s\n' "$plat" "${list:-}"
}

[ -r "$MANIFEST" ] || { echo "pin-images: cannot read $MANIFEST" >&2; exit 2; }

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT

# The loop runs in a subshell behind the pipe, so it cannot carry counters
# out; every verdict is recomputed below from the file it writes.
jq -r '.images[] | [.ref, (.digest // "")] | @tsv' "$MANIFEST" \
| while IFS=$'\t' read -r ref old; do
    if out=$(resolve "$ref"); then
      new=$(awk '{print $1}' <<<"$out")
      if [ "$new" = "$old" ]; then
        printf '  same    %-62s %s\n' "$ref" "${new:0:19}"
      elif [ -z "$old" ]; then
        printf '  PINNED  %-62s %s\n' "$ref" "${new:0:19}"
      else
        printf '  MOVED   %-62s %s -> %s\n' "$ref" "${old:0:19}" "${new:0:19}"
      fi
      printf '%s\t%s\t%s\n' "$ref" "$new" "$(awk '{print $2}' <<<"$out")" >> "$tmp"
    else
      printf '  FAIL    %-62s could not resolve for %s\n' "$ref" "$PLATFORM"
      printf '%s\t%s\t\n' "$ref" "$old" >> "$tmp"
    fi
  done

resolved=$(awk -F'\t' '$2!=""' "$tmp" | wc -l | tr -d ' ')
total=$(jq '.images | length' "$MANIFEST")
unresolved=$(( total - resolved ))

if $CHECK; then
  drift=0
  while IFS=$'\t' read -r ref new _; do
    old=$(jq -r --arg r "$ref" '.images[] | select(.ref==$r) | .digest // ""' "$MANIFEST")
    [ -n "$new" ] && [ "$new" != "$old" ] && drift=1
  done < "$tmp"
  echo
  echo "pin-images: $resolved/$total resolved for $PLATFORM"
  [ "$drift" -eq 0 ] || { echo "pin-images: DRIFT -- a pinned tag now resolves elsewhere; re-pin deliberately" >&2; exit 1; }
  echo "pin-images: no drift"
  exit 0
fi

# Rewrite the manifest, preserving every field but the digests.
python3 - "$MANIFEST" "$tmp" <<'PY'
import json, sys
mp, tp = sys.argv[1], sys.argv[2]
m = json.load(open(mp))
res = {}
for line in open(tp):
    parts = line.rstrip("\n").split("\t")
    if len(parts) >= 2 and parts[1]:
        res[parts[0]] = (parts[1], parts[2] if len(parts) > 2 else "")
for img in m["images"]:
    if img["ref"] in res:
        d, l = res[img["ref"]]
        img["digest"] = d
        if l:
            img["listDigest"] = l
        elif "listDigest" in img:
            del img["listDigest"]
json.dump(m, open(mp, "w"), indent=2, sort_keys=False)
open(mp, "a").write("\n")
PY
echo
echo "pin-images: $resolved/$total resolved for $PLATFORM; $unresolved unresolved"
echo "pin-images: wrote $MANIFEST"
