# AIVHAI CD image.  Issue #156, decided there on 2026-10-06 (PI, #139).
#
# WHAT IT IS FOR.  Continuous Deployment renders the project's Markdown and
# LaTeX documents to PDF, with their diagrams (#153).  Building documents is
# CD, not CI: CI only checks that Markdown reads through pandoc with no
# warnings (#152), in the much smaller `ci` image.
#
# WHAT IS IN IT replicates the documentation tooling of HOARDE's and
# cryptol-agent's CD images (docker/cd/Dockerfile in each), as the PI decided:
#   - pandoc, the same release and SHA-256 as the `ci` image, so a document CI
#     passes is read by the same pandoc that renders it;
#   - TeX Live with XeLaTeX and LuaLaTeX: texlive-latex-base, -latex-extra,
#     -fonts-recommended, -fonts-extra, -xetex, -luatex;
#   - the Liberation, DejaVu and Latin Modern fonts (DejaVu Sans Mono covers the box-drawing
#     characters that the default monospace font renders as blanks);
#   - Mermaid CLI 11.4.0, whose lockfile resolves the Mermaid library to
#     11.17.2, with the Chrome headless shell Puppeteer pins, configured so a
#     diagram's labels are SVG text that survives conversion to PDF (below);
#   - PlantUML 1.2024.7, with the Java runtime and Graphviz it needs;
#   - rsvg-convert, which pandoc uses to put an SVG diagram into a PDF;
#   - pdftotext, so CD can check that a rendered PDF still carries the
#     semantic property annotations of its source (#153).
# Plus the plumbing a CD job uses: bash, git, gh, jq, make, python3, curl.
#
# DEPARTURES FROM THOSE IMAGES (PI, #156, 2026-10-06):
#   - Everything is pinned (below).  Their apt and npm installs are not.
#   - No JDK or Gradle: only the Java runtime PlantUML needs.  No cloc:
#     metrics are deferred until #172.
#   - ubuntu:24.04, as the `ci` image is, not eclipse-temurin on 22.04.  CD runs
#     on the git host's runner beside CI job 1, and none of the 22.04 chain's
#     formal-methods toolchain belongs here (PLAT-D20 keeps it off `git`).
#
# DETERMINISM.  What the definition fixes, so that a rebuild should yield the
# same toolchain (reproducibility over time is enforced by these checks, not
# yet measured by two builds at different times):
#   - the base is pinned by digest;
#   - every installed apt package's VERSION is one that the dated snapshot of
#     the Ubuntu archive (snapshot.ubuntu.com) publishes.  That is version
#     membership, not download provenance: the bootstrap below fetches a few
#     packages from the live archive, and one whose version the snapshot also
#     publishes is kept (HOARDE Codex, PR #233 review cycle 3);
#   - pandoc, Node.js and the PlantUML jar are upstream releases checked
#     against a SHA-256.  Node.js is not taken from apt: noble's 18.19 is too
#     old for Mermaid's dependency tree, which needs Node 20 or later (`marked`);
#   - Mermaid CLI and its whole dependency tree install with `npm ci` from the
#     package-lock.json beside this file, which carries an integrity hash for
#     every package.  Puppeteer's version (in that lock) fixes the Chrome
#     headless shell it downloads, 131.0.6778.204, and only that browser is
#     fetched: mermaid-cli launches with `headless: 'shell'`.  Puppeteer
#     verifies no hash, so the build does: a SHA-256 over every file of the
#     browser's directory, 122 files, must equal CHROME_HEADLESS_SHELL_TREE_SHA256,
#     or the build fails.  The hash covers regular files' contents and their
#     relative paths only, not modes, symlinks or ownership; the zip has no
#     symlinks, and the main binary's executable bit is tested separately.
#     Google publishes no hash.  The value was computed from Google's zip by
#     HOARDE Copilot on 2026-10-09 (PR #233 review cycle 2), not recorded
#     from a build, and has since been reproduced by hosted run 38049740707,
#     by a laptop build of 4f37f73, and in the image published from 52daba2;
#   - every apt package, the base image's included, is moved to a version the
#     snapshot publishes, and then checked (below).
#
# THE PLATFORM IS NOT PINNED HERE; infra/containers/build.sh passes
# --platform linux/amd64 and refuses to build without it (PLAT-D03).
#
# NO DEFAULT USER, as for the `ci` image: CD runs it as the caller's uid
# (`--userns=keep-id` under rootless podman, `--user $(id -u):$(id -g)` under
# Docker), so the files it writes into the checkout stay the caller's.
ARG UBUNTU_DIGEST=sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55
FROM ubuntu:24.04@${UBUNTU_DIGEST}

