# AIVHAI prover chain layer.  Issue #67, Tier 3.
#
# OCaml, opam, Sail, Lem, Lean 4, z3 for Sail, and the Rocq switches.
#
# THERE IS NO SINGLE ROCQ THAT SATISFIES THIS CORPUS, which is the finding
# that shapes this whole layer -- see Layer C of docs/tools/fm-server-sbom.md.
# Five consumers want incompatible configurations, so the layer installs opam
# SWITCHES rather than "a Rocq", and a consumer selects one.  An image that
# picked one and moved on would build four of the five corpora and fail the
# fifth in a way that reads as a proof error.
#
#   switch            Rocq              pins
#   ----------------  ----------------  --------------------------------------
#   cheriot-pl        9.0.0             coq-record-update from opam; stdlib
#                                       cbba1ca6, stdpp 2cc64eaa and coqutil
#                                       1f7c323c are SIBLING CHECKOUTS
#   guru              9.1               rocq-stdlib at master is a SIBLING
#                                       CHECKOUT, not an opam package
#   sail-riscv        rocq-core 9.1.1   rocq-stdlib 9.0.0,
#                                       rocq-stdpp-bitvector 1.13.0,
#                                       rocq-sail-stdpp at the Sail version
#   saw               rocq-core 9.1.1   coq-bits at rocq-community/bits
#                     (see the switch)  f50fc3e5, plus the `coq` 9.1.0 shim
#                                       package, on OCaml 4.14
#
# cheriot-abstract-spec is the fifth consumer and pins nothing; it rides on
# the `guru` switch.  #67 says "four opam switches" and the SBOM table lists
# five consumers -- these are the same statement, and this comment exists so
# the next reader does not go looking for a fifth switch.
#
# THIS LAYER TAKES HOURS TO BUILD: four opam switches each compiling OCaml and
# Rocq from source.  It is built on CI dispatch, by name, or by hand, and not
# on every change; under emulation on an arm64 laptop the 2026-10-06 rebuild
# (#113) is recorded in .evidence/platform/.  Marked here rather than in a
# tracking document, because the next person to reach for this image needs
# to know before they wait for it.
#
# TWO THINGS THE FIRST REVISION ADVERTISED AND DID NOT CONTAIN (#113, measured
# on cli on 2026-09-29): a runnable Lean, and an SMT solver for Sail.  Both
# are installed below, and both are checked as the runtime user at the end.
ARG BASE=ghcr.io/sigil-logic/aivhai-base:latest
ARG SOLVERS=ghcr.io/sigil-logic/aivhai-solvers:latest
FROM ${SOLVERS} AS solvers
FROM ${BASE}

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      sl.layer="provers" \
      org.opencontainers.image.description="opam, OCaml, Sail 0.20.2, Lem, Lean 4 via elan, z3, four Rocq switches" \
      org.opencontainers.image.licenses="NOASSERTION" \
      sl.licenses.manifest="/opt/aivhai/licenses/MANIFEST.tsv"

USER root

