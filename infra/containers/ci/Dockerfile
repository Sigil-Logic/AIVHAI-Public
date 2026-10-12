# AIVHAI CI image.  Issue #155, specified there on 2026-10-06.
#
# THE ONE IMAGE NOT IN THE LAYERED CHAIN.  Every other AIVHAI image starts
# from aivhai-base on ubuntu:22.04, because the Galois solver snapshot is
# built against that ABI (base/Dockerfile).  CI needs none of that toolchain,
# and the PI's rule from PR #130 is that the CI container matches the
# operating system of GitHub's runners, so that a gate which passes locally
# in this image also passes in Actions.  GitHub's runner is ubuntu-24.04
# (measured from a CI run, 2026-10-06), so this image is too.
#
# WHAT IS IN IT is what CI job 1 (#152) runs and little more: the gates are
# bash, python3 (standard library only), git, jq, and the usual text tools;
# the citation gate needs gh; and the Markdown well-formedness check needs
# pandoc.  NOT in it: TeX Live, fonts, Mermaid, PlantUML -- rendering to PDF
# is CD (#156) -- and no formal-methods tool at all: CI job 2 runs in the
# provers image on fm, because PLAT-D20 keeps those tools off the git host.
#
# DETERMINISM.  Three pins, so that a rebuild reproduces the same toolchain:
#   - the base by digest, below;
#   - every apt package from one dated snapshot of the Ubuntu archive
#     (snapshot.ubuntu.com), so the versions are those published at
#     UBUNTU_SNAPSHOT and not whatever is current on the day of the build;
#   - pandoc from its upstream release, by version and SHA-256, because
#     noble's pandoc (3.1.3) is far behind the version the project measures
#     with, and an apt version cannot be checked against a published digest.
#
# THE PLATFORM IS NOT PINNED HERE; infra/containers/build.sh passes
# --platform linux/amd64 and refuses to build without it (PLAT-D03), as for
# every other layer.
#
# NO DEFAULT USER.  ubuntu:24.04 already owns uid 1000 (`ubuntu`), and CI runs
# this image as the CALLER's uid -- `--userns=keep-id` under rootless podman
# on the runner, `--user $(id -u):$(id -g)` under Docker on a laptop -- so the
# files a job writes into the checkout stay owned by whoever checked it out.
# A fixed image user would leave files the runner account cannot delete.
ARG UBUNTU_DIGEST=sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55
FROM ubuntu:24.04@${UBUNTU_DIGEST}

ARG UBUNTU_SNAPSHOT=20261006T000000Z
ARG PANDOC_VERSION=3.12
ARG PANDOC_SHA256=91903ff19f1b1d4db4129797c7e18f71212990d7394fcff1787719aebf04e372

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      org.opencontainers.image.description="AIVHAI CI gates: documentation, citation, bibliography, infrastructure, prelude, and pandoc checks" \
      org.opencontainers.image.licenses="NOASSERTION" \
      sl.licenses.note="Ubuntu 24.04 and its packages carry many licences; see /usr/share/doc/*/copyright in the image.  pandoc is GPL-2.0-or-later" \
      sl.project="aivhai" \
      sl.layer="ci" \
      sl.ubuntu.snapshot="${UBUNTU_SNAPSHOT}" \
      sl.pandoc.version="${PANDOC_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# `--snapshot` makes apt resolve every package against the archive as it was
# at UBUNTU_SNAPSHOT.  Noble's official sources are snapshot-enabled, so no
# sources file is rewritten.  The base image carries no ca-certificates, so
# the snapshot service (HTTPS) is unreachable until they are installed: the
# first update and install use the plain archive for ca-certificates alone,
# which is then replaced by the snapshot's version in the main install.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && apt-get update --snapshot "$UBUNTU_SNAPSHOT" \
 && apt-get install -y --no-install-recommends --snapshot "$UBUNTU_SNAPSHOT" --allow-downgrades \
      ca-certificates \
      curl \
      git \
      gh \
      jq \
      make \
      python3 \
      shellcheck \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/pandoc.deb \
      "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" \
 && echo "${PANDOC_SHA256}  /tmp/pandoc.deb" | sha256sum -c - \
 && dpkg -i /tmp/pandoc.deb \
 && rm /tmp/pandoc.deb

# A job run as an arbitrary uid has no home directory in /etc/passwd; gh,
# git, and python all want one.  /tmp is world-writable and per-container.
ENV HOME=/tmp

# The gate scripts call `git ls-files` on a checkout owned by the caller's
# uid, which inside the container is not always the uid git expects.  The
# checkout is the only repository this image is ever pointed at.
RUN git config --system --add safe.directory '*'

WORKDIR /work
CMD ["/bin/bash"]
