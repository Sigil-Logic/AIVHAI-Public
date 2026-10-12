#!/usr/bin/env bash
# build.sh --- build an AIVHAI toolchain image for the authoritative platform.
#
# Status:  Living script
# Version: 1.3.0
# Date:    2026-10-09
# Project: AIVHAI
# Issue:   https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/67
#          https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/113
#          https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/156
#
# Usage:  infra/containers/build.sh <layer> [--push]
#         infra/containers/build.sh base
#         infra/containers/build.sh extended-cv --push
#
# WHY THE PLATFORM LIVES HERE AND NOT IN THE DOCKERFILES.  PLAT-D03 makes
# linux/amd64 the authoritative toolchain, and the development laptops are
# arm64 -- so a build that silently follows the host produces an image whose
# proof timings mean something different, and nothing about it looks wrong.
# Hardcoding `FROM --platform=` in each Dockerfile spreads the decision across
# five files and buildkit warns about it besides.  It is asserted once, here,
# and stamped into the image so a mis-built one can be identified afterwards
# rather than merely assumed not to exist.
#
# LAYERS COMPOSE THROUGH BUILD ARGS, not through hardcoded FROM lines, so a
# local build chains local images and a release build chains published
# digests.  That is what lets the same Dockerfile serve both.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM=linux/amd64
REGISTRY="${AIVHAI_REGISTRY:-ghcr.io/sigil-logic}"
TAG="${AIVHAI_TAG:-dev}"
PUSH=false

# `ci` and `cd` are the CI and CD images (#155, #156, PLAT-D54): ubuntu:24.04,
# outside the chain, no parent.
usage() { echo "usage: $0 <base|solvers|hdl-formal|provers|haskell-galois|extended-cv|cheri-rvy|coral|ci|cd> [--push]" >&2; exit 2; }
[ $# -ge 1 ] || usage
LAYER="$1"; shift
[ -d "$HERE/$LAYER" ] || { echo "build: no layer directory $HERE/$LAYER" >&2; usage; }

# coral is the one image whose build context is NOT in this repository.
# PLAT-D30 builds it from the definitions the corpus already carries rather
# than from copies here, so the corpus path is a required parameter and not a
# guess -- a wrong guess would silently build nothing or build the wrong thing.
if [ "$LAYER" = coral ]; then
  EVERYTHING="${AIVHAI_EVERYTHING:-}"
  [ -n "$EVERYTHING" ] || {
    echo "build: coral needs AIVHAI_EVERYTHING set to the AIVHAI-Everything checkout" >&2
    echo "  e.g. AIVHAI_EVERYTHING=~/Sandboxes/SigilLogic/AIVHAI-Everything $0 coral" >&2
    exit 2; }
  CORAL_DF="$EVERYTHING/Hardware/Google/coralnpu/utils/coralnpu.dockerfile"
  [ -r "$CORAL_DF" ] || {
    echo "build: $CORAL_DF is missing; is the coralnpu submodule checked out?" >&2
    exit 2; }
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --push) PUSH=true ;;
    *) echo "build: unknown argument '$1'" >&2; usage ;;
  esac
  shift
done

# The fm and cli hosts run rootless podman, not Docker (PLAT-D31).  podman
# accepts every invocation below unchanged, so the engine is a parameter
# rather than a second script: AIVHAI_DOCKER=podman.
DOCKER="${AIVHAI_DOCKER:-docker}"
command -v "$DOCKER" >/dev/null || { echo "build: $DOCKER is not installed" >&2; exit 2; }

# UNDER PODMAN, BUILD IN A STORE OF OUR OWN, NOT THROUGH THE SHARED ONE.
# The hosts' /etc/containers/storage.conf adds root's read-only agent store,
# /var/lib/aivhai/images, to every rootless user (bootstrap.sh).  A build whose
# base layer is already in that store reuses it -- "Copying blob ... skipped:
# already exists" -- and its files belong to host root, which is outside the
# caller's uid mapping and so presents as 65534.  Its /tmp is also 1755, not
# 1777.  apt's sandbox user _apt then cannot create its temporary file, the
# signature check never runs, and apt reports every repository as unsigned.
# Measured on fm, 2026-10-01, for stock ubuntu:22.04 as well as aivhai-base.
#
# agent-wrapper.sh meets the same unmapped /tmp at RUN time and bind-mounts a
# caller-owned one.  A build cannot do that for every RUN step, so it avoids
# the shared store instead: a storage.conf with no additionalimagestores and a
# graphroot of the caller's own, so every layer is unpacked under the caller's
# mapping.  Nothing about the host or the Dockerfiles changes.
#
# Override with AIVHAI_PODMAN_STORE; the same CONTAINERS_STORAGE_CONF must be
# used to run or push the result, and the path is printed for that reason.
if [ "$(basename "$DOCKER")" = podman ] && [ -z "${CONTAINERS_STORAGE_CONF:-}" ]; then
  PSTORE="${AIVHAI_PODMAN_STORE:-$HOME/.local/share/aivhai-build}"
  mkdir -p "$PSTORE/storage"
  cat > "$PSTORE/storage.conf" <<STORAGE