# zstd is for the Lean toolchain tarball, which GitHub publishes as .tar.zst.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential m4 opam rsync mercurial darcs zstd \
      libgmp-dev pkg-config zlib1g-dev libipc-system-simple-perl libstring-shellquote-perl \
 && rm -rf /var/lib/apt/lists/*

ENV AIVHAI_OPAM=/opt/aivhai/opam \
    OPAMROOT=/opt/aivhai/opam \
    OPAMYES=1 \
    OPAMCOLOR=never

# OCaml 5.2.1: the version sail-riscv's Rocq CI uses.  The `rems` repository
# is where Sail and Lem come from and is added once for every switch.
ARG OCAML_VERSION=5.2.1
RUN set -eux; \
    opam init --bare --disable-sandboxing --no-setup; \
    opam repository add rems https://github.com/rems-project/opam-repository.git --all-switches --set-default; \
    opam repository add rocq-released https://coq.inria.fr/opam/released --all-switches --set-default

# THE ROCQ RELEASED REPOSITORY IS NOT OPTIONAL, and leaving it out is how the
# first build of this layer failed: "No package named rocq-stdpp-bitvector
# found".  rocq-core and the Rocq ecosystem packages the SBOM pins --
# rocq-stdpp-bitvector, rocq-sail-stdpp, coq-bits -- are published there and
# not in the default opam repository.  The default repository resolves enough
# to look like it might work, which is why the failure lands on a package name
# rather than on the missing repository.

# ---- switch: sail-riscv ---------------------------------------------------
# Sail 0.20.2 is required by sail-riscv's CMake, not merely preferred: the
# CMake check is a hard version comparison and a newer Sail fails configure.
ARG SAIL_VERSION=0.20.2
RUN set -eux; \
    opam switch create sail-riscv "ocaml-base-compiler.${OCAML_VERSION}"; \
    opam install --switch=sail-riscv -y \
      "sail.${SAIL_VERSION}" lem \
      rocq-core.9.1.1 rocq-stdlib.9.0.0 rocq-stdpp-bitvector.1.13.0 \
      "rocq-sail-stdpp.${SAIL_VERSION}"

# ---- switch: cheriot-pl ---------------------------------------------------
# ONLY ROCQ AND coq-record-update COME FROM OPAM HERE, and the first build of
# this layer proved why by failing: opam could find "No agreement on the
# version of coq" between commit-pinned coq-stdpp and coq-coqutil.
#
# The conflict was not a bad pin, it was the wrong MECHANISM.
# cheriot-program-logic's own README says stdpp and coqutil are "installed at
# the parent directory" -- SIBLING CHECKOUTS, exactly as Guru does with
# rocq-stdlib-master, and not opam packages at all.  Pinning them through opam
# asks the solver to reconcile constraints the project never intended it to
# see.  The SBOM's table lists them as pins, which is true of the versions and
# misleading about the delivery.
#
# So the switch installs what opam genuinely provides, and the sibling
# checkouts are the consuming job's to place.  Their commits, from that
# README, so the information is not lost:
#
#   stdlib   rocq-prover/stdlib     cbba1ca6   (for Zmod)
#   stdpp    iris/stdpp             2cc64eaa
#   coqutil  mit-plv/coqutil        1f7c323c
RUN set -eux; \
    opam switch create cheriot-pl "ocaml-base-compiler.${OCAML_VERSION}"; \
    opam install --switch=cheriot-pl -y rocq-core.9.0.0 coq-record-update

# ---- switch: guru ---------------------------------------------------------
# Same shape, and it is the shape the SBOM's Gap 1 describes: Guru's
# _CoqProject reads -Q ../rocq-stdlib-master/theories Stdlib, a sibling
# checkout at master needed for Zmod, which is a submodule of nothing and
# pinned nowhere.  It IS present in AIVHAI-Everything as
# Hardware/rocq-stdlib-master, so the consuming job has something to point at;
# "present in a working tree" is still not "pinned".
RUN set -eux; \
    opam switch create guru "ocaml-base-compiler.${OCAML_VERSION}"; \
    opam install --switch=guru -y rocq-core.9.1.0

# ---- switch: saw ----------------------------------------------------------
# TAKEN VERBATIM FROM saw-script's OWN CI AND README, not from the SBOM's
# summary of them, after the summary's pin turned out to name no repository.
# Verified 2026-09-22 against saw-script's default branch and against release
# v1.6 (2026-09-17): the pin still stands there today.
#
# THE COMMIT PIN IS REAL AND REQUIRED.  f50fc3e5f1ea is a genuine commit of
# rocq-community/bits, dated 2025-09-07.  saw-script's CI carries the comment
# "FIXME: replace with compatible opam-released version WHEN AVAILABLE" --
# which is upstream saying the released versions are not yet compatible.  So
# coq-bits.1.1.0 does NOT stand in for it, and the earlier substitution here
# was wrong.
#
# THREE THINGS THIS SWITCH DOES DIFFERENTLY, each of which I had wrong:
#
#   OCaml 4.14, not 5.2.1.  saw-script's Rocq job pins the compiler, and the
#   5.2.1 used by the other switches is a sail-riscv fact, not a global one.
#
#   An unusual Rocq mix: rocq-prover pinned to 9.0.0 while rocq-core is 9.1.0
#   and rocq-stdlib is 9.0.0.  Written as upstream writes it rather than
#   normalised, because normalising it is how a working combination gets
#   quietly replaced by a plausible one.
#
#   The `coq` compatibility package at 9.1.0 is REQUIRED, not optional.  It
#   supplies the Coq-to-Rocq transition shims -- coqc, coq_makefile -- that
#   coq-bits still builds against.  Its absence is most of why the earlier
#   attempt could not resolve.
ARG SAW_OCAML_VERSION=4.14.2
ARG COQ_BITS_COMMIT=f50fc3e5f1eabcb0b0b94c8d25f75e61a255c2ba
RUN set -eux; \
    opam switch create saw "ocaml-base-compiler.${SAW_OCAML_VERSION}"; \
    opam pin add --switch=saw -y rocq-prover 9.0.0; \
    opam install --switch=saw -y rocq-core=9.1.0 rocq-stdlib=9.0.0; \
    opam install --switch=saw -y coq=9.1.0; \
    opam pin --switch=saw -y coq-bits \
      "https://github.com/rocq-community/bits.git#${COQ_BITS_COMMIT}"

# ---- z3, from the solvers layer, for Sail ---------------------------------
# Sail runs an SMT solver for its type-level constraints, and in the first
# revision of this image `sail --version` died with "SMT solver returned
# unexpected status 127": no z3 at all (#113).  It is taken from the solvers
# layer rather than installed a second time, so the one pinned snapshot is
# the source of every z3 on the platform (PLAT-D29), and it lands in
# /opt/aivhai/bin -- the directory the base already puts on PATH and that
# this layer otherwise left empty.  The snapshot's provenance line and the
# z3 licence text travel with it.
COPY --from=solvers /opt/aivhai/what4-solvers/z3 /opt/aivhai/bin/z3
COPY --from=solvers /opt/aivhai/what4-solvers/.provenance /opt/aivhai/provenance/solvers-snapshot
COPY --from=solvers /opt/aivhai/licenses/z3.LICENSE /opt/aivhai/licenses/z3.LICENSE

# ---- Lean 4, via elan, with the toolchain INSTALLED and PINNED --------------
# Lean is a BUILD dependency rather than only a prover we might write in:
# sail-riscv builds a Lean model and a Lean emulator, and Sail ships
# sail_lean_backend.  The first revision of this layer installed elan with
# `--default-toolchain none`, reasoning that the consuming model's
# lean-toolchain file is the pin -- and shipped an image in which `lean` is
# not runnable at all (#113).  An image that downloads its prover on first
# use is not a toolchain of record.
#
# So the toolchain is installed here, at the version sail-riscv's
# lean_emulator/lean-toolchain names at the commit AIVHAI-Everything pins
# (Sigil-Logic/sail-riscv 1dbe9932): leanprover/lean4:v4.29.0.  A model that
# asks for another version still gets it through elan, into the same home, at
# run time -- the pin here is the default, not a ceiling.
#
# BOTH TARBALLS ARE VERIFIED, NOT TRUSTED.  elan would download the toolchain
# itself and check nothing.  Instead elan's own release tarball is checked
# against a digest measured on 2026-10-06 (elan publishes none), and the Lean
# tarball against the sha256 that GitHub's release API reports for the asset
# (the `digest` field of `releases/tags/v4.29.0`'s `assets[]`, computed by
# GitHub on upload); the Lean tree is then unpacked where elan keeps
# toolchains, so elan sees it as installed.  The build asserts that it does,
# and that `lean` runs.
#
# INSTALLED AS `aivhai`, NOT ROOT.  The toolchain home must be writable by the
# user who runs the image: elan writes settings.toml there and installs any
# further toolchain there, and the first revision's root-owned home is why
# `lean` failed with "could not write settings file" as `aivhai` (#151's
# emulation evidence).  Installing as that user avoids a chown over 1.5 GB,
# which would double the layer.
ARG ELAN_VERSION=4.2.4
ARG ELAN_SHA256=42b94d4244e8353142c456ec0e4ca6528fd898a6c604d4059f494e706e431f63
ARG LEAN_VERSION=4.29.0
ARG LEAN_SHA256=089f7e513ed3e9436d191f4986330c0b53809c86b5997f5eb7f25550c374fa48
ENV ELAN_HOME=/opt/aivhai/elan
RUN install -d -m 0755 -o aivhai -g aivhai "${ELAN_HOME}"
USER aivhai
RUN set -eux; \
    curl -fsSL -o /tmp/elan.tar.gz \
      "https://github.com/leanprover/elan/releases/download/v${ELAN_VERSION}/elan-x86_64-unknown-linux-gnu.tar.gz"; \
    echo "${ELAN_SHA256}  /tmp/elan.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/elan.tar.gz -C /tmp elan-init; \
    /tmp/elan-init -y --no-modify-path --default-toolchain none; \
    rm -f /tmp/elan.tar.gz /tmp/elan-init; \
    curl -fsSL -o /tmp/lean.tar.zst \
      "https://github.com/leanprover/lean4/releases/download/v${LEAN_VERSION}/lean-${LEAN_VERSION}-linux.tar.zst"; \
    echo "${LEAN_SHA256}  /tmp/lean.tar.zst" | sha256sum -c -; \
    tc="${ELAN_HOME}/toolchains/leanprover--lean4---v${LEAN_VERSION}"; \
    install -d -m 0755 "$tc"; \
    tar --zstd -xf /tmp/lean.tar.zst -C "$tc" --strip-components=1; \
    rm -f /tmp/lean.tar.zst; \
    "${ELAN_HOME}/bin/elan" default "leanprover/lean4:v${LEAN_VERSION}"; \
    "${ELAN_HOME}/bin/elan" toolchain list | grep -q "leanprover/lean4:v${LEAN_VERSION}"; \
    "${ELAN_HOME}/bin/lean" --version | grep -q "version ${LEAN_VERSION}"; \
    "${ELAN_HOME}/bin/lake" --version
USER root
ENV PATH="${ELAN_HOME}/bin:${PATH}"

# ---- licences, generated from opam's own package metadata ---------------
# THIS LAYER IS LABELLED NOASSERTION, and that is a considered difference from
# the other layers rather than laziness.  They carry a handful of deliberately
# chosen tools, so a compound SPDX expression names them usefully.  This one
# carries roughly 160 transitive opam packages across four switches, spanning
# 19 distinct licences including GPL-3.0-or-later, CECILL-B, CC0-1.0+ and
# several LGPL variants with the OCaml linking exception.  A nineteen-term AND
# string would be accurate and tell a reader nothing about WHICH package
# carries which term.
#
# So the label says "no single assertion" and points at a manifest that gives
# the mapping.  That is more useful to a scanner and more honest to a lawyer.
#
# The licences come from opam's own `license:` field in each installed
# package, which is package metadata -- the source docs/tools.md's rule
# explicitly permits alongside reading the tree.  The three rows whose switch
# column reads `image` are not opam packages: Lean 4 and elan, whose texts
# are fetched from their repositories at the pinned versions, and the z3
# copied from the solvers layer, whose text came with it.
RUN set -eux; \
    L=/opt/aivhai/licenses; install -d -m 0755 "$L"; \
    curl -fsSL -o "$L/lean4.LICENSE"        "https://raw.githubusercontent.com/leanprover/lean4/v${LEAN_VERSION}/LICENSE"; \
    curl -fsSL -o "$L/elan.LICENSE-APACHE"  "https://raw.githubusercontent.com/leanprover/elan/v${ELAN_VERSION}/LICENSE-APACHE"; \
    curl -fsSL -o "$L/elan.LICENSE-MIT"     "https://raw.githubusercontent.com/leanprover/elan/v${ELAN_VERSION}/LICENSE-MIT"; \
    for f in lean4.LICENSE elan.LICENSE-APACHE elan.LICENSE-MIT z3.LICENSE; do \
      test -s "$L/$f" || { echo "provers: licence text $f missing" >&2; exit 1; }; \
    done; \
    grep -q "Apache License" "$L/lean4.LICENSE"; \
    { printf 'switch\tpackage\tlicense\n'; \
      for sw in sail-riscv cheriot-pl guru saw; do \
        for f in /opt/aivhai/opam/$sw/.opam-switch/packages/*/opam; do \
          [ -r "$f" ] || continue; \
          pkg=$(basename "$(dirname "$f")"); \
          lic=$(awk '/^license:/{sub(/^license: */,""); gsub(/[]["]/,""); print; exit}' "$f"); \
          printf '%s\t%s\t%s\n' "$sw" "$pkg" "${lic:-UNSTATED}"; \
        done; \
      done; \
      printf 'image\tlean4.%s\tApache-2.0 (lean4.LICENSE)\n' "${LEAN_VERSION}"; \
      printf 'image\telan.%s\tMIT OR Apache-2.0 (elan.LICENSE-MIT, elan.LICENSE-APACHE)\n' "${ELAN_VERSION}"; \
      printf 'image\tz3 (solvers layer)\tMIT (z3.LICENSE)\n'; \
    } > "$L/MANIFEST.tsv"; \
    chmod -R a+rX "$L"; \
    n=$(( $(wc -l < "$L/MANIFEST.tsv") - 1 )); \
    [ "$n" -gt 100 ] || { echo "provers: only $n packages in the manifest; the extraction is wrong" >&2; exit 1; }; \
    u=$(awk -F'\t' 'NR>1{print $3}' "$L/MANIFEST.tsv" | sort -u | wc -l); \
    echo "provers: $n packages, $u distinct licence fields"

