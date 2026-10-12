# AIVHAI solvers layer.  Issue #67, Tier 3.
#
# The what4-solvers snapshot: Z3 4.8.8 AND 4.8.14, Yices 2.7.0, CVC5 1.3.1,
# Boolector 3.2.2, Bitwuzla 0.7.0, ABC.  Nothing upstream publishes this set
# as an image, and the set rather than any one solver is what the Galois
# toolchain is validated against.
#
# WHY TWO VERSIONS OF Z3, AND WHERE PATH IS DECIDED.  SAW and Crux are
# validated against specific Z3 builds, and a newer Z3 is not a drop-in: it
# changes which queries return unknown and how long the others take.  The
# snapshot therefore installs UNDER ITS OWN PREFIX, /opt/aivhai/what4-solvers,
# which a composing image copies wholesale and then decides for itself what
# goes on its PATH: extended-cv and haskell-galois put the snapshot there,
# provers takes z3 alone.  Getting that backwards produces proofs that pass
# with a solver nobody chose.
#
# IN THIS IMAGE THE SNAPSHOT IS ON PATH (#113).  The first revision left it
# off, so that it "could not shadow a modern Z3 that something else on the
# host wants" -- but a container's PATH shadows nothing on the host, and the
# only Z3 in this image is the snapshot's.  What the off-PATH arrangement
# actually produced was an image in which `z3` is "command not found" for a
# performer and for the catalogue, measured on cli on 2026-09-29.  The ENV
# below does not travel with a COPY --from, so a composing image still
# chooses.  Yices 2.7.0 stays by prefix: PLAT-D29 gives the Galois-shipped
# 2.6.5 the name `yices`.
ARG BASE=ghcr.io/sigil-logic/aivhai-base:latest
FROM ${BASE}

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      sl.layer="solvers" \
      org.opencontainers.image.description="what4-solvers snapshot on PATH, plus Yices 2.7.0 by prefix" \
      org.opencontainers.image.licenses="MIT AND GPL-3.0-only AND BSD-3-Clause AND LicenseRef-ABC-UCBerkeley" \
      sl.licenses.manifest="/opt/aivhai/licenses/MANIFEST.tsv"

USER root

# Pinned to the snapshot the corpus names.  ubuntu-22.04-X64 matches the base.
ARG WHAT4_SNAPSHOT=snapshot-20260622
ARG WHAT4_ASSET=ubuntu-22.04-X64-bin.zip
ENV AIVHAI_SOLVERS=/opt/aivhai/what4-solvers

# CHECKSUM, MEASURED AND NOW PINNED.  A GitHub release asset can be replaced in
# place, so the release tag alone is not integrity.  This value was not written
# down from anywhere -- it is what the first real build of this layer actually
# downloaded, on 2026-09-22, and the build failed closed against it thereafter.
# That is the only honest way to pin a 300 MB asset nobody publishes a digest
# for: measure it once, then refuse anything else.
ARG WHAT4_SHA256=51ce22c77b2ce88a3259a6013f77fd8f5a86a3b29b82488bb759909dbc106784
RUN set -eux; \
    url="https://github.com/GaloisInc/what4-solvers/releases/download/${WHAT4_SNAPSHOT}/${WHAT4_ASSET}"; \
    curl -fsSL -o /tmp/solvers.zip "$url"; \
    got="$(sha256sum /tmp/solvers.zip | awk '{print $1}')"; \
    echo "what4-solvers ${WHAT4_SNAPSHOT} ${WHAT4_ASSET} sha256=${got}"; \
    if [ -n "${WHAT4_SHA256}" ] && [ "${got}" != "${WHAT4_SHA256}" ]; then \
      echo "what4-solvers checksum MISMATCH: expected ${WHAT4_SHA256}" >&2; exit 1; \
    fi; \
    install -d -m 0755 "${AIVHAI_SOLVERS}"; \
    unzip -q /tmp/solvers.zip -d "${AIVHAI_SOLVERS}"; \
    chmod -R a+rx "${AIVHAI_SOLVERS}"; \
    rm -f /tmp/solvers.zip; \
    printf '%s  %s\n' "${got}" "${WHAT4_ASSET}" > "${AIVHAI_SOLVERS}/.provenance"; \
    ls -1 "${AIVHAI_SOLVERS}" | head -40