ARG UBUNTU_SNAPSHOT=20261006T000000Z
ARG PANDOC_VERSION=3.12
ARG PANDOC_SHA256=91903ff19f1b1d4db4129797c7e18f71212990d7394fcff1787719aebf04e372
ARG NODE_VERSION=22.23.3
ARG NODE_SHA256=df450af89261115ef9f9e3830c3eeb2cc9213b63c720b1af623cb5dcbe2e02de
ARG PLANTUML_VERSION=1.2024.7
ARG PLANTUML_SHA256=e34c12bbe9944f1f338ca3d88c9b116b86300cc8e90b35c4086b825b5ae96d24
ARG MERMAID_CLI_VERSION=11.4.0
ARG MERMAID_VERSION=11.17.2
ARG CHROME_HEADLESS_SHELL_VERSION=131.0.6778.204
ARG CHROME_HEADLESS_SHELL_TREE_SHA256=057fbad12649b6a9344aa6a65e2a5cfd74df2fe1435ba07f7f8bb9598f6eded5

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      org.opencontainers.image.description="AIVHAI CD: pandoc, TeX Live (XeLaTeX, LuaLaTeX), Mermaid CLI, PlantUML -- documents and diagrams rendered to PDF" \
      org.opencontainers.image.licenses="NOASSERTION" \
      sl.licenses.note="Ubuntu 24.04 and its packages, including TeX Live, carry many licences; see /usr/share/doc/*/copyright.  pandoc is GPL-2.0-or-later; Node.js MIT; Mermaid CLI MIT; PlantUML GPL-3.0-or-later; Chrome headless shell BSD-3-Clause and others" \
      sl.project="aivhai" \
      sl.layer="cd" \
      sl.ubuntu.snapshot="${UBUNTU_SNAPSHOT}" \
      sl.pandoc.version="${PANDOC_VERSION}" \
      sl.node.version="${NODE_VERSION}" \
      sl.mermaid-cli.version="${MERMAID_CLI_VERSION}" \
      sl.mermaid.version="${MERMAID_VERSION}" \
      sl.chrome-headless-shell.version="${CHROME_HEADLESS_SHELL_VERSION}" \
      sl.plantuml.version="${PLANTUML_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# As in the `ci` image: the base carries no ca-certificates, so the snapshot
