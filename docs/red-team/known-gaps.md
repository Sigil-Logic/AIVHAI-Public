# Known Gaps

**Status**: Living document  
**Version**: 0.4.2  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

What we know is missing, unproved, or in doubt, stated before anyone has to find it.  Every release carries this list as it stands on the release date.  A gap leaves this list only when what closes it has been released.

## Coverage of the system

**Only executable formal models exist yet.**  For roughly the first twelve months the project's artifacts are models and proofs about them; there is no hardware to attack until remote FPGA access, planned for around month 14.  Every claim in this repository is therefore about a model, and a model can differ from the hardware later built to it.

**The NPU's memory path is not a DMA path, and that is the point.**  An earlier internal framing said the accelerator would talk to the core over DMA, deferred to later sprints, and that this would be the red team's obvious target.  That was wrong, and Capabilities Limited corrected it (Robert Watson, 2026-10-09).  In AIVHAI the accelerator is part of the RISC-V core: it shares the core's instruction decode and memory subsystem.  It is designed so that, when complete, its memory accesses are constrained by the same MMU, PMP, and CHERI checks as every other access by the core.  The design's defining aim is that the security model holds end to end through vector acceleration, instead of being dropped at a DMA interface.  That is a design intent, not a result: that every vector and matrix access actually passes through those checks is goal G-c4 of the project case, undeveloped, because neither datapath exists yet.  If the red team finds a way for the accelerator to reach memory around those checks, that is exactly the defect the project exists to prevent.

**DMA by other devices is real, and it is not yet modelled.**  Peripherals such as networking may use DMA, which would be mediated by an IOPMP and an IOMMU.  The maturity of those components has not been assessed.  Capabilities Limited suspects the IOPMP is of prototype quality, and the compartmentalisation firmware will depend on it for its own protection.  No model or proof here covers either component yet.

**The threat model is a first draft, in one form.**  [`../../specs/assurance/threat-model.md`](../../specs/assurance/threat-model.md) is released as a flat hyperlinked document; the self-contained interactive form is not yet made.  Its known gaps are threats the project has not decided how to answer, each with an owner, and they are gaps of this release too:

- GAP-1, shared compartments and preemption;
- GAP-2, requester-ID integrity at the IOPMP, which the specification leaves implementation-defined;
- GAP-3, whether the firmware or the general-purpose OS owns the IOMMU tables;
- GAP-4, runtime delegation of authority beyond data-only I/O buffers;
- GAP-5, the vector and matrix specification is not frozen;
- GAP-6, where the SystemVerilog and Guru refinement chains meet;
- GAP-7, whether a measured or authenticated boot is in scope;
- GAP-8, concurrency, since the Sprint 1 target is sequential;
- GAP-9, compartment destruction and reuse.

**The project-level assurance case is a skeleton.**  [`../../specs/assurance/aivhai-case.md`](../../specs/assurance/aivhai-case.md) states the proof series as goals, grounded in the threat model, and every leaf goal is undeveloped with the reason.  It establishes no AIVHAI result.  The record of prior work it is read against shows that several of its goals have no precedent at all: sequence-level monotonicity for a RISC-V CHERI ISA, any mechanised result for a capability-aware vector unit, refinement for an application-class CHERI core with caches and an MMU, and any theorem about tenant state across context switches.

## Sprint 1 specifics

**The Sail model is assumed to follow the RVY specification.**  Every Sail-side property rests on it.  It is what Trail of Bits is auditing in Sprint 1, and divergences will be treated as findings.  Two were found on 2026-10-11, the day before the cutoff, by Capabilities Limited's Rocq proof of the demo's prologue: a sentry kept its tag through a `JALR` with a non-zero immediate, and `CBO.ZERO` left tags set.  Both were fixed that day, and the model pin moved to the one commit that carries both fixes, on a different branch from the one named on 2026-10-08.  The fixes still await Capabilities Limited's upstream review (see the hand-off).  That one proof attempt found two in one day is reason to expect more.

**The Sail toolchain version differs from the model's owner's.**  Capabilities Limited validates the model with Sail 0.18; the AIVHAI images carry Sail 0.20.2.  Whether the two produce the same result for this model is being measured and has not been established.

