# Red-Team Findings: Intake, Triage, and Closure

**Status**: Living document  
**Version**: 0.1.0  
**Date**: 2026-10-09  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

This document says what happens to a finding from the red team, from the moment it is reported until it is closed.  How to report one is in [`../../SECURITY.md`](../../SECURITY.md).

## What counts as a finding

Anything that, if true, should change what we claim or what we build:

- A **divergence** between a model and the specification it claims to follow.  An undocumented divergence is a finding even when the model is arguably the better reading, because the model is meant to become the specification.
- An **error in a model**: behavior the model's authors did not intend.  The JALR fix in the Sprint 1 Sail model, *"JALR must not unseal target cap on non-zero imm"*, is the canonical example of the kind of error we want found.
- A **flaw in an argument**: a proof whose statement does not say what its prose claims, an assumption that is unsound or unsatisfiable, or an assurance case whose evidence does not support its goal.
- A **reproduction failure**: a proof that does not re-run, or evidence that cannot be re-derived, in the published images.
- A **scope gap**: something an attacker can reach that the claims do not cover and the known-gaps list does not mention.

**Findings as branches.**  The red team has write access to `Sigil-Logic/AIVHAI-Everything`, the repository that pins every upstream by commit.  A finding that is best expressed as a change is welcome as a branch there: a proposed re-pin, a fork commit with a fix, or a test case.  Name the branch `redteam/<short-description>` and report it by the route in `SECURITY.md` as for any other finding.  We review it as a pull request and never merge it unreviewed; its commits are cited by hash, like everything else.

## The path of a finding

| Step           | Who                         | What happens                                                                                                                                      | Within         |
|----------------|-----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| 1. Report      | Red team                    | By the route in `SECURITY.md`, naming the **release commit hash**, the artifact, and the line where possible                                      | —              |
| 2. Acknowledge | Release manager             | Reply on the channel it arrived on; file it in Sigil Logic's tracker with the red-team finding template                                           | 2 working days |
| 3. Triage      | PI and the artifact's owner | Classify (below), assign, set severity, and tell the reporter the classification                                                                  | 5 working days |
| 4. Resolve     | The artifact's owner        | Fix the model, the proof, or the claim; or record why it stands (below)                                                                           | Set at triage  |
| 5. Disclose    | Release manager             | The next weekly release carries the resolution, and the finding's entry in the hand-off note's *findings* section states it                       | Next release   |
| 6. Close       | PI                          | Closed only when the reporter has seen the resolution; a finding we dispute is closed as *disputed*, with both positions recorded, not as *fixed* | —              |

A finding against an upstream project, such as Capabilities Limited's Sail model, is taken to that project's owners person to person first, and only then, with the PI's approval, by the route the project uses.  We do not carry an unagreed fix to someone else's model, even in our own images.  The finding stays open with us until the agreed fix is in a pinned commit.

## Classification

| Class                  | Meaning                                                               | Typical resolution                                                                        |
|------------------------|-----------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| **Model error**        | The model does not do what its authors intend                         | Agree the fix with the model's owner; re-pin to it; re-run every proof over the model     |
| **Divergence**         | The model and the specification disagree                              | Document it, then decide which one moves; a security-relevant divergence is high severity |
| **Argument flaw**      | A claim is not supported by what was proved                           | Narrow the claim, or repair the proof — see the next section                              |
| **Proof-invalidating** | A proved theorem's statement or assumption is shown wrong             | See the next section                                                                      |
| **Reproduction**       | Evidence does not re-derive in the published images                   | Fix the image or the instructions; the evidence does not count until it re-derives        |
| **Scope gap**          | Reachable behavior that no claim covers and no gap statement mentions | Add it to the known gaps now; plan its coverage                                           |
| **Not a defect**       | Working as stated                                                     | Explain, and improve the documentation that allowed the misreading                        |

## When a finding invalidates a proof

This is the expensive case, and it has a fixed procedure, so that nobody improvises it under pressure.

1. **Withdraw the claim at once.**  In the next release, the assurance case gains an open defeater against the affected goal, and the hand-off note says the claim is withdrawn pending repair.  The proof is not deleted.  Its statement and history remain, because a red team needs to see what was wrong.
2. **Find every dependent claim.**  Walk the assurance cases for every goal supported, directly or through other goals, by the invalidated one.  Each gets the same defeater.
3. **Classify the cause.**  Is the theorem's statement wrong (it says the wrong thing)?  Is an assumption wrong (it is false, or unsatisfiable, which makes the theorem vacuous)?  Is the model wrong (the theorem is right about the wrong model)?  Or is the toolchain wrong (the proof checker accepted a non-proof)?  Each has a different repair, and the last is the most serious.
4. **Repair, then re-run everything that depends on it** inside the published images, and record the new evidence.
5. **Close the defeater as rebutted**, with the repair's commit hash, and keep it in the case's *Resolved defeaters* section permanently.

The same procedure applies when we find the problem ourselves.  The CHERIoT case's defeater D1 is an example: the specification's author raised it, it was disclosed as open while it was, and it is closed as rebutted with the fix's commit and the re-run evidence, where it stays in the case's *Resolved defeaters* section; the half of the doubt the fix does not answer, whether the corrected hypothesis is satisfiable at all, was not closed with it but carried forward as the open defeater D2.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