# service (HTTPS) is unreachable until they are installed from the plain
# archive.  That bootstrap step can pull newer packages from the live archive
# (openssl, libssl3t64, ...), and naming them in the snapshot install does not
# replace them: apt never offers a candidate older than what is installed.  So
# a preferences file pins every package to the snapshot at priority 1001, and
# `dist-upgrade --allow-downgrades` then moves EVERY installed package, the
# base image's included, to a version the snapshot publishes (HOARDE Copilot and HOARDE
# Codex, PR #233 review cycle 2, which showed the cycle 1 check passing with
# live versions left in place).
#
# Fonts and TeX packages are named one by one rather than reached through a
# metapackage's recommends, which --no-install-recommends drops, so the list
# below is the image's font set.  DejaVu Sans Mono is in `fonts-dejavu-mono`.
# `fonts-lmodern` is the Latin Modern OpenType family XeLaTeX and LuaLaTeX
# use by default, and `texlive-latex-recommended` carries unicode-math, which
# pandoc's template loads for both engines.
#
# The result is then CHECKED by membership, not by apt's candidate (which
# counts the installed version): every installed package and version must be
# one the snapshot publishes, with no exception, and both inventories must be
# nonempty.  Shown both ways on 2026-10-10: without the pin, against a
# snapshot older than the live archive, 12 packages are off-snapshot and the
# check fails; with it, none are.  The step runs under bash with pipefail, so
# a failing producer cannot hide behind a succeeding `sort` or `awk`.
#
# The libraries after `poppler-utils` are what the Chrome headless shell links
# against; Puppeteer downloads the browser but not its system libraries.
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && printf '%s\n' 'Package: *' 'Pin: origin snapshot.ubuntu.com' 'Pin-Priority: 1001' \
      > /etc/apt/preferences.d/aivhai-snapshot \
 && apt-get update --snapshot "$UBUNTU_SNAPSHOT" \
 && apt-get install -y --no-install-recommends --snapshot "$UBUNTU_SNAPSHOT" --allow-downgrades \
      ca-certificates \
      openssl \
      curl \
      git \
      gh \
      jq \
      make \
      python3 \
      xz-utils \
      fontconfig \
      fonts-dejavu-core \
      fonts-dejavu-extra \
      fonts-dejavu-mono \
      fonts-liberation \
      fonts-lmodern \
      texlive-latex-recommended \
      texlive-latex-base \
      texlive-latex-extra \
      texlive-fonts-recommended \
      texlive-fonts-extra \
      texlive-xetex \
      texlive-luatex \
      openjdk-21-jre-headless \
      graphviz \
      librsvg2-bin \
      poppler-utils \
      libasound2t64 \
      libatk-bridge2.0-0t64 \
      libatk1.0-0t64 \
      libcairo2 \
      libcups2t64 \
      libdbus-1-3 \
      libdrm2 \
      libgbm1 \
      libnspr4 \
      libnss3 \
      libpango-1.0-0 \
      libxcomposite1 \
      libxdamage1 \
      libxfixes3 \
      libxkbcommon0 \
      libxrandr2 \
 && apt-get dist-upgrade -y --snapshot "$UBUNTU_SNAPSHOT" --allow-downgrades \
 && dpkg-query -W -f '${db:Status-Abbrev}\t${Package}\t${Version}\n' \
      | awk -F'\t' '$1 ~ /^ii/ {print $2 "\t" $3}' | sort -u > /tmp/installed \
 && apt-cache madison --snapshot "$UBUNTU_SNAPSHOT" $(cut -f1 /tmp/installed) \
      | awk -F' [|] ' '$3 ~ /snapshot\.ubuntu\.com/ {gsub(/ /, "", $1); gsub(/ /, "", $2); print $1 "\t" $2}' \
      | sort -u > /tmp/in-snapshot \
 && test -s /tmp/installed && test -s /tmp/in-snapshot \
 && comm -23 /tmp/installed /tmp/in-snapshot > /tmp/off-snapshot \
 && if [ -s /tmp/off-snapshot ]; then cat /tmp/off-snapshot >&2; \
      echo "cd: the packages above are not versions the snapshot publishes" >&2; exit 1; fi \
 && rm -f /tmp/installed /tmp/in-snapshot /tmp/off-snapshot \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/pandoc.deb \
      "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" \
 && echo "${PANDOC_SHA256}  /tmp/pandoc.deb" | sha256sum -c - \
 && dpkg -i /tmp/pandoc.deb \
 && rm /tmp/pandoc.deb

# The image's final package list, after pandoc's .deb, so two builds can be
# compared package for package.  pandoc is the one dpkg package not from the
# snapshot; it is checked by SHA-256 above instead.
RUN mkdir -p /usr/share/aivhai \
 && dpkg-query -W -f '${db:Status-Abbrev}\t${Package}\t${Version}\n' \
      | awk -F'\t' '$1 ~ /^ii/ {print $2 "\t" $3}' | sort -u > /usr/share/aivhai/dpkg-manifest.tsv \
 && test -s /usr/share/aivhai/dpkg-manifest.tsv

RUN curl -fsSL -o /tmp/node.tar.xz \
      "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
 && echo "${NODE_SHA256}  /tmp/node.tar.xz" | sha256sum -c - \
 && mkdir -p /opt/node \
 && tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1 \
 && rm /tmp/node.tar.xz
