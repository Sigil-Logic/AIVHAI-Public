# AIVHAI container base.  Issue #67.
#
# EVERY LAYER IN THIS SET STARTS HERE, which is the point: the three hosts
# compose different layer sets, and a common base is what stops the same
# apt-get running three times and drifting three ways.
#
# ubuntu:22.04 and not something newer, for one reason that decides it: the
# what4-solvers snapshot the corpus pins publishes an ubuntu-22.04 build, and
# the Galois toolchain is built against that ABI.  Following Ubuntu forward
# would mean either rebuilding the solver set ourselves or running binaries
# against a libc they were not linked for, and the second one fails as a
# wrong answer rather than as an error.
#
# linux/amd64 ONLY, per PLAT-D03.  The development laptops are arm64 and the
# authoritative toolchain is not; a proof budget means the same thing
# everywhere because the platform is fixed rather than inherited from whoever
# ran the build.
#
# THE PLATFORM IS NOT PINNED HERE, and that is deliberate rather than an
# omission.  `FROM --platform=linux/amd64` hardcodes it where buildkit warns
# about it (FromPlatformFlagConstDisallowed) and where a composing image
# cannot override it for a legitimate local experiment.  It is enforced one
# level up instead, by infra/containers/build.sh, which passes --platform and
# refuses to build without it -- one place, checkable, and it also stamps the
# resulting image so a mis-built one is identifiable afterwards rather than
# merely unlikely.
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      org.opencontainers.image.description="AIVHAI toolchain base layer" \
      org.opencontainers.image.licenses="NOASSERTION" \
      sl.licenses.note="Ubuntu 22.04 and its packages carry many licences; see /usr/share/doc/*/copyright in the image" \
      sl.project="aivhai" \
      sl.layer="base"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# One layer, and the list is deliberately short.  A base that carries every
# tool anyone might want is a base nobody can reason about; a tool belongs in
# the layer that needs it.  What is here is what EVERY layer needs: fetching
# and verifying downloads, unpacking them, and the C runtime the prebuilt
# binaries in later layers link against.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      unzip \
      xz-utils \
      bzip2 \
      jq \
      libgmp10 \
      libtinfo5 \
      zlib1g \
      python3 \
      python3-pip \
 && rm -rf /var/lib/apt/lists/*

# Tools install here rather than into /usr/local, so a layer's contribution is
# one directory that can be COPY --from'd wholesale by a composing image.
# That is what makes the layers composable rather than merely separate.
ENV AIVHAI_TOOLS=/opt/aivhai
RUN install -d -m 0755 "$AIVHAI_TOOLS/bin"
ENV PATH="$AIVHAI_TOOLS/bin:$PATH"

# Non-root by default.  Proof runs do not need root, and an image whose
# default user is root is one that will eventually be run with a host mount
# and write files nobody can delete.
RUN useradd --create-home --shell /bin/bash --uid 1000 aivhai
WORKDIR /work
RUN chown aivhai:aivhai /work
USER aivhai

CMD ["/bin/bash"]
