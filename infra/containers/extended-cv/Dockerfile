# AIVHAI Extended-CV proof image.  Issue #67.
#
# THIS IS THE ONE #67 SAYS TO BUILD FIRST, because it is the image that runs
# the 37 licence-free proof tasks.  It is a composition rather than a new
# install: the hdl-formal layer already carries Yosys from our fork, SBY,
# sv2v and bsc, and the solvers layer carries the what4 snapshot that supplies
# Boolector.  Nothing upstream combines Bluespec with the Yosys formal chain,
# which is exactly why it has to be composed here.
ARG HDL_FORMAL=ghcr.io/sigil-logic/aivhai-hdl-formal:latest
ARG SOLVERS=ghcr.io/sigil-logic/aivhai-solvers:latest

FROM ${SOLVERS} AS solvers
FROM ${HDL_FORMAL}

LABEL org.opencontainers.image.source="https://github.com/Sigil-Logic/AIVHAI-Sigil" \
      sl.layer="extended-cv" \
      org.opencontainers.image.description="Yosys + SBY + Boolector + bsc + sv2v: the licence-free proof image" \
      org.opencontainers.image.licenses="ISC AND BSD-3-Clause AND MIT AND GPL-3.0-only AND Apache-2.0 AND BSD-2-Clause AND GPL-2.0-only AND LicenseRef-ABC-UCBerkeley" \
      sl.licenses.manifest="/opt/aivhai/licenses/MANIFEST.tsv"

USER root
# One directory per layer is what makes this a copy rather than a reinstall.
COPY --from=solvers /opt/aivhai/what4-solvers /opt/aivhai/what4-solvers
# Yices 2.7.0 travels too.  The snapshot's 2.6.5 is what goes on PATH, because
# this image runs the Galois-validated task set and a Galois tool is guaranteed
# against the set Galois ships.  2.7.0 is present for a consumer that asks for
# it by prefix -- installed, reachable, and not shadowing.
COPY --from=solvers /opt/aivhai/yices-2.7.0 /opt/aivhai/yices-2.7.0
# The solver licences travel with the solver binaries.  An aggregate image
# that drops them is the compliance failure, not the layer that had them.
COPY --from=solvers /opt/aivhai/licenses /opt/aivhai/licenses-solvers

# SBY invokes solvers by name, so the snapshot IS on PATH in this image --
# unlike the solvers layer itself, which deliberately leaves it off.  That is
# a considered difference and not an inconsistency: this image exists to run
# one validated task set with one validated solver set, so shadowing a modern
# Z3 is the intended behaviour here and the hazard everywhere else.
ENV PATH="/opt/aivhai/what4-solvers:${PATH}"

# A proof result has to name the tools that produced it, so the image can say
# what it is without anyone running the tools by hand to find out.
RUN set -eux; \
    install -d -m 0755 /opt/aivhai/provenance; \
    { echo "# AIVHAI Extended-CV image provenance"; \
      cat /opt/aivhai/provenance/yosys 2>/dev/null || true; \
      cat /opt/aivhai/provenance/sv2v  2>/dev/null || true; \
      cat /opt/aivhai/provenance/bsc   2>/dev/null || true; \
      cat /opt/aivhai/what4-solvers/.provenance 2>/dev/null || true; \
    } > /opt/aivhai/provenance/extended-cv
COPY provenance.sh /opt/aivhai/bin/aivhai-provenance
RUN chmod 0755 /opt/aivhai/bin/aivhai-provenance

USER aivhai
CMD ["/opt/aivhai/bin/aivhai-provenance"]
