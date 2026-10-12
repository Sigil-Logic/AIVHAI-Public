# AIVHAI HDL formal layer.  Issue #67, Tier 3.
#
# Yosys built FROM OUR FORK, plus SBY, sv2v, and the Bluespec compiler.
#
# WHY NOT hdlc/formal, WHICH ALREADY EXISTS.  It is upstream Yosys, and
# docs/tools/yosys-toolchain.md requires a proof to be attributable to OUR
# binary rather than to any Yosys.  So we need both, and images.json pins
# hdlc/yosys as the baseline half of that negative control.  Replacing this
# layer with the upstream image would quietly delete the distinction the
# negative control exists to make.
#
# NOTHING UPSTREAM COMBINES BLUESPEC WITH THE YOSYS FORMAL CHAIN, which is why
# this layer is authored rather than pulled, and why #67 says to build it
# first: it is the image that runs the 37 licence-free proof tasks.
ARG BASE=ghcr.io/sigil-logic/aivhai-base:latest
FROM ${BASE}

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      sl.layer="hdl-formal" \
      org.opencontainers.image.description="Yosys from our fork, SBY, sv2v, bsc, verible, bender, fusesoc" \
      org.opencontainers.image.licenses="ISC AND BSD-3-Clause AND Apache-2.0 AND BSD-2-Clause AND GPL-2.0-only" \
      sl.licenses.manifest="/opt/aivhai/licenses/MANIFEST.tsv"

USER root