RUN set -eux; \
    install -d -m 0755 /opt/aivhai/provenance; \
    { echo "switches: sail-riscv cheriot-pl guru saw"; \
      echo "sail-riscv  ocaml=${OCAML_VERSION} sail=${SAIL_VERSION} rocq-core=9.1.1"; \
      echo "cheriot-pl  ocaml=${OCAML_VERSION} rocq-core=9.0.0 coq-record-update"; \
      echo "guru        ocaml=${OCAML_VERSION} rocq-core=9.1.0"; \
      echo "saw         ocaml=${SAW_OCAML_VERSION} rocq-core=9.1.0 coq=9.1.0 coq-bits=${COQ_BITS_COMMIT}"; \
      echo "lean        leanprover/lean4:v${LEAN_VERSION} via elan ${ELAN_VERSION}, ELAN_HOME=${ELAN_HOME}, pinned to sail-riscv lean_emulator/lean-toolchain at 1dbe9932"; \
      echo "z3          /opt/aivhai/bin/z3 from the solvers layer: $(head -1 /opt/aivhai/provenance/solvers-snapshot)"; \
      echo ""; \
      echo "# Sibling checkouts this image does NOT carry.  cheriot-program-logic"; \
      echo "# and Guru expect these beside them, and they are pinned as submodules"; \
      echo "# of AIVHAI-Everything rather than installed here:"; \
      echo "#   rocq-stdlib cbba1ca6   stdpp 2cc64eaa   coqutil 1f7c323c"; \
    } > /opt/aivhai/provenance/provers; \
    chmod -R a+rX /opt/aivhai/opam