**The Sprint 1 monotonicity proof over the Sail model does not exist yet.**  Its plan is the second assurance case ([`assurance-case/rvy-sail-monotonicity.case.md`](assurance-case/rvy-sail-monotonicity.case.md)), in which nothing is proved and every leaf goal is undeveloped.  The five informal properties RP1 to RP5 in the hand-off are statements of intent.  RP1 is the sequence-level target, and the plan decomposes it through RP2 to RP5; none of them is proved.  The crux, that the bounds-setting instruction never widens bounds under the RVY encoding, is unproved.

**The CHERIoT theorem holds only on same-domain traces.**  `ThreadIsolatedMonotonicity` says nothing about any state after a compartment call, compartment return, or exception, because its property is conditional on the whole trace being same-domain.  The switcher's contracts are specified but not proved.  See [`assurance-case/cheriot-thread-isolated-monotonicity.case.md`](assurance-case/cheriot-thread-isolated-monotonicity.case.md).

**The CHERIoT theorem's instruction hypothesis was mis-stated at the pin, and is corrected in the hand-off commit.**  The specification's author noted that `FuncNormal` applied the instruction to the same memory twice where a different memory was intended (Spec.v, lines 508-509 at `f754796`), and fixed it upstream; the hand-off commit carries that one-line fix, the proof script is otherwise unchanged apart from comments, and the theorem checks against it.  Defeater D1 in the case is rebutted on that evidence.  Whether the hypothesis as now stated is satisfiable by any instruction is not shown; that is the case's open defeater D2, and if no instruction satisfies it the theorem is vacuous.

**The CHERIoT theorem assumes, rather than proves, per-instruction monotonicity.**  Each instruction carries a proof obligation that it does not grow reachable capabilities.  No instruction set's instructions have been shown to meet it within this development.

**What a source search cannot show.**  Kernel acceptance of the CHERIoT theorem is evidenced only by the recorded build log (case evidence E3), and axiom-freedom only by the recorded `Print Assumptions` output (E2).  A text search, which finds no `Admitted`, `Axiom`, `Parameter`, or `Hypothesis` outside sections in the five source files, is not evidence of either, and axioms from imported libraries are not examined by it.  Both are recorded for this release under `.evidence/cheriot-abstract-spec/`, against the hand-off commit.

**The CHERIoT theorem is parametric.**  It holds for every choice of capability encoding, fetch function, and decoder, and claims nothing about any particular one.  Two parts of the specification that bear on whether its hypotheses can be satisfied are marked unfinished in the sources (Properties.v lines 457 and 577).

**CHERIoT is not the AIVHAI target, and not an evaluation target.**  CHERIoT is a 32-bit embedded CHERI design; AIVHAI's core is a 64-bit application core.  The CHERIoT material is included for pedagogy, and the gaps above about it are stated because a worked example should show its open doubts, not because we ask the red team to settle them.  The CHERIoT theorem is offered as the first showing of what a hand-off contains, and as the basis that the 64-bit isolation model will extend.  It is not evidence about AIVHAI's hardware.  Its programming model is CHERIoT RTOS's, as the specification's author points out: compartments with export tables, a switcher with trusted stacks, sealed sentries, and threads laid out by a configuration.  `IsolatedThreads` is stated in those terms, so thread isolation as proved there does not transfer to RVY.  What transfers without change is the shape of the argument, per-instruction capability monotonicity lifted to whole executions by an inductive invariant; the RVY properties RP1 to RP5 are stated separately for that reason.

## Process

**The equivalent of FETT's injection path is defined for Sprint 1 only.**  In earlier red-team exercises over finished hardware, the red team was given a direct way to inject malicious software and told where the secrets and critical software were.  Over executable models, twelve months before hardware, the equivalent could be:

- a compartment the red team may populate with hostile code;
- a capability they may try to forge;
- a proof obligation they may try to falsify.

For Sprint 1, Capabilities Limited's compartment demo provides the first two: a compartment the red team populates with its own code, and named assets outside it, among them an unbounded capability left in memory, to read, modify or obtain authority over ([`../../REDTEAM.md`](../../REDTEAM.md) §4).  It is one compartment on a bare-metal image, with no I/O buffers, no privilege modes below M-mode, no MMU and no vector unit, so it exercises the boundary and the ISA, not the firmware to come.  How the path grows with the architecture, and what form the third takes, will be designed with the red team.

**Releases are cut by hand.**  Sigil Logic's policy is that every commit is signed, and no automation yet holds a signing key, so a person cuts each release and CI rehearses it weekly; see [`disclosure.md`](disclosure.md).  The organization rule that would make the platform enforce signing was found disabled on 2026-10-09, so the release script checks the signatures itself.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
