# AIVHAI: Sprint 1 ISA Issues Identified

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#255](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/255)  
**Source**: Capabilities Limited (Robert Watson), the AIVHAI team's write-up of 2026-10-11; register entry `Watson-26` in [`../../bibliography.md`](../../bibliography.md)  
**Method**: The bibliography's snapshot of the Google Doc as revised at 23:12 UTC on 2026-10-11, with the two passages its author marked *Not for public release* omitted, and their places marked; the comment threads are omitted.  Wording otherwise unedited  

---

Capabilities Limited's account of the two divergences of the RVY Sail model from the RVY specification found on 2026-10-11, and of their fixes, which the Sprint 1 model pin carries.  It is included in the red-team release as an illustration of the defects most wanted ([`../../../REDTEAM.md`](../../../REDTEAM.md) §4).  At its author's request, two passages about the likely effect on silicon are omitted from this copy.

---

11 October 2026

These issues with the RVY Sail model associated with the draft RVY specification were discovered during work by Ben Laurie @ CapLtd working with Claude (Opus 5.5) to develop a Rocq proof of isolation properties in the bare-metal 'prologue' compartmentalisation code developed by Hesham Almatary @ CapLtd.  The RVY Sail model bugs were triaged and fixed by Peter Rugg @ CapLtd and Jessica Clarke @ CapLtd.  **These are preliminary research results from a work-in-progress project, and require further validation before the Sail patches are merged into the RISC-V International repository.  Our current analysis is neither comprehensive nor complete.**

Bugs in the Sail formal model are important for several reasons including that (a) In the future, it is likely that the RVY specification will be derived directly from the model; (b) the Sail model is used as a golden model performing tandem verification of hardware designs, leading to bugs in the Sail model having high probability of being not only missed in a hardware design, but actually being added to one, and (c) that proofs against the model will not correspond to the intended design.

## Issue 1: Incorrect checks in JALR

As part of productisation of CHERI-RISC-V, a number of changes have been made to the instruction-set specification to improve the performance of hardware implementations.  An essential goal for these optimisations is to maintain CHERI's security properties.

This issue relates to a proposed optimisation that changed how security violations are handled, and was the result of experiences with hardware implementation work at two different hardware vendors.  In the research ISA, capability checks on jump-and-link-register (JALR) instructions would be performed within that instruction, and lead to an immediate architectural exception (trap) being thrown in the event of a security check failure.  The proposed ISA optimisation retained the checks in the JALR instruction, but shifted exception throwing to later instruction fetch.  This was achieved by clearing the target capability tag on a violation, causing a tag violation to take place on fetch.  This change enables a more efficient critical path in the jump implementation, while maintaining the security invariant that execution cannot proceed across a protection-boundary if a security check had failed.

This proposed change was specified correctly in the human readable specification, but was incorrectly translated into the Sail model, instead permitting the tag to sometimes be maintained despite prohibited changes to the target address.  Such changes would enable control-flow attacks across protection-domain boundaries -- a critical security vulnerability.  This bug was picked up during manual code review, but was incorrectly fixed, which continued to allow prohibited control-flow transfers.

We found the bug as a result of our AIVHAI effort -- in particular, a target invariant for preserving control-flow security properties on protection-domain transition could be violated, which was raised by Claude when driving Rocq verification of compartmentalisation firmware in the context of the draft RVY Sail model.  The vulnerability was independently validated by two CapLtd staff members.  We have developed a fix that is now awaiting code review before being merged into the upstream model.

The Sail model is used for tandem verification of hardware implementations, acting as the gold model of correctness.  We discovered that the CVA6-CHERI processor contained the same incorrect implementation, which had been overlooked because it complied with the ISA formal model during randomised testing.

*[A passage is omitted here at its author's request.]*

**RVY Sail model fix**:

- <https://github.com/Capabilities-Limited/sail-cheri-riscv/commit/05b24fa16d006a3528fbe40100ce68e15701bfb3>

## Issue 2: Missing tag clearing in CBO.ZERO

As part of the merging of more recent instruction extensions from upstream RISC-V, support for an efficient memory zeroing instruction was merged.  These operate at cache-line granularity, and were correctly specified during the merge to RVY as also clearing tags and not just in-line data.

Earlier Sail models from which the RVY model is derived made an assumption as to the maximum write size that could be seen.  There were no code assertions to enforce this constraint, only a comment documenting it, and this was not fixed when combining with a new RISC-V model that did support the cache-line zeroing instruction.  Memory contents were still forced to zero but this would allow the creation of unexpectedly tagged "null capabilities" that, while not representing any architectural rights (due to having no permissions), violate the underlying invariant that all capabilities have appropriate provenancy validity in being derived from a valid prior capability.  In principle, these tagged null values, which are unsealed and have bounds covering the entire address space, could have been used by software to connote software-defined notions of privilege, although we are unaware of any software using that technique.

We found the bug as a result of our AIVHAI effort -- in particular, a target invariant for preserving control-flow security properties on protection-domain transition could be violated, which was raised by Claude when driving Rocq verification of compartmentalisation firmware in the context of the draft RVY Sail model.  The vulnerability was independently validated by two CapLtd staff members.  We have developed a fix that is now awaiting code review before being merged into the upstream model.

*[A passage is omitted here at its author's request.]*

**RVY Sail model fixes**:

- <https://github.com/Capabilities-Limited/sail-cheri-riscv/commit/84515a85ead058eb2cc8bffb45496979f2dbdd7c>
- <https://github.com/Capabilities-Limited/sail-cheri-riscv/commit/77e03123889f931c7e1d7d7468f905ab2ba44e2c>

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
