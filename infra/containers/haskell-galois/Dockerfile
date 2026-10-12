# syntax=docker/dockerfile:1.7
# AIVHAI Galois toolchain layer.  Issue #67, Tier 1 composed.
#
# Cryptol, SAW, Crux-LLVM and the two remote APIs, taken from the images
# Galois already publishes rather than rebuilt, plus the what4-solvers set
# they need at run time, taken from the solvers layer.  Every upstream source
# is referenced BY DIGEST (PLAT-D28); build.sh passes the digests from
# infra/containers/images.json so this file never carries a second copy of
# them to drift.  Crux-MIR and mir-json are parked, not carried -- see #72
# and the note below.
#
# WHY COPY THE BINARIES INSTEAD OF USING THE IMAGES DIRECTLY.  A performer on
# the cli host wants `cryptol` and `saw` in one shell, and the fm host wants
# them in the same image as the provers.  Seven separate images cannot give
# either.  The binaries are statically-ish linked Haskell -- cryptol needs
# only libm, libtinfo.so.6, libz, libgmp and libc, all of which the base
# already carries -- so the copy is a copy and not a repackaging.
#
# THE PATHS ARE DISCOVERED, NOT ASSUMED, and that was learned the hard way.
# A first version used `COPY --from=<stage> /usr/local/bin/<tool>` for all
# seven, which is where cryptol, crux-mir and crux-llvm live -- and is NOT
# where mir-json or saw live.  The build failed on "/usr/local/bin/mir-json:
# not found", and would have failed again on the next one guessed.  COPY
# cannot search, so each tool is located with a bind mount and a `find`
# instead, which works whatever the upstream layout is and, more importantly,
# keeps working when an upstream image moves something.
#
# THE SOLVER SET COMES FROM THE SOLVERS LAYER, ONCE.  Cryptol, SAW and Crux
# find their solvers by name on PATH at run time, and the first revision of
# this layer shipped none.  It reasoned that every Galois image carries its
# own what4-solvers build and that copying them here "would put the same
# 300 MB in the image several times over" -- true of copying from each of the
# seven stages, and beside the point: an image cannot reach another image's
# files, and a `saw` with no `z3` cannot prove anything.  Measured on cli on
# 2026-09-29 as #113.  So the directory the solvers layer installs is copied
# here, as extended-cv already does: one source, one copy, on PATH, so the
# solver a proof names is the one the platform pins (PLAT-D29).
ARG BASE=ghcr.io/sigil-logic/aivhai-base:latest
ARG SOLVERS=ghcr.io/sigil-logic/aivhai-solvers:latest
ARG CRYPTOL_IMAGE=ghcr.io/galoisinc/cryptol:nightly
ARG SAW_IMAGE=ghcr.io/galoisinc/saw:nightly
ARG CRUX_LLVM_IMAGE=ghcr.io/galoisinc/crux-llvm:nightly
ARG CRUX_MIR_IMAGE=ghcr.io/galoisinc/crux-mir:nightly
ARG MIR_JSON_IMAGE=ghcr.io/galoisinc/mir-json:nightly
ARG CRYPTOL_REMOTE_IMAGE=ghcr.io/galoisinc/cryptol-remote-api:nightly
ARG SAW_REMOTE_IMAGE=ghcr.io/galoisinc/saw-remote-api:nightly

FROM ${SOLVERS} AS solvers
FROM ${CRYPTOL_IMAGE} AS cryptol
FROM ${SAW_IMAGE} AS saw
FROM ${CRUX_LLVM_IMAGE} AS cruxllvm
FROM ${CRUX_MIR_IMAGE} AS cruxmir
FROM ${MIR_JSON_IMAGE} AS mirjson
FROM ${CRYPTOL_REMOTE_IMAGE} AS cryptolremote
FROM ${SAW_REMOTE_IMAGE} AS sawremote

FROM ${BASE}

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      sl.layer="haskell-galois" \
      org.opencontainers.image.description="Cryptol, SAW, Crux-LLVM and the remote APIs from Galois published images, with the what4-solvers set on PATH" \
      org.opencontainers.image.licenses="BSD-3-Clause AND GPL-2.0-only WITH Classpath-exception-2.0 AND Apache-2.0 WITH LLVM-exception AND MIT AND GPL-3.0-only AND LicenseRef-ABC-UCBerkeley" \
      sl.licenses.manifest="/opt/aivhai/licenses/MANIFEST.tsv"

USER root
ENV AIVHAI_GALOIS=/opt/aivhai/galois
RUN install -d -m 0755 "${AIVHAI_GALOIS}/bin" /opt/aivhai/provenance

