#!/usr/bin/env bash
# negative-control.sh --- run the yosys-toolchain.md checks INSIDE an image.
#
# Status:  Living script
# Version: 1.0.0
# Date:    2026-09-22
# Project: AIVHAI
# Issue:   https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/67
#
# Usage:  infra/containers/negative-control.sh [image]
#         (default: ghcr.io/sigil-logic/aivhai-extended-cv:dev)
#
# WHY THIS EXISTS AND WHY IT IS THE ACCEPTANCE CRITERION.  From
# docs/tools/yosys-toolchain.md: "A chain that passes everything, including
# false properties, is worse than no chain -- it manufactures confidence."
# An image that prints version numbers proves nothing.  This asks the image to
# prove a TRUE property and then to FAIL a false one, and treats a pass on the
# false property as the worst possible outcome rather than as a curiosity.
#
# THE FIVE CHECKS, from that document's own table:
#
#   N1  synth_ice40 on a counter completes
#   N2  read_verilog -formal -> prep -> write_smt2 produces SMT2
#   N3  SBY proves a TRUE property: DONE (PASS), rc=0
#   N4  SBY REFUTES a false property: DONE (FAIL), rc=2, with a counterexample
#   N5  the run records WHICH yosys and WHICH solver produced the result
#
# N4 IS THE LOAD-BEARING ONE.  N1 to N3 can all pass on a broken chain that
# says yes to everything.  Only N4 distinguishes a working prover from an
# agreeable one, and its expected exit status is 2 -- so a naive `set -e`
# harness would treat the correct outcome as a failure and the incorrect one
# as success.  That inversion is why the rc is asserted explicitly.

set -uo pipefail

IMAGE="${1:-ghcr.io/sigil-logic/aivhai-extended-cv:dev}"
command -v docker >/dev/null || { echo "negative-control: docker is not installed" >&2; exit 2; }
docker image inspect "$IMAGE" >/dev/null 2>&1 \
  || { echo "negative-control: image $IMAGE is not present locally" >&2; exit 2; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

# A counter, and two properties about it: one true, one deliberately false.
cat > "$WORK/counter.sv" <<'SV'
module counter (input clk, input rst, output reg [3:0] count);
  always @(posedge clk) begin
    if (rst) count <= 4'd0;
    else     count <= count + 4'd1;
  end
`ifdef FORMAL
  // TRUE: four bits cannot exceed 15, so this holds at every depth.
  always @(*) assert (count <= 4'd15);
`endif
endmodule
SV

cat > "$WORK/false.sv" <<'SV'
module counter (input clk, input rst, output reg [3:0] count);
  always @(posedge clk) begin
    if (rst) count <= 4'd0;
    else     count <= count + 4'd1;
  end
`ifdef FORMAL
  // FALSE by construction: reachable at depth 4 from reset.  A chain that
  // reports PASS here is manufacturing confidence, which is the failure this
  // whole check exists to detect.
  always @(*) assert (count != 4'd3);
`endif
endmodule
SV

cat > "$WORK/true.sby" <<'SBY'
[options]
mode bmc
depth 15

[engines]
smtbmc z3

[script]
read -formal counter.sv
prep -top counter

[files]
counter.sv
SBY

sed -e 's/counter\.sv/false.sv/g' "$WORK/true.sby" > "$WORK/false.sby"

pass=0; fail=0
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  FAIL  %s\n' "$1"; fail=$((fail+1)); }

run() { docker run --rm --platform linux/amd64 -v "$WORK:/work" -w /work "$IMAGE" bash -c "$1" 2>&1; }

echo "negative-control: $IMAGE"

# ---- N1 ------------------------------------------------------------------
if run 'yosys -p "read_verilog counter.sv; synth_ice40 -top counter" >/dev/null 2>&1 && echo OK' | grep -q OK; then
  ok "N1 synth_ice40 on a counter completes"
else
  bad "N1 synth_ice40 did not complete"
fi

# ---- N2 ------------------------------------------------------------------
n2=$(run 'yosys -p "read_verilog -formal -DFORMAL counter.sv; prep -top counter; write_smt2 /tmp/out.smt2" >/dev/null 2>&1; wc -l < /tmp/out.smt2 2>/dev/null || echo 0')
if [ "${n2:-0}" -gt 0 ] 2>/dev/null; then
  ok "N2 write_smt2 produced $(printf '%s' "$n2" | tr -d ' ') lines of SMT2"
else
  bad "N2 write_smt2 produced nothing"
fi

# ---- N3: a TRUE property must be proved ----------------------------------
n3=$(run 'sby -f true.sby >/dev/null 2>&1; echo "rc=$?"; grep -hoE "DONE \(PASS|DONE \(FAIL" true/logfile.txt 2>/dev/null | tail -1')
case "$n3" in
  *"rc=0"*"DONE (PASS"*) ok "N3 SBY proved the true property, rc=0" ;;
  *) bad "N3 expected rc=0 and DONE (PASS); got: $(printf '%s' "$n3" | tr '\n' ' ')" ;;
esac

# ---- N4: a FALSE property must be REFUTED --------------------------------
# rc=2 is the CORRECT outcome.  A harness that treats non-zero as failure
# scores this backwards, which is exactly the confusion the check guards.
n4=$(run 'sby -f false.sby >/dev/null 2>&1; echo "rc=$?"; grep -hoE "DONE \(PASS|DONE \(FAIL" false/logfile.txt 2>/dev/null | tail -1; ls false/engine_0/*.vcd >/dev/null 2>&1 && echo VCD')
case "$n4" in
  *"rc=2"*"DONE (FAIL"*)
    if printf '%s' "$n4" | grep -q VCD; then
      ok "N4 SBY refuted the false property, rc=2, with a counterexample VCD"
    else
      ok "N4 SBY refuted the false property, rc=2 (no VCD emitted)"
    fi
    ;;
  *"DONE (PASS"*)
    bad "N4 SBY PASSED A FALSE PROPERTY -- this chain manufactures confidence and must not be used" ;;
  *)
    bad "N4 expected rc=2 and DONE (FAIL); got: $(printf '%s' "$n4" | tr '\n' ' ')" ;;
esac

# ---- N5: attribution ------------------------------------------------------
n5=$(run 'yosys -V 2>/dev/null | head -1; cat /opt/aivhai/provenance/yosys 2>/dev/null | head -2')
if printf '%s' "$n5" | grep -qi yosys; then
  ok "N5 the image records its Yosys: $(printf '%s' "$n5" | head -1)"
  printf '%s\n' "$n5" | tail -n +2 | sed 's/^/        /'
else
  bad "N5 the image does not report which Yosys it carries"
fi

echo
echo "negative-control: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
