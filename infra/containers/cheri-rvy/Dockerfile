# AIVHAI CHERI RVY toolchain layer.  Issue #95.
#
# The RVY 0.9.9 LLVM, QEMU, OpenSBI and GDB, built by cheribuild at pinned
# source commits.  No published image carries these: the ctsrd/* images on
# Docker Hub are the legacy Xcheri lineage (ctsrd/cheri-sdk ships CTSRD clang
# 17, which rejects both `zcherihybrid` and `y`; ctsrd/qemu-cheri is QEMU 7.0
# with no riscv64y emulator).  Checked by running them on 2026-10-01.
#
# WE AUTHOR NO BUILD LOGIC.  cheribuild knows how to build every component,
# and how they depend on one another -- OpenSBI is compiled by the RVY clang
# and installed beside the RVY QEMU that boots it.  This file supplies
# cheribuild's host dependencies, pins its inputs, and records its outputs.
# That is PLAT-D30's rule (do not re-author what upstream maintains) applied
# to a build orchestrator rather than to a Dockerfile.
#
# CHERIBUILD FOLLOWS BRANCH TIPS, so pinning cheribuild pins only the build
# logic.  Every source is therefore fetched HERE, at the exact commit in
# sources.tsv, and handed to cheribuild through --<target>/source-directory
# with --skip-update.  cheribuild never clones and never pulls; what it builds
# is what sources.tsv says, and the image's labels and provenance file say so
# again so the toolchain behind a result can be read from the digest alone.
#
# DELIBERATELY ABSENT, each with its reason in #95: CheriBSD (2.2 GB and
# hours; a separate image if the red team needs an OS), RVY OpenOCD (FPGA
# debug, pending the consortium's answer), the executable Sail golden model
# (#78 owns the Sail version; it belongs with the Sail chain in `provers`),
# and the RISC-V GNU toolchain, which does not implement RVY at all.
#
# BUILD IT ON A NATIVE amd64 HOST.  LLVM under emulation on an arm64 laptop
# is a day, not an hour.  build.sh refuses nothing here, but the fm host or a
# dispatched CI job is where this belongs.
ARG BASE=ghcr.io/sigil-logic/aivhai-base:latest

# ---------------------------------------------------------------------------
# Stage 1: build.  Everything here except the SDK prefix is thrown away.
# ---------------------------------------------------------------------------
FROM ${BASE} AS build

USER root