# take <stage-mount> <tool>...: locate each tool anywhere in the source image
# and install it.  Fails loudly with the tool named, rather than copying
# nothing and leaving an image that is missing a tool nobody notices until a
# proof run cannot start.
#
# -perm -u+x and -type f exclude directories and the odd same-named data file;
# `head -1` takes the first hit because several images ship a tool both in a
# bin directory and in a Nix-style store path, and either is the same binary.
RUN --mount=type=bind,from=cryptol,target=/src \
    set -eux; for t in cryptol cryptol-language-server; do \
      f=$(find /src -type f -perm -u+x -name "$t" 2>/dev/null | head -1); \
      [ -n "$f" ] || { echo "haskell-galois: $t not found in the cryptol image" >&2; exit 1; }; \
      install -m 0755 "$f" "/opt/aivhai/galois/bin/$t"; echo "installed $t from $f"; \
    done

RUN --mount=type=bind,from=saw,target=/src \
    set -eux; f=$(find /src -type f -perm -u+x -name saw 2>/dev/null | head -1); \
    [ -n "$f" ] || { echo "haskell-galois: saw not found in the saw image" >&2; exit 1; }; \
    install -m 0755 "$f" /opt/aivhai/galois/bin/saw; echo "installed saw from $f"

RUN --mount=type=bind,from=cruxllvm,target=/src \
    set -eux; f=$(find /src -type f -perm -u+x -name crux-llvm 2>/dev/null | head -1); \
    [ -n "$f" ] || { echo "haskell-galois: crux-llvm not found" >&2; exit 1; }; \
    install -m 0755 "$f" /opt/aivhai/galois/bin/crux-llvm; echo "installed crux-llvm from $f"

# crux-mir IS PARKED, with mir-json, and the reason is a scope decision rather
# than a technical one: AIVHAI has not chosen to use high-assurance Rust, so
# this is a self-imposed dependency serving no proof we intend to run.
#
# Half of it worked, which is the trap.  crux-mir runs on .mir input, but
# crux-mir on RUST SOURCE drives mir-json, and mir-json needs the pinned Rust
# nightly this layer does not carry.  Shipping the half that works invites
# somebody to discover the other half at the worst moment.  So NEITHER is
# copied: not crux-mir, not mir-json.  #113 measured both absent and found
# docs/containers.md still advertising both; the document now says parked.
#
# Tracked on #72 with what it would cost to pick up, including the part that
# gets more expensive with time: nightly-2026-03-21 is a nightly, and
# nightlies are eventually removed from the channel servers.  Meanwhile
# ghcr.io/galoisinc/crux-mir and ghcr.io/galoisinc/mir-json stay pinned in
# images.json, and anyone who needs either runs that image directly.

# mir-json IS DELIBERATELY NOT COPIED, and this was measured rather than
# reasoned.  The binary was copied, it ran, and it produced nothing: mir-json
# is a rustc DRIVER, not a standalone tool, and it needs the Rust nightly the
# SBOM pins -- nightly-2026-03-21 with rustc-dev and rust-src -- which this
# layer does not carry.  A copied mir-json is inert in a way that looks
# installed: it is on PATH, it exits zero, and it does nothing.
#
# That is worse than its absence, so it is absent.  Carrying it properly means
# carrying a whole pinned Rust toolchain, which is a layer-sized decision and
# not a line in this one.  Until that is taken, use the upstream image
# directly: ghcr.io/galoisinc/mir-json, pinned by digest in images.json.

RUN --mount=type=bind,from=cryptolremote,target=/src \
    set -eux; f=$(find /src -type f -perm -u+x -name cryptol-remote-api 2>/dev/null | head -1); \
    [ -n "$f" ] || { echo "haskell-galois: cryptol-remote-api not found" >&2; exit 1; }; \
    install -m 0755 "$f" /opt/aivhai/galois/bin/cryptol-remote-api; echo "installed cryptol-remote-api from $f"

RUN --mount=type=bind,from=sawremote,target=/src \
    set -eux; f=$(find /src -type f -perm -u+x -name saw-remote-api 2>/dev/null | head -1); \
    [ -n "$f" ] || { echo "haskell-galois: saw-remote-api not found" >&2; exit 1; }; \
    install -m 0755 "$f" /opt/aivhai/galois/bin/saw-remote-api; echo "installed saw-remote-api from $f"

