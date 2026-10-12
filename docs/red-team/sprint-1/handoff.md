# Sprint 1 Hand-off to the Red Team

**Status**: Living document  
**Version**: 0.7.1  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53), [#4](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/4)  

---

This is Sigil Logic's hand-off for Sprint 1's red-team week, which begins on **Monday 2026-10-12**.  **It is a practice run**: four weeks into the contract, the consortium is warming up its development and assurance pipeline, and bringing the whole team onto the technologies and the methodology.  It is a first showing of what a hand-off contains, not a Sprint 1 assurance package.

**What we ask you to evaluate** is two artifacts, with their documentation.  The first is Capabilities Limited's **RVY Sail model**, with the most recent fixes, read against the human-readable RVY draft specification.  The second is Capabilities Limited's **bare-metal compartment firmware**.  In the very short term the consortium is beating the instruction-set specification into shape, and what we would most like is any defect, against the specification or against what it is meant to achieve, that could lead to security harm and that motivates a change to the specification and the Sail model.  We make no proved claim about either artifact this sprint.

**What else is here, and why.**  The defects found this week are included as illustrations ("Found before this hand-off" below).  So is the project's broader assurance corpus, to show where the work is going: the threat model, the assurance-case skeleton, the census of prior work, and **one proved theorem about the CHERIoT abstract specification**.  The CHERIoT material is here for pedagogy: to show what a mechanised Rocq proof and a structured case around it look like, and to ask for your reflections on how it is packaged.  **It is not offered for red-teaming.**  CHERIoT is a 32-bit embedded design, not AIVHAI's 64-bit core, and nothing proved about it is evidence about AIVHAI.

[`REDTEAM.md`](../../../REDTEAM.md), at the root of the release, is the map of how all of this fits together.

## What to evaluate, and what accompanies it

| Target                             | Repository and commit                                                                                                                                                 | What we ask you to look at                                                                                                            |
|------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| The RVY Sail model                 | `Capabilities-Limited/sail-cheri-riscv@84515a85ead058eb2cc8bffb45496979f2dbdd7c` (branch `0.9.9-undo-branch-restriction`; mirrored in `Sigil-Logic/sail-cheri-riscv`) | Divergence from the RVY specification, or from its intent, that could lead to security harm; any undocumented divergence is a finding |
| The RVY specification              | `riscv/riscv-cheri@2946806c10910c12c1b9dc6153e9b0d56ccd8ce6` (tag `riscv-isa-release-2946806-2026-08-25`)                                                             | The reference for the audit above.  Problems in the specification itself are welcome too                                              |
| The CHERIoT abstract specification | `Sigil-Logic/cheriot-abstract-spec@2bab36ad8c0bd25765d0f2dba1e12654abd4157f` (tag `handoff/2026-10-12`, the fork's `main`)                                            | **Not an evaluation target.**  Included for pedagogy: what a Rocq proof and its case look like, and how such material is packaged     |

The model's commit carries Peter Rugg's fix *"JALR must not unseal target cap on non-zero imm"* (2026-10-06, as `2d4a383`) and the three fixes of 2026-10-11 described under "Found before this hand-off" below.  Errors of that kind are the ones we want found, and the risk of them is greatest when translating from CHERI-MIPS and Morello to RVY.

**The model is not on the branch named on 2026-10-08.**  That discussion named the head of `0.9.9-upgrade`.  No commit on that branch carries all of the 2026-10-11 fixes: its tip, `5083802`, has only the first.  The model offered is therefore the tip of `0.9.9-undo-branch-restriction` (Joe Kiniry, 2026-10-11).  That branch has the fixes and is the one Capabilities Limited's demo builds, so the audit and the demo use one model.  It has diverged from `0.9.9-upgrade` (11 commits ahead, 5 behind).  The fixes still await Capabilities Limited's upstream review.

**Capabilities Limited's compartment firmware is the second evaluation artifact**, `Capabilities-Limited/aivhai-fw-compartment@9691cf2e0c092f880f0aa57c7c3e70abf95b1b1e`: a bare-metal firmware image, run on the Sail model above, that enters a compartment the red team populates with its own code, with named assets outside it to reach.  Its instructions and rules are Capabilities Limited's own hand-off, and this note covers Sigil Logic's.  The threat model takes the demo's four protections as threats TM-013 to TM-016, the project case attaches it to goals G-CF4 and G-CF7, and [`REDTEAM.md`](../../../REDTEAM.md) §5 says what a capture would falsify.

Every upstream this release depends on is pinned by commit in `RELEASE.json`, under `pins.aivhai_everything.manifest`.  The list is copied from Sigil Logic's pin repository, `Sigil-Logic/AIVHAI-Everything@0cca9e107dc518c12fcdbce43dc0e1ef544d928b` (tag `deliverable/sprint-1-handoff-2026-10-12`), to which the red team also has write access: you are welcome to push your own branches there, for example a re-pin or a proposed model change, as feedback.

## The claims

### Claim 1 — the RVY Sail model: properties stated, none proved

We claim no proved property of the Sail model for this hand-off.  We do state the properties we intend to prove, informally, so that the audit can test the model against them.  We call them **RVY properties**, numbered RP1 to RP5, so that a finding or a message can name one briefly.  A divergence from the specification that would break one of them is the most valuable kind of finding.  None of these is proved.  Each is a statement of intent, in the tradition of the CHERI-MIPS and Morello proofs.  In Sigil Logic's requirements they are the five scenarios of one requirement, capability monotonicity of the Sail model (`AIVHAI-SYS-R01`, scenarios S1 to S5): RP1 is the property, and RP2 to RP5 are the per-instruction facts its proof is expected to decompose into.

| Id  | Informal property                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|-----|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| RP1 | **Authority never increases.**  Call a capability *valid* if it is tagged, and *reachable* if it is a valid capability in a register (including the program counter and special capability registers) or a valid capability in memory loadable through a reachable capability, transitively, whoever believes they own that memory.  After a sequence of instructions that makes no sentry call or return and takes no trap, every reachable capability confers no more authority than some capability reachable at the start: its bounds lie within, and its permissions are a subset of, that capability's.  New capabilities may be derived, for example by narrowing bounds; what cannot happen is reaching authority that was not already reachable.  This is the Sprint 1 proof target |
| RP2 | **Bounds never widen.**  If an instruction derives a valid capability, its bounds lie within those of the valid capability it was derived from.  For `YBNDSRW`, which must round requests the compressed encoding cannot represent exactly, the result is valid only if the rounded bounds stay within the source's; a request that cannot be met that way yields an invalid result                                                                                                                                                                                                                                                                                                                                                                                                          |
| RP3 | **Permissions never grow.**  If an instruction derives a valid capability, its permissions are a subset of those of the valid capability it was derived from                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| RP4 | **Tags cannot be forged.**  The architecture provides root capabilities at reset.  From then on, every valid capability in a register or in memory was derived from a valid capability; no instruction makes a valid capability from data, and writing data over a capability's storage leaves it invalid                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| RP5 | **Sentries are opaque.**  A valid sentry grants no authority while sealed: it cannot be used to load, store, or fetch, and modifying it leaves it invalid.  A valid unsealed capability is obtained from it only by the operations the RVY specification provides for that, and confers no more authority than the sentry with its seal removed.  We take those operations to be an indirect jump to it with a zero offset, a trap return through an exception program counter register holding it, and `YUNSEALS`; whether each is admitted, and whether `YUNSEALS` counts as unsealing or as rederivation, is an open question to Capabilities Limited.  The model's `JALR` fix (a non-zero offset must not unseal) is an instance of this property                                        |

The wording was revised after Jessica Clarke's review on 2026-10-09, which pointed out that the first version was trivially false as written for RP1, was missing "valid" throughout, and was vague about unsealing.  Capabilities Limited owns the model, and so whether these properties match its own understanding of RVY matters.  Status, 2026-10-11: the steer this hand-off follows was agreed that day between Joe Kiniry and Robert Watson; Capabilities Limited has not yet confirmed RP1 to RP5 property by property, so they are offered as Sigil Logic's audit hypotheses.

The proof plan for RP1 is an assurance case in which nothing is proved and every leaf goal is undeveloped: [`../assurance-case/rvy-sail-monotonicity.case.md`](../assurance-case/rvy-sail-monotonicity.case.md).  Its expected crux is RP2 for `YBNDSRW` under the RVY capability encoding.  We would welcome the red team's view on where else the proof is likely to be hard.

In the project-level case ([`../../../specs/assurance/aivhai-case.md`](../../../specs/assurance/aivhai-case.md)), RP1 is goal G-a1, undeveloped, with this plan attached as its context, and the model's adherence to the specification is assumption A-1.  The threat model's TM-001 to TM-003 and TM-049 are the threats G-a1 answers; TM-006 and TM-050, a model that departs from the specification and a departure copied into hardware validated against the model, are what A-1 covers.  The record of prior work says what is new: every one of RP1 to RP5 has been proved for some CHERI design, and none at instruction-sequence level for a RISC-V CHERI ISA.

### Claim 2 — CHERIoT thread-isolated monotonicity: an example for pedagogy, not an evaluation target

This claim is included to show what a mechanised theorem, its scope, its assumptions, its open doubts and its recorded evidence look like when they are handed over, and we would value your reflections on that packaging.  We do not ask you to red-team it.

The statement, from `src/Properties.v` line 2867.  Every line reference in this note is at commit `2bab36ad8c0bd25765d0f2dba1e12654abd4157f`, the hand-off commit, tagged `handoff/2026-10-12` on the fork's `main`:

```coq
Theorem ThreadIsolatedMonotonicity :
  forall config initial_machine,
  WFConfig config ->
  ValidInitialMachine config initial_machine ->
  Combinators.always MachineStep (PThreadIsolatedMonotonicity initial_machine) (initial_machine, []).
```

**What it says.**  Take a well-formed configuration and a valid initial machine whose threads start with pairwise-disjoint read/write reach.  In every state reachable by the step relation **whose trace so far contains only same-domain events**, each thread can reach only capabilities that were reachable from its initial state.  Thread isolation, the disjoint read/write reach, is assumed of the initial machine and is maintained by the proof's invariant along such traces, because one thread's step must not enlarge what an idle thread can reach; it is not part of the theorem's conclusion.  Same-domain events are general instructions and thread switches, and the specification models thread switches as no-ops.

The theorem is **parametric**: it holds for every choice of the instruction-set parameters (the capability encoding, the fetch function, the decoder, and others; Properties.v lines 2540 to 2553), and no concrete choice is claimed.

**What it does not say.**  `PThreadIsolatedMonotonicity` (line 2617) is an implication from `SameDomainTrace` of the whole trace.  After the first compartment call, compartment return, or exception, the property holds vacuously.  It says nothing about such events or anything after them.  The switcher's contracts are specified (lines 893 to 1798) but not proved.

**What it assumes.**

- `WFConfig` (line 350) and `ValidInitialMachine` (line 2593).  Two places in the specification bear on whether these can be satisfied and are marked as unfinished: a commented-out memory invariant (line 457) and an initial-stack condition marked "TODO: fix spec" (line 577).
- **Every instruction is well formed.**  Each general instruction carries a proof of `WfGeneralInst` (Spec.v line 684), which includes the instruction's own reachable-capability monotonicity.  The theorem lifts that assumed per-instruction property to whole executions.  No instruction set's instructions are shown to satisfy it in this development.
- The Rocq 9.1.0 kernel and the toolchain in the `aivhai-provers` image (its `saw` switch: `rocq-core` 9.1.0, `rocq-stdlib` 9.0.0).

**A doubt, and what remains of it.**  The specification's author noted that `FuncNormal`, part of the instruction hypothesis, applied the instruction to memory `m1` twice (Spec.v lines 508 and 509 at `f754796`) where `m2` was intended.  The author's fix (OpenSeCura `21cd9bf`) is in the hand-off commit as its own one-line change (`3917ac6`); the proof script is otherwise unchanged apart from comments, and the theorem checks at that commit: the build and the `Print Assumptions` output below are recorded against the corrected hypothesis.  That rebuts the case's defeater D1, the mis-statement.  What remains, as the case's open defeater D2: no instruction is shown to satisfy the hypothesis as now stated, and if none does the theorem is vacuous.  A build and `Print Assumptions` cannot answer that; a witness instruction would.

**Proof state.**  The proof goes by an inductive invariant (`Invariant`, line 2637) through the establish-preserve-use rule `Combinators.always` (Utils.v line 27), and it is closed with `Qed`.  `always` is defined, not assumed: it holds when some invariant holds initially, is preserved by every step, and implies the property, and the reading "in every reachable state" above follows from that by induction on steps.  The build log (case evidence E3) and the `Print Assumptions` output (E2) are recorded in this release under `.evidence/cheriot-abstract-spec/`: `cheriot-2bab36a-build.log` (E3), `cheriot-2bab36a-print-assumptions.log` (E2), and `cheriot-2bab36a-2026-10-11.md`, the record of the run, and `cheriot-2bab36a-replay-2026-10-11.md`, the end-to-end replay of every evidence node from fresh checkouts in the pinned image (3 nodes, 0 failed): host, image digest, switch, and the commands as run.

The full argument is [`../assurance-case/cheriot-thread-isolated-monotonicity.case.md`](../assurance-case/cheriot-thread-isolated-monotonicity.case.md).  In the project-level case it is context C-CF5, the precedent J-CF2 offers for the shape the firmware's formal model (goal G-CF2) is expected to take, and evidence for no AIVHAI goal; that case carries this case's open defeater D2 upward as its D3.

## How to build and re-run

The toolchain image is `aivhai-provers`, pinned by digest in this release's `RELEASE.json` under `pins.images`.  Its definition is `infra/containers/provers/` in this release.

```bash
# The CHERIoT abstract specification (Claim 2), on the saw switch (Rocq 9.1.0)
git clone https://github.com/Sigil-Logic/cheriot-abstract-spec && cd cheriot-abstract-spec
git checkout handoff/2026-10-12   # = 2bab36ad8c0bd25765d0f2dba1e12654abd4157f
AIVHAI_PROVERS="$(jq -r '.pins.images["aivhai-provers"]' /path/to/AIVHAI-Public/RELEASE.json)"
docker run --rm -v "$PWD":/work -w /work "$AIVHAI_PROVERS" \
  bash -lc 'eval "$(opam env --switch=saw --set-switch)" && make'
```

The development does not build on Rocq 9.3, nor on the image's `guru` switch, which carries no standard library; use `saw`, Rocq 9.1.0 with `rocq-stdlib` 9.0.0.  The Sail model builds as its upstream README describes.  Note that Capabilities Limited validates it with Sail 0.18, while `aivhai-provers` carries Sail 0.20.2, and agreement between the two on this model is still being measured.

## Known gaps this sprint

The full list is [`../known-gaps.md`](../known-gaps.md).  The ones that bear on this hand-off are these:

- No property of the Sail model is claimed, and RP1 to RP5 are statements of intent.
- The CHERIoT theorem, included for pedagogy: its same-domain restriction and its assumed instruction hypothesis.
- Defeater D1, the mis-statement in that hypothesis, is rebutted at the hand-off commit.  Defeater D2 is open: no instruction is shown to satisfy the hypothesis as now stated.
- The threat model and the project-level case are first drafts: every leaf goal of the case is undeveloped, and the threat model's nine known gaps are open.
- The NPU's memory path is not a DMA path: the accelerator is part of the core and is designed to be checked like the core.  That every vector and matrix access is so checked is goal G-c4, unproved.  DMA by other devices, through the IOPMP and IOMMU, is not modelled.

## Found before this hand-off

This is the first hand-off, so no earlier sprint has findings.  These are included as illustrations of the defects we most want found, with both the changes and Capabilities Limited's write-up, which is in this release as [`isa-issues-2026-10-11.md`](isa-issues-2026-10-11.md), with two passages omitted at its author's request.  Capabilities Limited describes the findings as preliminary research results, to be validated further before the fixes are merged upstream.  The `JALR` fix took two attempts: the first, `716106581bb5` of 2026-10-06, came from manual review and was incomplete.  Two divergences of the model from the RVY specification were found on 2026-10-11, the day before the cutoff, by Ben Laurie (Capabilities Limited), working with Claude on a Rocq proof of isolation properties of the demo's compartment prologue over this model.  Peter Rugg and Jessica Clarke fixed both that day, and the commit above carries the fixes.

| Divergence                                                                                                                                                                                                                                                                                                                           | Fix                                        | Threat       |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------|--------------|
| A `JALR` with a non-zero immediate to a sentry left the tag set and could change the address, so a sealed capability was modified, and a trap return to it would unseal it.  The 2026-10-06 fix had left this case.  Capabilities Limited reports that CVA6-CHERI had the same behaviour, having matched the model in tandem testing | `05b24fa`                                  | TM-003 (RP5) |
| `CBO.ZERO`, which writes a whole cache block, zeroed the data but did not clear every tag it covered, leaving tagged null capabilities that no valid capability derived, a provenance violation                                                                                                                                      | `84515a8`, with the hardening in `77e0312` | TM-049 (RP4) |

Neither finding is Sigil Logic's; both are Capabilities Limited's, and they are recorded here because they change the model under audit.  They are also the first evidence that the proof work this project rests on finds model errors before a red team does.

## How to report

See [`../../../SECURITY.md`](../../../SECURITY.md) and [`../findings.md`](../findings.md).  Cite this release's commit hash.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