ENV PATH=/opt/node/bin:$PATH

# Mermaid CLI from the lockfile.  Versions are read from the files, not by
# require(): the packages' `exports` maps do not expose their package.json.
# The browser goes to a fixed, world-readable cache rather than the building
# user's home, because the image runs as an arbitrary uid whose HOME is /tmp.
# Its version and its every file are then asserted, because Puppeteer checks
# neither.
ENV PUPPETEER_CACHE_DIR=/opt/aivhai/puppeteer
COPY package.json package-lock.json /opt/aivhai/mermaid/
RUN cd /opt/aivhai/mermaid \
 && PUPPETEER_CHROME_SKIP_DOWNLOAD=true npm ci --no-audit --no-fund \
 && test "$(jq -r .version node_modules/@mermaid-js/mermaid-cli/package.json)" = "$MERMAID_CLI_VERSION" \
 && test "$(jq -r .version node_modules/mermaid/package.json)" = "$MERMAID_VERSION" \
 && tree="$PUPPETEER_CACHE_DIR/chrome-headless-shell/linux-$CHROME_HEADLESS_SHELL_VERSION/chrome-headless-shell-linux64" \
 && test -x "$tree/chrome-headless-shell" \
 && got=$(cd "$tree" && find . -type f | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1) \
 && { [ "$got" = "$CHROME_HEADLESS_SHELL_TREE_SHA256" ] \
      || { echo "cd: the browser's files hash to $got, not $CHROME_HEADLESS_SHELL_TREE_SHA256" >&2; exit 1; }; } \
 && test "$(find "$PUPPETEER_CACHE_DIR" -name chrome-headless-shell -type f | wc -l)" = 1 \
 && chmod -R a+rX "$PUPPETEER_CACHE_DIR" \
 && npm cache clean --force

# The browser's own sandbox needs user namespaces that a rootless container
# does not grant; the container is the sandbox.  And Mermaid by default draws
# labels as HTML inside an SVG foreignObject, which rsvg-convert, and so
# pandoc's PDF path, silently drops: a diagram embedded in a PDF lost every
# label, and the first smoke check passed it (HOARDE Codex, PR #233).
# mermaid.json makes labels SVG text.  `mmdc` is wrapped so that every caller
# gets both configurations; a caller's own -p or -c, given later, overrides.
COPY puppeteer.json /etc/aivhai/puppeteer.json
COPY mermaid.json /etc/aivhai/mermaid.json
RUN printf '%s\n' '#!/bin/sh' \
      'exec /opt/aivhai/mermaid/node_modules/.bin/mmdc -p /etc/aivhai/puppeteer.json -c /etc/aivhai/mermaid.json "$@"' \
      > /usr/local/bin/mmdc \
 && chmod 0755 /usr/local/bin/mmdc

RUN curl -fsSL -o /opt/aivhai/plantuml.jar \
      "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar" \
 && echo "${PLANTUML_SHA256}  /opt/aivhai/plantuml.jar" | sha256sum -c - \
 && printf '%s\n' '#!/bin/sh' \
      'exec java -Djava.awt.headless=true -jar /opt/aivhai/plantuml.jar "$@"' \
      > /usr/local/bin/plantuml \
 && chmod 0755 /usr/local/bin/plantuml

# The image's own check, run by containers.yml with no network, as cheri-rvy's
# is: it exercises representative renders of each tool -- a document through
# both engines, each kind of diagram, a diagram inside a PDF -- checks their
# content, not only their existence, and proves that a broken document fails.
# It is not the CD service's own test, which is #153's.  Run at build time
# too, so a broken image is never tagged.
COPY smoke.sh /usr/local/bin/aivhai-cd-smoke
RUN chmod 0755 /usr/local/bin/aivhai-cd-smoke \
 && HOME=/tmp aivhai-cd-smoke

ENV HOME=/tmp
RUN git config --system --add safe.directory '*'

WORKDIR /work
CMD ["/bin/bash"]