# ---- the solver set, from the solvers layer ------------------------------
# One directory per layer is what makes this a copy rather than a reinstall,
# and the same three lines extended-cv uses.  Yices 2.7.0 travels too, by
# prefix: the snapshot's 2.6.5 is what goes on PATH, because a Galois tool is
# guaranteed against the set Galois ships (PLAT-D29), and 2.7.0 is present
# for a consumer that asks for it by prefix -- installed, reachable, and not
# shadowing.  The solver licences travel with the solver binaries; an image
# that drops them is the compliance failure, not the layer that had them.
COPY --from=solvers /opt/aivhai/what4-solvers /opt/aivhai/what4-solvers
COPY --from=solvers /opt/aivhai/yices-2.7.0 /opt/aivhai/yices-2.7.0
COPY --from=solvers /opt/aivhai/licenses /opt/aivhai/licenses-solvers

# Record which digests these came out of.  A binary with no provenance is a
# binary nobody can attribute a proof to, and these arrive from seven images
# and one layer.
ARG CRYPTOL_IMAGE
ARG SAW_IMAGE
ARG CRUX_LLVM_IMAGE
ARG CRUX_MIR_IMAGE
ARG MIR_JSON_IMAGE
ARG CRYPTOL_REMOTE_IMAGE
ARG SAW_REMOTE_IMAGE
ARG SOLVERS
RUN set -eux; \
    { echo "cryptol           ${CRYPTOL_IMAGE}"; \
      echo "saw               ${SAW_IMAGE}"; \
      echo "crux-llvm         ${CRUX_LLVM_IMAGE}"; \
      echo "crux-mir          ${CRUX_MIR_IMAGE} (NOT copied: parked with mir-json, see #72)"; \
      echo "mir-json          ${MIR_JSON_IMAGE} (NOT copied: needs the pinned Rust toolchain; use this image directly)"; \
      echo "cryptol-remote    ${CRYPTOL_REMOTE_IMAGE}"; \
      echo "saw-remote        ${SAW_REMOTE_IMAGE}"; \
      echo "solvers           ${SOLVERS} (the solvers layer, copied; #113)"; \
      sed 's/^/solvers           /' /opt/aivhai/what4-solvers/.provenance; \
    } > /opt/aivhai/provenance/galois; \
    chmod -R a+rx "${AIVHAI_GALOIS}/bin"

# ---- what the Galois tools need at RUNTIME, not just to have been built --
# Two Layer B gaps, and neither is optional for the tools above to be usable.
#
# JDK 8, exactly 8: crucible-jvm and SAW's JVM tests are pinned to it by the
# SBOM.  A newer JDK is not a substitute -- the class-file versions these
# tools read are the point.
#
# clang/LLVM 12 AND 14.  12 is the version llvm-pretty-bc-parser pins, so it
# is the one whose bitcode the parser is known to read; 14 is jammy's default
# and is there because crux-llvm supports a range and a user compiling their
# own C wants a current compiler.  Both come from jammy, so no third-party
# apt repository is added to an image that ships proof tools.
#
# THIS COSTS ROUGHLY 1.5 GB, which is most of what this layer weighs.  It buys
# a crux-llvm that can actually compile C to bitcode; without a clang the tool
# is installed and cannot start a job, which is the same inert-on-PATH shape
# that got mir-json removed.
RUN apt-get update && apt-get install -y --no-install-recommends \
      openjdk-8-jdk-headless \
      clang-12 llvm-12 \
      clang-14 llvm-14 \
 && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Licence texts for what this layer adds.  The Galois tools are BSD-3-Clause,
# read from their repositories; OpenJDK 8 is GPL-2.0 WITH Classpath-exception
# and clang/LLVM is Apache-2.0 WITH LLVM-exception, both of which ship their
# own copyright files as Debian packages, so those are referenced in place
# rather than re-fetched.  The solvers' rows are taken from the manifest the
# solvers layer wrote, with their texts under licenses-solvers/, so this
# manifest lists everything the image redistributes in one place.
RUN set -eux; \
    L=/opt/aivhai/licenses; install -d -m 0755 "$L"; \
    curl -fsSL -o "$L/cryptol.LICENSE"   https://raw.githubusercontent.com/GaloisInc/cryptol/master/LICENSE; \
    curl -fsSL -o "$L/saw-script.LICENSE" https://raw.githubusercontent.com/GaloisInc/saw-script/master/LICENSE; \
    curl -fsSL -o "$L/crucible.LICENSE"  https://raw.githubusercontent.com/GaloisInc/crucible/master/LICENSE; \
    { printf 'component\tspdx\ttext\n'; \
      printf 'cryptol\tBSD-3-Clause\tcryptol.LICENSE\n'; \
      printf 'saw\tBSD-3-Clause\tsaw-script.LICENSE\n'; \
      printf 'crux-llvm\tBSD-3-Clause\tcrucible.LICENSE\n'; \
      printf 'openjdk-8\tGPL-2.0-only WITH Classpath-exception-2.0\t/usr/share/doc/openjdk-8-jdk-headless/copyright\n'; \
      printf 'clang-llvm\tApache-2.0 WITH LLVM-exception\t/usr/share/doc/llvm-14/copyright\n'; \
      awk -F'\t' 'NR>1 { printf "%s\t%s\t../licenses-solvers/%s\n", $1, $2, $3 }' /opt/aivhai/licenses-solvers/MANIFEST.tsv; \
    } > "$L/MANIFEST.tsv"; \
    chmod -R a+rX "$L"; \
    for f in cryptol.LICENSE saw-script.LICENSE crucible.LICENSE; do \
      test -s "$L/$f" || { echo "haskell-galois: licence text $f missing" >&2; exit 1; }; \
    done; \
    test -s /opt/aivhai/licenses-solvers/yices.LICENSE; \
    n=$(( $(wc -l < "$L/MANIFEST.tsv") - 1 )); \
    [ "$n" -ge 12 ] || { echo "haskell-galois: only $n rows in the manifest; the solver rows are missing" >&2; exit 1; }; \
    echo "haskell-galois: $n licence rows, texts collected"

