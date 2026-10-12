#!/usr/bin/env bash
# Print what this image actually contains, by ASKING THE TOOLS rather than by
# reading the labels that were written when it was built.  A recorded version
# and an installed version disagree eventually, and the recorded one is the
# one that looks right.  #67's acceptance criterion wants a linux/amd64 run
# distinguishable from a local arm64 one, and this is what makes that
# recordable per result.
set -u
echo "# AIVHAI Extended-CV"
echo "arch:        $(uname -m)"
echo "yosys:       $(yosys -V 2>/dev/null | head -1 || echo absent)"
echo "sby:         $(sby --version 2>/dev/null | head -1 || echo absent)"
echo "sv2v:        $(sv2v --version 2>/dev/null | head -1 || echo absent)"
echo "bsc:         $(bsc -v 2>/dev/null | head -1 || echo absent)"
echo "boolector:   $(boolector --version 2>/dev/null | head -1 || echo absent)"
echo "z3:          $(z3 --version 2>/dev/null | head -1 || echo absent)"
echo "yices:       $(yices --version 2>/dev/null | head -1 || echo absent)   [on PATH: the Galois-shipped build]"
echo "yices-2.7.0: $(/opt/aivhai/yices-2.7.0/bin/yices --version 2>/dev/null | head -1 || echo absent)   [by prefix, not on PATH]"
echo "cvc5:        $(cvc5 --version 2>/dev/null | head -1 || echo absent)"
echo "bitwuzla:    $(bitwuzla --version 2>/dev/null | head -1 || echo absent)"
echo
echo "# recorded at build time"
cat /opt/aivhai/provenance/extended-cv 2>/dev/null || echo "(none recorded)"