# Written by AIVHAI infra/containers/build.sh.  A build-only store: no
# additionalimagestores, so no layer is shared with root's agent store.
[storage]
driver = "overlay"
graphroot = "$PSTORE/storage"
STORAGE
  export CONTAINERS_STORAGE_CONF="$PSTORE/storage.conf"
  echo "build: podman store $PSTORE/storage (CONTAINERS_STORAGE_CONF=$CONTAINERS_STORAGE_CONF)"
fi

IMAGE="$REGISTRY/aivhai-$LAYER:$TAG"

# Each layer's dependencies, passed as build args so the chain is explicit and
# local.  A layer that names its base in a FROM line cannot be built against a
# locally modified parent, which is exactly what iterating on the base needs.
declare -a ARGS=()
case "$LAYER" in
  solvers|hdl-formal|cheri-rvy)
    ARGS+=( --build-arg "BASE=$REGISTRY/aivhai-base:$TAG" )
    ;;
  provers|haskell-galois)
    # Both take their solvers from the solvers layer by COPY --from (#113):
    # Sail needs a z3 at run time, and the Galois tools need the whole set.
    # So the solvers image must exist before either builds, exactly as
    # hdl-formal and solvers must before extended-cv.
    ARGS+=( --build-arg "BASE=$REGISTRY/aivhai-base:$TAG"
            --build-arg "SOLVERS=$REGISTRY/aivhai-solvers:$TAG" )
    ;;
  extended-cv)
    ARGS+=( --build-arg "HDL_FORMAL=$REGISTRY/aivhai-hdl-formal:$TAG"
            --build-arg "SOLVERS=$REGISTRY/aivhai-solvers:$TAG" )
    ;;
esac

# The Galois layer composes seven upstream images, and PLAT-D28 says by digest.
# They are read out of images.json here rather than written into the
# Dockerfile, so a digest lives in exactly one place and pin-images.sh stays
# the only thing that edits it.  An unpinned entry falls back to its tag and
# says so, rather than producing a reference that cannot be resolved.
pinned() {
  local out
  out=$(jq -r --arg r "$1" '
          .images[] | select(.ref==$r)
          | if (.digest // "") == "" then .ref
            else ((.ref | split(":")[0]) + "@" + .digest) end' "$HERE/images.json")
  if [ -z "$out" ]; then
    echo "build: $1 is not in images.json" >&2; exit 1
  fi
  case "$out" in
    *@sha256:*) ;;
    *) echo "build: WARNING -- $1 is unpinned; building against a moving tag" >&2 ;;
  esac
  printf '%s' "$out"
}

if [ "$LAYER" = haskell-galois ]; then
  ARGS+=(
    --build-arg "CRYPTOL_IMAGE=$(pinned ghcr.io/galoisinc/cryptol:nightly)"
    --build-arg "SAW_IMAGE=$(pinned ghcr.io/galoisinc/saw:nightly)"
    --build-arg "CRUX_LLVM_IMAGE=$(pinned ghcr.io/galoisinc/crux-llvm:nightly)"
    --build-arg "CRUX_MIR_IMAGE=$(pinned ghcr.io/galoisinc/crux-mir:nightly)"
    --build-arg "MIR_JSON_IMAGE=$(pinned ghcr.io/galoisinc/mir-json:nightly)"
    --build-arg "CRYPTOL_REMOTE_IMAGE=$(pinned ghcr.io/galoisinc/cryptol-remote-api:nightly)"
    --build-arg "SAW_REMOTE_IMAGE=$(pinned ghcr.io/galoisinc/saw-remote-api:nightly)"
  )
fi

# cheri-rvy's source commits live in exactly one place, sources.tsv.  They are
# passed as build args so the image's labels can name them, and the Dockerfile
# refuses to build if they disagree with the sources.tsv it copied in -- so
# the labels cannot be typed twice and drift.
if [ "$LAYER" = cheri-rvy ]; then
  pin() {
    local v
    v=$(awk -F'\t' -v k="$1" '$1==k{print $4}' "$HERE/cheri-rvy/sources.tsv")
    [ -n "$v" ] || { echo "build: cheri-rvy/sources.tsv has no row for $1" >&2; exit 1; }
    printf '%s' "$v"
  }
  ARGS+=(
    --build-arg "CHERIBUILD_COMMIT=$(pin cheribuild)"
    --build-arg "RVY_LLVM_COMMIT=$(pin rvy-llvm)"
    --build-arg "RVY_QEMU_COMMIT=$(pin rvy-qemu)"
    --build-arg "RVY_OPENSBI_COMMIT=$(pin opensbi)"
    --build-arg "RVY_GDB_COMMIT=$(pin rvy-gdb)"
  )
  [ -n "${AIVHAI_JOBS:-}" ] && ARGS+=( --build-arg "JOBS=$AIVHAI_JOBS" )
