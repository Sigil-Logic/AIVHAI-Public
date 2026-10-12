#!/usr/bin/env bash
# smoke.sh --- verify the aivhai-cheri-rvy image does what it claims, from inside it.
#
# Status:  Living script
# Version: 1.0.0
# Date:    2026-10-01
# Project: AIVHAI
# Issue:   https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/95
#
# Usage:  docker run --rm --network none IMAGE aivhai-cheri-rvy-smoke
#
# Installed in the image as aivhai-cheri-rvy-smoke, so the check that ran is
# the check that ships.  Run with --network none: the acceptance criterion is
# that the image works with no network and no further setup.
#
# A BUILD THAT SUCCEEDED IS NOT EVIDENCE.  Each check below either exercises
# the RVY-specific behaviour or is a negative control showing the check can
# fail.  The negative control matters most: a clang that accepted every
# -march string would pass the positive check and prove nothing.
set -uo pipefail

SDK="${RVY_SDK:-/opt/aivhai/rvy-sdk}"
B="$SDK/bin"
# cheribuild's own RVY arch string for riscv64y (compilation_targets.py,
# get_riscv_arch_string).  Check 2 compiles it with the hybrid ABI, lp64d;
# check 3 with the purecap ABI, l64pc128d.
MARCH=rv64ymafdczyhybrid_zylevels1b
PASS=0 FAIL=0
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

ok()   { echo "  PASS  $*"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }

echo "aivhai-cheri-rvy smoke test, SDK $SDK"