# ---- Yices 2.7.0, alongside the snapshot's 2.6.5 ------------------------
# TWO YICES VERSIONS COEXIST, for the same reason two Z3 versions do, and the
# PI's rule settles which governs where: **a Galois tool depends on, and is
# guaranteed against, the solver set Galois ships and documents.**  The
# what4-solvers snapshot ships Yices 2.6.5, so 2.6.5 is what Cryptol, SAW and
# Crux get.  Other consumers ask for 2.7.0 -- the SBOM's Layer G inventory
# records it -- so 2.7.0 is installed too, under its own prefix, and neither
# shadows the other.
#
# The alternative was to pick one, and picking one is how a proof ends up
# recorded against a solver its tool was never validated with.  Installing
# both costs 9 MB and removes the question.
ARG YICES_VERSION=2.7.0
ARG YICES_SHA256=49566b6f817692820538df78fe406878400d79810631c9372b2495bc81d3e00a
ENV AIVHAI_YICES_270=/opt/aivhai/yices-2.7.0
RUN set -eux; \
    curl -fsSL -o /tmp/yices.tar.gz \
      "https://github.com/SRI-CSL/yices2/releases/download/yices-${YICES_VERSION}/yices-${YICES_VERSION}-x86_64-pc-linux-gnu-static-gmp.tar.gz"; \
    echo "${YICES_SHA256}  /tmp/yices.tar.gz" | sha256sum -c -; \
    install -d -m 0755 "${AIVHAI_YICES_270}"; \
    tar -xzf /tmp/yices.tar.gz -C "${AIVHAI_YICES_270}" --strip-components=1; \
    rm -f /tmp/yices.tar.gz; \
    chmod -R a+rX "${AIVHAI_YICES_270}"; \
    printf 'yices %s sha256=%s prefix=%s\n' "${YICES_VERSION}" "${YICES_SHA256}" "${AIVHAI_YICES_270}" \
      >> "${AIVHAI_SOLVERS}/.provenance"

# BOTH ARE VERIFIED HERE, by version string, because "installed two solvers"
# and "installed two DIFFERENT solvers" are different claims and the second is
# the one that matters.  A tarball that silently contained 2.6.5 again would
# otherwise pass unnoticed.
RUN set -eux; \
    a="$("${AIVHAI_SOLVERS}/yices" --version | head -1)"; \
    b="$("${AIVHAI_YICES_270}/bin/yices" --version | head -1)"; \
    echo "snapshot: $a"; echo "alongside: $b"; \
    case "$a" in *2.6.5*) ;; *) echo "expected the snapshot to ship 2.6.5" >&2; exit 1 ;; esac; \
    case "$b" in *2.7.0*) ;; *) echo "expected the alongside build to be 2.7.0" >&2; exit 1 ;; esac