# The Galois tools first, then the solver snapshot they are validated against.
# The snapshot IS on PATH here, as in extended-cv: this image exists to run
# the Galois tools with the solver set Galois ships, so `saw` finding the
# snapshot's z3 by name is the intended behaviour, not a hazard.
ENV PATH="${AIVHAI_GALOIS}/bin:/opt/aivhai/what4-solvers:${PATH}"
USER aivhai

# Checked AS THE RUNTIME USER, because a check that runs as root proves the
# image works for nobody who will use it -- the lesson verible taught in the
# hdl-formal layer, where a tool passed the build and was unreadable to
# `aivhai`.
#
# AND CHECKED BY PROVING SOMETHING, not only by printing versions.  A `saw`
# that starts is not a `saw` that can reach a solver, which is exactly the
# state #113 found.  Two true properties are proved through two different
# solvers, and a false one must come back Invalid: a chain that proves
# everything manufactures confidence, and only the refutation tells a prover
# from an agreeable one (docs/tools/yosys-toolchain.md).
#
# THE GATE KEEPS saw's EXIT STATUS.  The first revision piped saw through
# `tee` and then grepped for Invalid -- and a refuted `prove_print` of one of
# the TRUE properties also prints Invalid and exits 2, which `tee` masked and
# the grep accepted (HOARDE Codex, PR #187 cycle 1; reproduced in the image).
# Now saw's output goes to a file and saw's own status decides under
# `set -e`: the two `prove_print`s must succeed or saw exits nonzero and the
# build stops.  Only then is the Invalid line looked for, and since the
# `prove_print`s succeeded, the sole thing that can have printed it is
# `print r` for the deliberately false property; a false property that
# proved Valid prints no such line and fails the grep.  Version probes are
# command substitutions for the reason given in the solvers layer.
RUN set -eux; \
    cryptol --version >/dev/null; \
    saw --version >/dev/null; \
    crux-llvm --version >/dev/null; \
    for t in z3 yices cvc4 cvc5 boolector bitwuzla abc; do \
      [ "$(command -v "$t")" = "/opt/aivhai/what4-solvers/$t" ] || { echo "haskell-galois: $t does not resolve to the snapshot" >&2; exit 1; }; \
    done; \
    v=$(z3 --version); echo "$v" | head -1; \
    v=$(yices --version); echo "$v" | head -1 | grep -q 2.6.5; \
    v=$(cvc5 --version); echo "$v" | head -1; \
    v=$(clang-12 --version); echo "$v" | head -1; \
    v=$(clang-14 --version); echo "$v" | head -1; \
    v=$(java -version 2>&1); echo "$v" | head -1; \
    { echo 'prove_print z3 {{ \(x:[8]) -> x + 0 == x }};'; \
      echo 'prove_print yices {{ \(x:[8]) -> x * 2 == x + x }};'; \
      echo 'r <- prove z3 {{ \(x:[8]) -> x == 0 }};'; \
      echo 'print r;'; \
    } > /tmp/solver-check.saw; \
    if saw /tmp/solver-check.saw > /tmp/solver-check.out 2>&1; then \
      cat /tmp/solver-check.out; \
    else \
      rc=$?; cat /tmp/solver-check.out; echo "haskell-galois: saw exited $rc; a true property was not proved" >&2; exit "$rc"; \
    fi; \
    grep -q '^Invalid' /tmp/solver-check.out || { echo "haskell-galois: the false property was not refuted" >&2; exit 1; }; \
    rm -f /tmp/solver-check.saw /tmp/solver-check.out; \
    echo "haskell-galois: tools, solvers and their runtime dependencies execute as $(id -un)"