# 1. Every binary resolves its shared libraries.  A missing runtime library is
#    the commonest way a multi-stage image builds and then cannot run.
#    Each executable is CLASSIFIED rather than assumed to be ELF: an ELF must
#    pass ldd (or be static), a script must start with #!, and anything else,
#    or any unexplained ldd error, fails.  ldd errors used to be discarded, so
#    an executable garbage file passed (HOARDE Codex, #128 Cycle 2).
nelf=0 nscript=0 problems=""
for f in "$B"/*; do
  [ -x "$f" ] && [ -f "$f" ] || continue
  magic="$(head -c4 "$f" | od -An -c | tr -d ' ')"
  if [ "$magic" = '177ELF' ]; then
    nelf=$((nelf+1))
    # Four magic bytes are not an ELF: a 5-byte "\177ELF\n" passed as a
    # "static" binary (HOARDE Codex, #128 Cycle 3).  The header must parse.
    if ! "$B/llvm-readelf" -h "$f" >/dev/null 2>&1; then
      problems="$problems"$'\n'"$(basename "$f"): ELF magic, but the header does not parse"
      continue
    fi
    out="$(ldd "$f" 2>&1)"; lrc=$?
    if printf '%s' "$out" | grep -q 'not found'; then
      problems="$problems"$'\n'"$(basename "$f"): $(printf '%s' "$out" | grep 'not found' | head -1)"
    elif [ "$lrc" -ne 0 ] && ! printf '%s' "$out" | grep -q 'not a dynamic executable'; then
      problems="$problems"$'\n'"$(basename "$f"): ldd failed: $(printf '%s' "$out" | head -1)"
    fi
  elif [ "$(head -c2 "$f")" = '#!' ]; then
    nscript=$((nscript+1))
  else
    problems="$problems"$'\n'"$(basename "$f"): executable, but neither ELF nor a #! script"
  fi
done
if [ "$nelf" -eq 0 ]; then bad "no ELF executables in $B; check 1 has nothing to check"
elif [ -z "$problems" ]; then ok "all $nelf ELF binaries in bin/ resolve their shared libraries ($nscript scripts not applicable)"
else bad "bin/ problems:$problems"; fi

# 2. clang compiles an RVY object, and the object is RVY.
printf 'int f(int *p) { return *p; }\n' > "$T/a.c"
if "$B/clang" --target=riscv64-unknown-elf -march="$MARCH" -mabi=lp64d -c "$T/a.c" -o "$T/a.o" 2> "$T/clang.err"; then
  attrs="$("$B/llvm-readelf" --arch-specific "$T/a.o" 2>/dev/null | tr -d '\n')"
  case "$attrs" in *zyhybrid*) ok "clang -march=$MARCH emits an object whose RISC-V attributes name zyhybrid" ;;
                   *) bad "object built, but its attributes do not name zyhybrid: $attrs" ;; esac
else
  bad "clang rejected -march=$MARCH: $(head -1 "$T/clang.err")"
fi

# 3. The purecap ABI, l64pc128d, compiles, and it is not the hybrid ABI under
#    another name: the object's e_flags must differ from check 2's.  (Measured
#    2026-10-02: hybrid 0x5, purecap 0x45.)
hflags="$("$B/llvm-readelf" -h "$T/a.o" 2>/dev/null | awk '/Flags:/{print $2}')"
if [ -z "$hflags" ]; then
  bad "no hybrid e_flags to compare against (check 2's object is missing or unreadable)"
elif "$B/clang" --target=riscv64-unknown-elf -march="$MARCH" -mabi=l64pc128d -c "$T/a.c" -o "$T/p.o" 2> "$T/pc.err"; then
  pflags="$("$B/llvm-readelf" -h "$T/p.o" 2>/dev/null | awk '/Flags:/{print $2}')"
  if [ -n "$pflags" ] && [ "$pflags" != "$hflags" ]; then
    ok "clang -mabi=l64pc128d emits a purecap object (e_flags ${pflags%,}, hybrid ${hflags%,})"
  else
    bad "purecap object's e_flags (${pflags:-none}) do not differ from hybrid (${hflags:-none})"
  fi
else
  bad "clang rejected -mabi=l64pc128d: $(head -1 "$T/pc.err")"
fi

# 4. lld links the RVY object into an executable.  Checks 2 and 3 only compile.
if "$B/ld.lld" -e f "$T/a.o" -o "$T/a.elf" 2> "$T/ld.err" \
   && "$B/llvm-readelf" -h "$T/a.elf" 2>/dev/null | grep -q 'EXEC'; then
  ok "ld.lld links the RVY object into an executable"
else
  bad "ld.lld did not link an executable: $(head -1 "$T/ld.err")"
fi

# 5. NEGATIVE CONTROL: clang rejects an extension that does not exist.  If
#    this passes, check 2 shows nothing.
if "$B/clang" --target=riscv64-unknown-elf -march="${MARCH}_zyfabricated" -c "$T/a.c" -o "$T/b.o" 2>/dev/null; then
  bad "negative control: clang ACCEPTED a fabricated extension; check 2 is not evidence"
else
  ok "negative control: clang rejects a fabricated extension"
fi

# 6. QEMU boots the image's own RVY OpenSBI, AND the hart it reports is RVY.
#    A banner alone would show that some OpenSBI ran on some RISC-V; the
#    "Boot HART ISA Extensions" line naming rvy is what shows it is this one.
#    fw_dynamic with no payload prints the banner and then has nowhere to go,
#    so a timeout after the banner is the expected ending, not a failure.
#    No -append: QEMU allows it only with -kernel, and the first build's run
#    of this check failed on exactly that (2026-10-01).
fw="$(find "$SDK" -path '*riscv64y*' -name fw_dynamic.bin 2>/dev/null | head -1)"
if [ -z "$fw" ]; then
  bad "no riscv64y fw_dynamic.bin under $SDK"
elif [ ! -x "$B/qemu-system-riscv64y" ]; then
  bad "no qemu-system-riscv64y in $B"
else
  timeout 20 "$B/qemu-system-riscv64y" -M virt -cpu rv64,Svyrg=true,Zylevels1=true \
    -nographic -bios "$fw" 2>&1 | tr -d '\r' > "$T/qemu.out" || true
  # The serial console ends lines with CR LF.  Unstripped, the CR in the ISA
  # string returned the cursor mid-message, so the report's closing ")"
  # printed at the start of the line on fm (2026-10-01).  Cosmetic, but the
  # report is evidence, and evidence should read correctly.
  ext="$(grep 'Boot HART ISA Extensions' "$T/qemu.out" | head -1)"
  if grep -q 'OpenSBI v' "$T/qemu.out" && printf '%s' "$ext" | grep -qw rvy; then
    ok "qemu-system-riscv64y boots the image's RVY OpenSBI; hart reports rvy ($(grep 'Boot HART Base ISA' "$T/qemu.out" | sed 's/.*: *//'))"
  elif grep -q 'OpenSBI v' "$T/qemu.out"; then
    bad "OpenSBI booted, but the hart does not report rvy: $ext"
  else
    bad "no OpenSBI banner from qemu-system-riscv64y; first lines: $(head -3 "$T/qemu.out" | tr '\n' ' ')"
  fi
fi

