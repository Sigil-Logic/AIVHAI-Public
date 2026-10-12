#!/bin/sh
# fetch-pinned.sh --- check out exactly the commit sources.tsv pins for one source.
#
# Status:  Living script
# Version: 1.0.0
# Date:    2026-10-01
# Project: AIVHAI
# Issue:   https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/95
#
# Usage:  fetch-pinned.sh KEY DEST [SOURCES]
#
# GitHub serves a commit by SHA, so a depth-1 fetch of exactly the pinned
# object is enough.  HEAD is then VERIFIED against the pin rather than
# trusted, so a moved branch cannot change what is built -- the branch name
# in sources.tsv is a human label and is never fetched.
set -eu

key="${1:?usage: fetch-pinned.sh KEY DEST [SOURCES]}"
dest="${2:?usage: fetch-pinned.sh KEY DEST [SOURCES]}"
sources="${3:-/opt/aivhai/provenance/cheri-rvy-sources.tsv}"

row="$(awk -F'\t' -v k="$key" '$1==k' "$sources")"
[ -n "$row" ] || { echo "fetch-pinned: no row for $key in $sources" >&2; exit 1; }
repo="$(printf '%s\n' "$row" | cut -f2)"
sha="$(printf '%s\n' "$row" | cut -f4)"
# Exactly 40 lowercase hex digits.  `[0-9a-f]*` alone would match one hex
# digit followed by ANYTHING (HOARDE Codex, #128), so non-hex is rejected first.
case "$sha" in
  ""|*[!0-9a-f]*) echo "fetch-pinned: $key pin is not a lowercase hex SHA: '$sha'" >&2; exit 1 ;;
esac
[ "${#sha}" -eq 40 ] || { echo "fetch-pinned: $key pin is not 40 hex digits: '$sha'" >&2; exit 1; }

git init -q "$dest"
git -C "$dest" remote add origin "https://github.com/$repo.git"
git -C "$dest" fetch -q --depth 1 origin "$sha"
git -C "$dest" checkout -q FETCH_HEAD
got="$(git -C "$dest" rev-parse HEAD)"
[ "$got" = "$sha" ] || { echo "fetch-pinned: $key checked out $got, pinned $sha" >&2; exit 1; }
echo "fetch-pinned: $key $repo $sha"