# ---- build dependencies, removed again at the end of the layer -----------
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential clang bison flex libreadline-dev gawk tcl-dev \
      libffi-dev pkg-config libboost-system-dev libboost-python-dev \
      libboost-filesystem-dev python3-dev \
 && rm -rf /var/lib/apt/lists/*

# CMake from PyPI, not from apt, and this is not a preference.
# docs/tools/yosys-toolchain.md records that Yosys requires CMake >= 3.28;
# Ubuntu 22.04 ships 3.22, which configures far enough to look fine and then
# fails a version check.  The base is 22.04 because the what4-solvers snapshot
# is built for that ABI (see the solvers layer), so the CMake has to come from
# somewhere else rather than the base moving.  PyPI publishes a digest for the
# wheel, so this is pinned properly rather than floating on `pip install cmake`.
ARG CMAKE_VERSION=4.1.2
ARG CMAKE_SHA256=7587a2b2ce48df1fd68a68657b6c5a711b467c346812e46dfb9cd996cd6e2352
RUN set -eux; \
    whl="cmake-${CMAKE_VERSION}-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl"; \
    pip3 download --no-deps --only-binary=:all: --platform manylinux2014_x86_64 \
      --dest /tmp/cm "cmake==${CMAKE_VERSION}"; \
    echo "${CMAKE_SHA256}  /tmp/cm/${whl}" | sha256sum -c -; \
    pip3 install --no-deps "/tmp/cm/${whl}"; \
    rm -rf /tmp/cm; \
    cmake --version | head -1

# ---- Yosys, from Sigil-Logic/yosys ---------------------------------------
# BUILT WITH CMAKE, NOT MAKE.  docs/tools/yosys-toolchain.md calls this "the
# single most useful fact here": Yosys has migrated to CMake and there is no
# Makefile in the tree at all, so the familiar `make config-clang` folklore
# does not apply.  Writing `make` here failed with "No targets specified and
# no makefile found" -- a failure the project had already written down.
# Pinned to a commit, not a branch.  A branch tip is the same problem as a
# :nightly tag: the proof that passes today is not the proof anyone can
# re-run.  YOSYS_REF is set by the build workflow from the fork's recorded
# commit; the default is the branch only so a local exploratory build works,
# and a release build MUST pass a commit.
ARG YOSYS_REPO=https://github.com/Sigil-Logic/yosys.git
ARG YOSYS_REF=main
ENV AIVHAI_YOSYS=/opt/aivhai/yosys
RUN set -eux; \
    git clone --recursive "${YOSYS_REPO}" /tmp/yosys; \
    cd /tmp/yosys; \
    git checkout "${YOSYS_REF}"; \
    resolved="$(git rev-parse HEAD)"; \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${AIVHAI_YOSYS}"; \
    cmake --build build --parallel "$(nproc)"; \
    cmake --install build; \
    install -d -m 0755 /opt/aivhai/provenance; \
    printf 'yosys repo=%s ref=%s commit=%s\n' "${YOSYS_REPO}" "${YOSYS_REF}" "${resolved}" \
      > /opt/aivhai/provenance/yosys; \
    cd /; rm -rf /tmp/yosys
ENV PATH="${AIVHAI_YOSYS}/bin:${PATH}"

# ---- SBY, the formal driver ----------------------------------------------
ARG SBY_REF=main
RUN set -eux; \
    git clone https://github.com/YosysHQ/sby.git /tmp/sby; \
    cd /tmp/sby; git checkout "${SBY_REF}"; \
    resolved="$(git rev-parse HEAD)"; \
    make install PREFIX="${AIVHAI_YOSYS}"; \
    printf 'sby ref=%s commit=%s\n' "${SBY_REF}" "${resolved}" >> /opt/aivhai/provenance/yosys; \
    cd /; rm -rf /tmp/sby

# ---- sv2v, a Haskell binary with no published image ----------------------
# Checksum computed 2026-09-22 and pinned, because a GitHub release asset can
# be replaced in place and a tag on its own is not integrity.
ARG SV2V_VERSION=v0.0.13
ARG SV2V_SHA256=552799a1d76cd177b9b4cc63a3e77823a3d2a6eb4ec006569288abeff28e1ff8
RUN set -eux; \
    curl -fsSL -o /tmp/sv2v.zip \
      "https://github.com/zachjs/sv2v/releases/download/${SV2V_VERSION}/sv2v-Linux.zip"; \
    echo "${SV2V_SHA256}  /tmp/sv2v.zip" | sha256sum -c -; \
    unzip -q /tmp/sv2v.zip -d /tmp/sv2v; \
    install -m 0755 "$(find /tmp/sv2v -name sv2v -type f | head -1)" /opt/aivhai/bin/sv2v; \
    printf 'sv2v version=%s sha256=%s\n' "${SV2V_VERSION}" "${SV2V_SHA256}" \
      > /opt/aivhai/provenance/sv2v; \
    rm -rf /tmp/sv2v.zip /tmp/sv2v; \
    sv2v --version

# ---- bsc, the Bluespec compiler ------------------------------------------
# No official image exists; Docker Hub 404s.  Installed from the release
# tarball, which is the working precedent TestRIG's testrig-builder set.  The
# checksum is the project's OWN published SHA256SUM line, not one we computed
# -- upstream publishes it, so use it.
ARG BSC_VERSION=2026.01
ARG BSC_SHA256=9f32be4cb34dc025a47d8dddfa119ec8e7a5fd7240b6de31d175aa4e65fd5301
ENV AIVHAI_BSC=/opt/aivhai/bsc
RUN set -eux; \
    curl -fsSL -o /tmp/bsc.tar.gz \
      "https://github.com/B-Lang-org/bsc/releases/download/${BSC_VERSION}/bsc-${BSC_VERSION}-ubuntu-22.04.tar.gz"; \
    echo "${BSC_SHA256}  /tmp/bsc.tar.gz" | sha256sum -c -; \
    install -d -m 0755 "${AIVHAI_BSC}"; \
    tar -xzf /tmp/bsc.tar.gz -C "${AIVHAI_BSC}" --strip-components=1; \
    rm -f /tmp/bsc.tar.gz; \
    printf 'bsc version=%s sha256=%s\n' "${BSC_VERSION}" "${BSC_SHA256}" \
      > /opt/aivhai/provenance/bsc
ENV PATH="${AIVHAI_BSC}/bin:${PATH}" \
    BLUESPECDIR="${AIVHAI_BSC}/lib"

# ---- the HDL ecosystem tools the corpus also needs ----------------------
# verible (lint), bender (IP dependency manager) and fusesoc (build) are Layer
# A entries that no layer supplied.  They sit here rather than in a new layer
# because they serve the same consumers as the formal chain and the agreed
# clustering is four layers, not five.
#
# device-tree-compiler goes in too, even though three DIFFERENT layers want it
# -- cheri-cva6, sail-riscv and Spike.  It is one apt package; duplicating it
# is cheaper than a layer to hold it.
ARG VERIBLE_VERSION=v0.0-4294-gc1d8f5e8
# Measured on the first build and pinned after, the same way the what4-solvers
# archive was: upstream publishes no checksum for these assets, so the honest
# pin is what we actually downloaded, not a number copied from nowhere.
ARG VERIBLE_SHA256=64499cf72cfe88911a015b707a06e18a47effbc0296348b7ca13331d94db6940
RUN set -eux; \
    url="https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VERSION}/verible-${VERIBLE_VERSION}-linux-static-x86_64.tar.gz"; \
    curl -fsSL -o /tmp/verible.tar.gz "$url"; \
    got="$(sha256sum /tmp/verible.tar.gz | awk '{print $1}')"; \
    echo "verible ${VERIBLE_VERSION} sha256=${got}"; \
    if [ -n "${VERIBLE_SHA256}" ] && [ "${got}" != "${VERIBLE_SHA256}" ]; then \
      echo "verible checksum MISMATCH: expected ${VERIBLE_SHA256}" >&2; exit 1; \
    fi; \
    install -d -m 0755 /opt/aivhai/verible; \
    tar -xzf /tmp/verible.tar.gz -C /opt/aivhai/verible --strip-components=1; \
    rm -f /tmp/verible.tar.gz; \
    chmod -R a+rX /opt/aivhai/verible; \
    printf 'verible %s sha256=%s\n' "${VERIBLE_VERSION}" "${got}" > /opt/aivhai/provenance/verible
ENV PATH="/opt/aivhai/verible/bin:${PATH}"

# bender publishes its own .sha256 beside the tarball, so this one is pinned
# from upstream's number rather than from ours.
ARG BENDER_VERSION=0.32.1
ARG BENDER_SHA256=59a36723b056a06b266dc68d4ceedcd0aa17a1c096e8c2ea512af264ff6a13f6
RUN set -eux; \
    curl -fsSL -o /tmp/bender.tar.xz \
      "https://github.com/pulp-platform/bender/releases/download/v${BENDER_VERSION}/bender-x86_64-unknown-linux-gnu.tar.xz"; \
    echo "${BENDER_SHA256}  /tmp/bender.tar.xz" | sha256sum -c -; \
    tar -xJf /tmp/bender.tar.xz -C /tmp \
      --strip-components=1 bender-x86_64-unknown-linux-gnu/bender; \
    install -m 0755 /tmp/bender /opt/aivhai/bin/bender; \
    rm -f /tmp/bender.tar.xz /tmp/bender; \
    printf 'bender %s sha256=%s\n' "${BENDER_VERSION}" "${BENDER_SHA256}" > /opt/aivhai/provenance/bender

# fusesoc is pinned to 2.4.3 BY mocha, not by preference, and PyPI publishes a
# digest for the wheel.  --no-deps keeps pip from resolving a different
# dependency set than the one the corpus was built against.
ARG FUSESOC_VERSION=2.4.3
ARG FUSESOC_SHA256=9ab4a82a5b7d4decbeb8f76049673a1b0806732ab8f807fee285bbc0452b3dc3
RUN set -eux; \
    pip3 download --no-deps --dest /tmp/fs "fusesoc==${FUSESOC_VERSION}"; \
    echo "${FUSESOC_SHA256}  /tmp/fs/fusesoc-${FUSESOC_VERSION}-py3-none-any.whl" | sha256sum -c -; \
    pip3 install "/tmp/fs/fusesoc-${FUSESOC_VERSION}-py3-none-any.whl"; \
    rm -rf /tmp/fs; \
    printf 'fusesoc %s sha256=%s\n' "${FUSESOC_VERSION}" "${FUSESOC_SHA256}" > /opt/aivhai/provenance/fusesoc

RUN apt-get update && apt-get install -y --no-install-recommends device-tree-compiler \
 && rm -rf /var/lib/apt/lists/* \
 && dtc --version

# Build dependencies go, the tools stay -- and the RUNTIME libraries stay with
# them, which the first attempt got wrong.
#
# `make` is in the runtime set, not the build set, and that distinction was
# also learned by trying.  It came in with build-essential, went out with the
# purge, and the image could then hold every proof tool and run no proof: the
# corpus drives its proofs through Makefiles -- cheri-cap-lib's `make
# check-prop` generates the Verilog with bsc and then calls sby.  An image
# that has the tools but cannot execute the recipe that uses them is finished
# from the wrong end.
#
# Purging tcl-dev took libtcl8.6 with it as an orphan, and the image built
# perfectly and shipped a yosys that died on "libtcl8.6.so: cannot open shared
# object file".  A -dev package is headers AND a runtime dependency; removing
# the first removes the second unless the runtime is asked for by name.  So
# the runtime set is reinstalled explicitly after the purge rather than hoped
# to survive it.
RUN apt-get purge -y build-essential clang bison flex libreadline-dev gawk \
      tcl-dev libffi-dev pkg-config python3-dev \
 && apt-get autoremove -y \
 && apt-get update && apt-get install -y --no-install-recommends \
      libtcl8.6 libreadline8 libffi8 zlib1g libgmp10 \
      libboost-system1.74.0 libboost-filesystem1.74.0 \
      python3-click \
      make \
 && rm -rf /var/lib/apt/lists/*

# ---- licence texts for what this layer adds -----------------------------
# Every SPDX identifier below was READ FROM THE TREE, per the rule in
# docs/tools.md, not recalled: Yosys and SBY are ISC (SBY's COPYING is the
# "with or without fee" ISC text, which GitHub does not classify); sv2v and
# bsc are BSD-3-Clause; verible is Apache-2.0; bender Apache-2.0; fusesoc
# BSD-2-Clause; device-tree-compiler GPL-2.0.
#
# bsc's COPYING is worth reading before anyone simplifies this: most of it is
# BSD-3-Clause, and it vendors STP and other components under their own terms.
# The image therefore carries bsc's own LICENSES directory rather than a
# one-line claim about it.
RUN set -eux; \
    L=/opt/aivhai/licenses; install -d -m 0755 "$L"; \
    curl -fsSL -o "$L/yosys.COPYING"   https://raw.githubusercontent.com/YosysHQ/yosys/main/COPYING; \
    curl -fsSL -o "$L/sby.COPYING"     https://raw.githubusercontent.com/YosysHQ/sby/main/COPYING; \
    curl -fsSL -o "$L/sv2v.LICENSE"    https://raw.githubusercontent.com/zachjs/sv2v/master/LICENSE; \
    curl -fsSL -o "$L/bsc.COPYING"     https://raw.githubusercontent.com/B-Lang-org/bsc/main/COPYING; \
    curl -fsSL -o "$L/verible.LICENSE" https://raw.githubusercontent.com/chipsalliance/verible/master/LICENSE; \
    curl -fsSL -o "$L/bender.LICENSE"  https://raw.githubusercontent.com/pulp-platform/bender/master/LICENSE-APACHE 2>/dev/null \
      || curl -fsSL -o "$L/bender.LICENSE" https://raw.githubusercontent.com/pulp-platform/bender/master/LICENSE; \
    curl -fsSL -o "$L/fusesoc.LICENSE" https://raw.githubusercontent.com/olofk/fusesoc/main/LICENSE; \
    cp -r "${AIVHAI_BSC}/LICENSES" "$L/bsc-LICENSES" 2>/dev/null || true; \
    { printf 'component\tspdx\ttext\n'; \
      printf 'yosys\tISC\tyosys.COPYING\n'; \
      printf 'sby\tISC\tsby.COPYING\n'; \
      printf 'sv2v\tBSD-3-Clause\tsv2v.LICENSE\n'; \
      printf 'bsc\tBSD-3-Clause AND others\tbsc.COPYING\n'; \
      printf 'verible\tApache-2.0\tverible.LICENSE\n'; \
      printf 'bender\tApache-2.0 OR MIT\tbender.LICENSE\n'; \
      printf 'fusesoc\tBSD-2-Clause\tfusesoc.LICENSE\n'; \
      printf 'device-tree-compiler\tGPL-2.0-only\t(Debian package; /usr/share/doc/device-tree-compiler/copyright)\n'; \
    } >> "$L/MANIFEST.tsv"; \
    chmod -R a+rX "$L"; \
    for f in yosys.COPYING sby.COPYING sv2v.LICENSE bsc.COPYING verible.LICENSE fusesoc.LICENSE; do \
      test -s "$L/$f" || { echo "hdl-formal: licence text $f is empty or missing" >&2; exit 1; }; \
    done; \
    echo "hdl-formal: licence texts collected"

# THE LAYER PROVES ITS OWN TOOLS RUN BEFORE IT IS ALLOWED TO EXIST, AND IT
# PROVES IT AS THE USER THAT WILL RUN THEM.
#
# "The image built" and "the tools work" are different claims, and so are "the
# tools work" and "the tools work for the user the image runs as".  Both gaps
# were hit here.  The first was libtcl8.6, purged as an orphan with tcl-dev: a
# clean build, a green log, and a yosys that could not start.  The second was
# verible, whose tarball extracts without world-read: the check passed as root
# and the binary was invisible to `aivhai`, which is who actually runs a proof.
#
# So the check runs under `su aivhai`.  A check that runs as root proves the
# image works for nobody who will use it.
USER aivhai
RUN set -eux; \
    yosys -V; \
    sby --version; \
    sv2v --version; \
    bsc -v | head -1; \
    verible-verilog-lint --version | head -1; \
    bender --version; \
    fusesoc --version; \
    dtc --version; \
    make --version | head -1; \
    echo "hdl-formal: every installed tool executes as $(id -un)"