# 7. RVFI-DII is compiled in: the interface TestRIG drives for tandem runs of
#    Sail against QEMU.  CHERI QEMU builds it only under --enable-rvfi-dii, and
#    the first published image lacked it.  With it, QEMU accepts -rvfi-dii-port,
#    PRINTS that it is listening and waiting for RVFI packets, and blocks.
#    Without it, QEMU exits at once with "invalid option", exactly as for a
#    made-up option.  Both messages are required, because a timeout alone
#    proves only that something hung (HOARDE Codex, #128 Cycle 2).
#    This shows the interface is present, NOT that a tandem run works; that is
#    AIVHAI-Sigil#126.
if [ -x "$B/qemu-system-riscv64y" ]; then
  timeout 10 "$B/qemu-system-riscv64y" -M virt -nographic -bios none \
    -rvfi-dii-port $((40000 + $$ % 20000)) 2>&1 | tr -d '\r' > "$T/rvfi.out"; rc=${PIPESTATUS[0]}
  if [ "$rc" -eq 124 ] && grep -q 'Listening for remote rvfi_dii connection' "$T/rvfi.out" \
     && grep -q 'Waiting for incoming RVFI socket packets' "$T/rvfi.out"; then
    ok "qemu-system-riscv64y accepts -rvfi-dii-port and waits for a TestRIG connection (interface present; no tandem run)"
  else
    bad "qemu-system-riscv64y has no RVFI-DII (rc=$rc): $(head -1 "$T/rvfi.out")"
  fi
else
  bad "no qemu-system-riscv64y in $B; RVFI-DII cannot be checked"
fi

# 8. qemu-system-riscv32y runs.  ONLY that: no 32-bit OpenSBI is built, so the
#    32-bit emulator is not booted and not shown to execute RVY code.
# The banner is required, not merely exit 0: a no-op stub exits 0 too
# (HOARDE Codex, #128 Cycle 3).
if "$B/qemu-system-riscv32y" --version > "$T/q32.out" 2>&1 \
   && grep -q '^QEMU emulator version ' "$T/q32.out"; then
  ok "qemu-system-riscv32y runs ($(head -1 "$T/q32.out")); not booted, not RVY-tested"
else
  bad "qemu-system-riscv32y failed to run: $(head -1 "$T/q32.out")"
fi

# 9. gdb runs and knows RISC-V.  This does NOT show it knows the RVY
#    capability registers; that needs a live target and is not claimed here.
#    gdb exits 0 even for an architecture it does not know -- it prints
#    "Undefined item" and stays on auto/i386 -- so exit status shows nothing.
#    The exact confirmation is required, and any diagnostic fails (HOARDE
#    Codex, #128 Cycle 3).
if "$B/gdb" --batch -ex 'set architecture riscv:rv64' -ex 'show architecture' > "$T/gdb.out" 2>&1 \
   && grep -qxF 'The target architecture is set to "riscv:rv64".' "$T/gdb.out" \
   && ! grep -qE 'Undefined item|auto|error' "$T/gdb.out"; then
  ok "gdb runs and accepts riscv:rv64 (RVY registers not checked) ($(head -1 "$T/gdb.out"))"
else
  bad "gdb failed: $(head -1 "$T/gdb.out")"
fi

# 10. Provenance: clang embeds its source commit, and it must be the pin.  The
#     pin itself is validated first: an empty or malformed pin would otherwise
#     make the match vacuous -- grep for "" matches everything (HOARDE Codex,
#     #128).  QEMU, GDB and OpenSBI embed no commit; by PI decision their
#     provenance rests on the fetch-time check (AIVHAI-Sigil#95).
llvm_pin="$(awk -F'\t' '$1=="rvy-llvm"{print $4}' "$SDK/SOURCES.tsv" 2>/dev/null)"
case "$llvm_pin" in
  *[!0-9a-f]*|"") bad "SOURCES.tsv has no well-formed rvy-llvm pin: '${llvm_pin}'" ;;
  *) if [ "${#llvm_pin}" -ne 40 ]; then
       bad "SOURCES.tsv rvy-llvm pin is not 40 hex digits: '${llvm_pin}'"
     elif "$B/clang" --version | grep -qwF "$llvm_pin"; then
       ok "clang --version names the full pinned commit $llvm_pin"
     else
       bad "clang --version does not name the full pinned commit $llvm_pin: $("$B/clang" --version | head -1)"
     fi ;;
esac
"$B/qemu-system-riscv64y" --version | head -1 | sed 's/^/  INFO  /'

echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