# ---- licence texts, shipped with the binaries they cover -----------------
# THE SNAPSHOT SHIPS NONE, and that is the gap this closes.  The
# what4-solvers archive contains fifteen binaries and not one licence file;
# AIVHAI's own docs/tools.md already records that the archive declares no
# licence of its own and that "if we ever ship solver binaries obtained
# through it, the governing licences are the solvers', not Galois'".  We are
# shipping them, and publishing the image is what turns that from an
# observation into a redistribution obligation.
#
# ONE OF THEM IS GPLv3.  Yices 2.x is GPL-3.0, so a licence text is not
# optional politeness here.  Its text is taken from the 2.7.0 tarball we
# already install, which carries LICENSE and NOTICES; the others are fetched
# from their upstreams.
#
# Each licence was READ FROM ITS TREE rather than assumed, which is the rule
# docs/tools.md sets: "No document claims a licence that was not read from
# the tree or from package metadata."
RUN set -eux; \
    L=/opt/aivhai/licenses; install -d -m 0755 "$L"; \
    curl -fsSL -o "$L/z3.LICENSE"        https://raw.githubusercontent.com/Z3Prover/z3/master/LICENSE.txt; \
    curl -fsSL -o "$L/cvc5.COPYING"      https://raw.githubusercontent.com/cvc5/cvc5/main/COPYING; \
    curl -fsSL -o "$L/cvc4.COPYING"      https://raw.githubusercontent.com/cvc5/CVC4/master/COPYING; \
    curl -fsSL -o "$L/boolector.COPYING" https://raw.githubusercontent.com/Boolector/boolector/master/COPYING; \
    curl -fsSL -o "$L/bitwuzla.COPYING"  https://raw.githubusercontent.com/bitwuzla/bitwuzla/main/COPYING; \
    curl -fsSL -o "$L/abc.copyright"     https://raw.githubusercontent.com/berkeley-abc/abc/master/copyright.txt; \
    cp "${AIVHAI_YICES_270}/LICENSE" "$L/yices.LICENSE"; \
    cp "${AIVHAI_YICES_270}/NOTICES" "$L/yices.NOTICES" 2>/dev/null || true; \
    { printf 'component\tspdx\ttext\n'; \
      printf 'z3\tMIT\tz3.LICENSE\n'; \
      printf 'yices\tGPL-3.0-only\tyices.LICENSE\n'; \
      printf 'cvc5\tBSD-3-Clause\tcvc5.COPYING\n'; \
      printf 'cvc4\tBSD-3-Clause\tcvc4.COPYING\n'; \
      printf 'boolector\tMIT\tboolector.COPYING\n'; \
      printf 'bitwuzla\tMIT\tbitwuzla.COPYING\n'; \
      printf 'abc\tLicenseRef-ABC-UCBerkeley\tabc.copyright\n'; \
    } > "$L/MANIFEST.tsv"; \
    chmod -R a+rX "$L"; \
    test -s "$L/yices.LICENSE"; \
    grep -q "GNU GENERAL PUBLIC" "$L/yices.LICENSE"; \
    echo "solvers: $(( $(wc -l < "$L/MANIFEST.tsv") - 1 )) licences shipped"

ENV AIVHAI_SOLVERS_SNAPSHOT="${WHAT4_SNAPSHOT}" \
    AIVHAI_YICES_SNAPSHOT_VERSION="2.6.5"

# The snapshot is on PATH, so `z3`, `yices`, `cvc4`, `cvc5`, `boolector`,
# `bitwuzla` and `abc` resolve by name (#113).  `yices` is the snapshot's
# 2.6.5; 2.7.0 is reached as /opt/aivhai/yices-2.7.0/bin/yices.  A composing
# image copies the directory and sets its own PATH -- this ENV does not travel
# with a COPY --from, so the choice stays with the image that makes it.
ENV PATH="${AIVHAI_SOLVERS}:${PATH}"

USER aivhai

# Checked AS THE RUNTIME USER and BY NAME ON PATH, because that is the claim
# #113 found false: a solver set installed under a prefix no shell searched.
# Every executable is asserted with an exact `command -v` against the prefix,
# so a stray binary elsewhere in the image could not stand in for the
# snapshot's, and every version probe is a command substitution: under this
# image's /bin/sh a missing tool in `tool --version | head -1` leaves the
# pipeline at `head`'s status 0 and `set -e` never fires (HOARDE Codex,
# PR #187 cycle 1), whereas `v=$(tool --version)` fails the build.
RUN set -eux; \
    for t in z3 yices cvc4 cvc5 boolector bitwuzla abc; do \
      [ "$(command -v "$t")" = "${AIVHAI_SOLVERS}/$t" ] || { echo "solvers: $t does not resolve to the snapshot" >&2; exit 1; }; \
    done; \
    v=$(z3 --version); echo "$v" | head -1; \
    v=$(yices --version); echo "$v" | head -1 | grep -q 2.6.5; \
    v=$(cvc4 --version); echo "$v" | head -1; \
    v=$(cvc5 --version); echo "$v" | head -1; \
    v=$(boolector --version); echo "$v" | head -1; \
    v=$(bitwuzla --version); echo "$v" | head -1; \
    v=$("${AIVHAI_YICES_270}/bin/yices" --version); echo "$v" | head -1 | grep -q 2.7.0; \
    echo "solvers: the snapshot resolves on PATH as $(id -un)"