fi

echo "build: $IMAGE for $PLATFORM"
if [ "$LAYER" = coral ]; then
  # Built where its definition lives, with the corpus as context.
  # GHCR links a package to a repository from org.opencontainers.image.source,
  # and nothing else.  Every other layer carries it in its own Dockerfile; coral
  # has no Dockerfile of ours (PLAT-D30), so it would inherit Google's labels
  # and arrive UNLINKED -- which is the exact condition that stopped CI
  # publishing in #67, and which also leaves the package `internal` rather than
  # the public PLAT-D28 requires.  Applied here because here is the only place
  # we control.
  "$DOCKER" build \
    --platform "$PLATFORM" \
    --label "sl.platform=$PLATFORM" \
    --label "sl.source=AIVHAI-Everything/Hardware/Google/coralnpu" \
    --label "org.opencontainers.image.source=https://github.com/Sigil-Logic/AIVHAI-Sigil" \
    --label "org.opencontainers.image.description=Coral NPU Bazel toolchain, built from the corpus definitions per PLAT-D30" \
    --label "org.opencontainers.image.licenses=Apache-2.0" \
    -f "$CORAL_DF" \
    -t "$IMAGE" \
    "$EVERYTHING/Hardware/Google/coralnpu" || { echo "build: FAILED for coral" >&2; exit 1; }
  got=$("$DOCKER" image inspect "$IMAGE" --format '{{.Os}}/{{.Architecture}}' 2>/dev/null)
  [ "$got" = "$PLATFORM" ] || { echo "build: image reports $got, not $PLATFORM" >&2; exit 1; }
  echo "build: $IMAGE is $got"
  $PUSH && { "$DOCKER" push "$IMAGE" && echo "build: pushed $IMAGE"; }
  exit 0
fi

"$DOCKER" build \
  --platform "$PLATFORM" \
  --label "sl.platform=$PLATFORM" \
  --label "sl.built-from=$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo unknown)" \
  --label "org.opencontainers.image.revision=$(git -C "$HERE" rev-parse HEAD 2>/dev/null || echo unknown)" \
  ${ARGS[@]+"${ARGS[@]}"} \
  -t "$IMAGE" \
  "$HERE/$LAYER" || { echo "build: FAILED for $LAYER" >&2; exit 1; }

# Assert what was actually produced.  A --platform flag that was ignored, or a
# buildx driver defaulting elsewhere, is otherwise invisible until a proof
# runs at the wrong speed on the wrong architecture.
got=$("$DOCKER" image inspect "$IMAGE" --format '{{.Os}}/{{.Architecture}}' 2>/dev/null)
if [ "$got" != "$PLATFORM" ]; then
  echo "build: image reports $got, not $PLATFORM -- refusing to tag it as authoritative" >&2
  exit 1
fi
echo "build: $IMAGE is $got"

# cheri-rvy: verify the FINAL labels, not the build args.  The Dockerfile
# asserts the args against sources.tsv, but a caller's --label overrides a
# Dockerfile LABEL after that assertion has passed (HOARDE Codex, #128).  So
# the guarantee is checked on what was produced, as the platform is above.
if [ "$LAYER" = cheri-rvy ]; then
  for kv in cheribuild:sl.cheribuild.commit rvy-llvm:sl.rvy-llvm.commit \
            rvy-qemu:sl.rvy-qemu.commit opensbi:sl.rvy-opensbi.commit rvy-gdb:sl.rvy-gdb.commit; do
    k="${kv%%:*}"; lab="${kv#*:}"
    want=$(awk -F'\t' -v k="$k" '$1==k{print $4}' "$HERE/cheri-rvy/sources.tsv")
    have=$("$DOCKER" image inspect "$IMAGE" --format "{{index .Config.Labels \"$lab\"}}" 2>/dev/null)
    if [ -z "$want" ] || [ "$have" != "$want" ]; then
      echo "build: label $lab is '$have', sources.tsv pins '$want' -- refusing" >&2
      exit 1
    fi
  done
  echo "build: all five source labels match sources.tsv"
fi

if $PUSH; then
  # PLAT-D28: both registries, and public for anything built from open-source
  # tools.  Visibility is a registry-side setting, not something a push can
  # assert, so it is checked by the workflow rather than claimed here.
  "$DOCKER" push "$IMAGE" || { echo "build: push failed" >&2; exit 1; }
  echo "build: pushed $IMAGE"
fi