# No switch is selected by default, for the same reason the solvers layer
# once left its set off PATH: choosing one here would make four consumers
# work and the fifth fail in a way that reads as a proof error rather than as
# a configuration one.  A consumer runs `opam switch <name>` first.
USER aivhai

# Checked AS THE RUNTIME USER, which is where #113's findings would have been
# caught: a Lean that cannot write its own settings, a Sail with no solver,
# and a /opt/aivhai/bin on PATH with nothing in it.  `sail --version` is the
# right probe for the solver because it is exactly the call that failed.
# Version probes are command substitutions, not `tool | head`: under /bin/sh
# a missing tool on the left of a pipe leaves `head`'s status 0 and `set -e`
# never fires (HOARDE Codex, PR #187 cycle 1).
RUN set -eux; \
    [ "$(command -v z3)" = /opt/aivhai/bin/z3 ]; \
    v=$(z3 --version); echo "$v" | head -1; \
    v=$(lean --version); echo "$v" | grep -q "version ${LEAN_VERSION}"; \
    v=$(lake --version); echo "$v" | head -1; \
    "${AIVHAI_OPAM}/sail-riscv/bin/sail" --version; \
    "${AIVHAI_OPAM}/sail-riscv/bin/lem" -v; \
    echo "provers: z3, lean, lake, sail and lem execute as $(id -un)"
