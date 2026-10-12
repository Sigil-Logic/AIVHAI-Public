# Security Policy

**Status**: Living document  
**Version**: 0.1.0  
**Date**: 2026-10-09  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

AIVHAI is building and formally verifying a capability-mediated edge AI accelerator: the CVA6-CHERI application core with an integrated, capability-aware Coral NPU, and CHERI compartmentalisation firmware.  This repository holds Sigil Logic's part of that work: formal models, specifications, proofs, assurance cases, and the toolchain that checks them.

## What is in scope

- **Formal models and specifications** published here or pinned by a release, including divergences between a model and the specification it follows.
- **Proofs and assurance cases**: a theorem whose statement does not mean what its documentation says, an assumption that is false or unsatisfiable, or evidence that does not support the claim it is attached to.
- **Reproducibility**: a proof or evidence artifact that does not re-run in the published container images.
- **The toolchain images**, where a defect could make a checker accept what it should reject.
- **This repository's release process**, if it could publish something it should not.

## What is out of scope

- Hardware and firmware implementations owned by other consortium members, unless the finding is about a model or proof published here.  Report those to the owning project; we will help route a report if asked.
- Microarchitectural side channels and invasive physical attacks.  The project's claims are structural, and these are outside the formal boundary by design; see [`docs/red-team/known-gaps.md`](docs/red-team/known-gaps.md).
- The security of third-party tools as such (Rocq, Sail, solvers), except where a defect affects a result published here.

## How to report

**The red team (Trail of Bits)** reports through the channels agreed for the engagement: the shared `#aria-aivhai-redteam` channel on the CHERI-CPU Slack for discussion, and e-mail to the Sigil Logic PI for anything with a deadline or an escalation.  Name the **release commit hash**, not a tag, and the artifact.

**Anyone else** should report privately, not in a public issue, through GitHub's private vulnerability reporting on the `Sigil-Logic/AIVHAI-Public` repository (the *Security* tab, then *Report a vulnerability*).  Please include the commit hash, the artifact, what you expected, and what you found.

We acknowledge a report within two working days and say how it was classified within five.  What happens next is described in [`docs/red-team/findings.md`](docs/red-team/findings.md), including what happens when a report invalidates a proof.

## Disclosure

This is a research program whose outputs are published openly.  We disclose findings and their resolutions in the release that carries the fix, and credit the reporter unless they ask otherwise.  We do not ask reporters to keep a finding confidential beyond the time needed to tell any affected upstream project.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