# cheribuild's own checks name these: libtoolize, autoreconf, aclocal,
# pixman-1, glib-2.0, bzip2, libattr, libcap-ng and slirp for QEMU
# (build_qemu.py; the first build stopped on libattr, 2026-10-01); cmake and ninja for
# LLVM; flex, bison, texinfo, gmp and mpfr for GDB; dtc for OpenSBI's
# generic platform.  python3-venv because QEMU's configure builds a venv.
# clang, lld and llvm because cheribuild compiles LLVM and QEMU with a clang
# host compiler and QEMU with -flto (seen in a --pretend run, 2026-10-01).
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential make ninja-build cmake pkg-config clang lld llvm \
      python3-venv python3-setuptools \
      libtool autoconf automake autotools-dev \
      libglib2.0-dev libpixman-1-dev libfdt-dev zlib1g-dev libzstd-dev \
      libattr1-dev libcap-ng-dev libslirp-dev \
      bison flex texinfo libgmp-dev libmpfr-dev libexpat1-dev libncurses-dev \
      device-tree-compiler lsb-release bc time file \
 && rm -rf /var/lib/apt/lists/*

COPY sources.tsv /opt/aivhai/provenance/cheri-rvy-sources.tsv

# fetch-pinned.sh fetches exactly the pinned commit and verifies HEAD; see it
# for why the branch column is never fetched.
COPY --chmod=0755 fetch-pinned.sh /usr/local/bin/fetch-pinned
RUN install -d -o aivhai -g aivhai /build

# THE LABELS AND sources.tsv ARE TWO RECORDS OF ONE THING.  build.sh passes
# the commits as build args read from sources.tsv, so they cannot be typed
# twice; this step refuses to build if a caller passed anything else.
ARG CHERIBUILD_COMMIT
ARG RVY_LLVM_COMMIT
ARG RVY_QEMU_COMMIT
ARG RVY_OPENSBI_COMMIT
ARG RVY_GDB_COMMIT
RUN set -eu; T=/opt/aivhai/provenance/cheri-rvy-sources.tsv; \
    for kv in "cheribuild=$CHERIBUILD_COMMIT" "rvy-llvm=$RVY_LLVM_COMMIT" \
              "rvy-qemu=$RVY_QEMU_COMMIT" "opensbi=$RVY_OPENSBI_COMMIT" "rvy-gdb=$RVY_GDB_COMMIT"; do \
      k="${kv%%=*}"; v="${kv#*=}"; \
      want="$(awk -F'\t' -v k="$k" '$1==k{print $4}' "$T")"; \
      [ -n "$v" ] && [ "$v" = "$want" ] || { echo "cheri-rvy: build arg for $k is '$v', sources.tsv pins '$want'; build with infra/containers/build.sh" >&2; exit 1; }; \
    done

USER aivhai
WORKDIR /build

RUN set -eux; \
    fetch-pinned cheribuild /build/cheribuild; \
    fetch-pinned rvy-llvm   /build/src/rvy-llvm-project; \
    fetch-pinned rvy-qemu   /build/src/rvy-qemu; \
    fetch-pinned opensbi    /build/src/rvy-opensbi; \
    fetch-pinned rvy-gdb    /build/src/rvy-gdb

# The SDK lands where cheribuild's own RVY layout puts it, so a cheribuild run
# INSIDE this image (or TestRIG, or a performer) finds it without flags.
ENV RVY_SDK=/opt/aivhai/rvy-sdk
USER root
RUN install -d -o aivhai -g aivhai "$RVY_SDK"
USER aivhai

# One RUN, because cheribuild resolves the inter-target dependencies itself
# and splitting it would only re-derive them.  Release builds without
# assertions: this is a toolchain to run, not to debug.  QEMU is limited to
# the two RVY system emulators, which is what the image is for.
#
# --enable-rvfi-dii IS REQUIRED, AND cheribuild DOES NOT PASS IT.  CHERI QEMU
# compiles its RVFI-DII interface -- what TestRIG drives for tandem runs of Sail
# against QEMU, and half of PLAT-D47's reason for this image -- only under that
# configure flag (configure:824); the rvfi-fixes branch carries the code with
# it switched off.  The first published image lacked it: its QEMU rejected
# -rvfi-dii-port as an invalid option, exactly as it rejects a made-up one.
# Found by the HOARDE Copilot review on #128 (2026-10-02).
ARG JOBS=""
RUN set -eux; \
    J="${JOBS:-$(nproc)}"; \
    /build/cheribuild/cheribuild.py \
      --skip-update --no-confirm-clone \
      --source-root=/build/src --build-root=/build/build --output-root=/build/output \
      --tools-root=/build/tools --rvy-sdk-root="$RVY_SDK" \
      --make-jobs="$J" \
      --rvy-llvm/source-directory=/build/src/rvy-llvm-project \
      --rvy-llvm/build-type=Release --rvy-llvm/no-assertions \
      --rvy-qemu/source-directory=/build/src/rvy-qemu \
      --rvy-qemu/targets=riscv64y-softmmu,riscv32y-softmmu \
      --rvy-qemu/configure-options=--enable-rvfi-dii \
      --cheri-std093-opensbi/source-directory=/build/src/rvy-opensbi \
      --rvy-gdb/source-directory=/build/src/rvy-gdb \
      rvy-llvm rvy-qemu cheri-std093-opensbi-baremetal-riscv64y-purecap rvy-gdb-native

# Licences come from the source trees that were built, not from a URL that
# names a branch and may since have moved.
RUN set -eux; \
    L="$RVY_SDK/licenses"; install -d -m 0755 "$L"; \
    cp /build/cheribuild/LICENSE                 "$L/cheribuild.LICENSE"; \
    cp /build/src/rvy-llvm-project/llvm/LICENSE.TXT "$L/llvm.LICENSE.TXT"; \
    cp /build/src/rvy-qemu/COPYING               "$L/qemu.COPYING"; \
    cp /build/src/rvy-qemu/LICENSE               "$L/qemu.LICENSE"; \
    cp /build/src/rvy-opensbi/COPYING.BSD        "$L/opensbi.COPYING.BSD"; \
    cp /build/src/rvy-gdb/COPYING3               "$L/gdb.COPYING3"; \
    cp /opt/aivhai/provenance/cheri-rvy-sources.tsv "$RVY_SDK/SOURCES.tsv"

# cheribuild installs OpenSBI under its cheri-std093 SDK root even for the RVY
# build -- the target is cheri-std093-opensbi, retargeted -- so it is gathered
# into the RVY prefix here, beside the QEMU that boots it.
RUN set -eux; \
    src=/build/tools/cheri-std093-sdk/opensbi/riscv64y-purecap; \
    test -s "$(find "$src" -name fw_dynamic.bin | head -1)"; \
    install -d "$RVY_SDK/opensbi"; cp -a "$src" "$RVY_SDK/opensbi/"

# ---------------------------------------------------------------------------
# Stage 2: the image.  The SDK prefix and the runtime libraries it links.
# ---------------------------------------------------------------------------
FROM ${BASE}

ARG CHERIBUILD_COMMIT
ARG RVY_LLVM_COMMIT
ARG RVY_QEMU_COMMIT
ARG RVY_OPENSBI_COMMIT
ARG RVY_GDB_COMMIT

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      sl.layer="cheri-rvy" \
      org.opencontainers.image.description="CHERI RVY 0.9.9 toolchain: LLVM, QEMU (RVFI-DII), OpenSBI, GDB, built by cheribuild at pinned commits" \
      org.opencontainers.image.licenses="Apache-2.0 WITH LLVM-exception AND GPL-2.0-only AND BSD-2-Clause AND GPL-3.0-or-later" \
      sl.licenses.dir="/opt/aivhai/rvy-sdk/licenses" \
      sl.sources="/opt/aivhai/rvy-sdk/SOURCES.tsv" \
      sl.cheribuild.commit="${CHERIBUILD_COMMIT}" \
      sl.rvy-llvm.commit="${RVY_LLVM_COMMIT}" \
      sl.rvy-qemu.commit="${RVY_QEMU_COMMIT}" \
      sl.rvy-opensbi.commit="${RVY_OPENSBI_COMMIT}" \
      sl.rvy-gdb.commit="${RVY_GDB_COMMIT}"

USER root
# Runtime only: what the built binaries link against, not what built them.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libglib2.0-0 libpixman-1-0 libfdt1 libzstd1 libgmp10 libmpfr6 \
      libexpat1 libncursesw6 libpython3.10 libattr1 libcap-ng0 libslirp0 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/aivhai/rvy-sdk /opt/aivhai/rvy-sdk
COPY sources.tsv /opt/aivhai/provenance/cheri-rvy-sources.tsv
COPY --chmod=0755 smoke.sh /opt/aivhai/rvy-sdk/bin/aivhai-cheri-rvy-smoke

ENV RVY_SDK=/opt/aivhai/rvy-sdk \
    PATH="/opt/aivhai/rvy-sdk/bin:${PATH}"

USER aivhai
