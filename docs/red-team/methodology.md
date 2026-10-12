# How the Specifications, Proofs, and Assurance Cases Are Produced

**Status**: Living document  
**Version**: 0.2.1  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

This document is for a reader outside the project, first of all the red team.  It explains how Sigil Logic's artifacts are made, so that a reader can judge an assurance case knowing where each part of it came from.  It does not explain CHERI, RISC-V, or Sail; the project's bibliography ([`../bibliography.md`](../bibliography.md)) lists the sources for those.

## What we claim, and what we do not

The project's security claim is **structural non-bypass**.  Every effect a tenant can have on the machine (a memory access, a transfer, an output) passes through a capability check that the tenant cannot avoid, so a tenant can reach only what it was explicitly given.  This is a claim about the *machine*: about which paths exist.

It is **not** a claim of *semantic benignity*, that a model or agent running on the machine behaves well, reasons correctly, or is harmless.  A malicious model confined correctly is still malicious; the claim is only that it is confined.

Three further things are outside the formal claims and are stated as such wherever they matter:

- **Availability.**  Isolation as proved here is a safety property: nothing reaches what it should not.  It is not resource partitioning; a tenant starving another of time or bandwidth is a separate and harder claim, and is never folded into "isolation".
- **Microarchitectural side channels**, such as timing and cache effects.  CHERI does not defeat these by itself, and the proofs model architectural state, not timing.
- **Invasive physical attack.**

When a document here appears to claim more than this, that is a defect in the document; please report it.

## The refinement chain

The method Sigil Logic uses is called NINJA.  Its central idea is that every artifact should be traceable both to what it refines and to what refines it, so that nothing is translated by hand between stages without a record.  For AIVHAI the chain runs:

| Level          | What it is                                                                                       | Example                                                                       |
|----------------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| Commitment     | What the project promised its funder                                                             | "Prove capability monotonicity for the RVY ISA"                               |
| Sprint target  | The part of a commitment scheduled for an 8-week sprint                                          | Sprint 1: sentry-less instruction-sequence monotonicity over the Sail model   |
| Specification  | The authoritative description of correct behavior                                                | The RVY specification (`riscv-cheri`), and the CHERIoT abstract specification |
| Model          | An executable formal model of the specification                                                  | Capabilities Limited's Sail model of RVY                                      |
| Property       | A precise statement about the model                                                              | A Rocq theorem                                                                |
| Proof          | A machine-checked derivation of the property                                                     | The Rocq proof script                                                         |
| Evidence       | The record that the proof checks, from pinned inputs, in a pinned toolchain                      | A build log, `Print Assumptions` output                                       |
| Assurance case | The argument from the evidence back up to the commitment, with every assumption and doubt listed | [`assurance-case/`](assurance-case/)                                          |

Two adjacent levels are related in one of a few ways: one **refines** the other (adds detail without changing meaning), one **satisfies** the other (a model satisfies a specification), or one **verifies** the other (a proof verifies a property).  Where the relation between two levels is assumed rather than established, the assurance case says so as an assumption.  The most important example in Sprint 1 is that the Sail model is assumed to follow the RVY specification.  That assumption is exactly what Trail of Bits is auditing.

## How a result is pinned

A claim such as *"we proved capability monotonicity"* is meaningless until it says over which commit of which model, built with which commit of which tool.  Three things pin every result we publish:

1. **The upstream corpus.**  `Sigil-Logic/AIVHAI-Everything` holds every upstream repository a claim depends on as a git submodule at an exact commit: the models, the specifications, the compilers, the proof libraries.  It is private, and the red team has access to it.  Each release also copies its full pin list into `RELEASE.json`, so that a release can be checked by anyone without that access.
2. **The toolchain images.**  Every proof is built and checked in a container image named by digest, not by tag.  Where we had to modify a tool, the image's Dockerfile carries the modification and says why.  The image definitions are published with each release, under `infra/containers/`.
3. **The release manifest.**  `RELEASE.json` at the root of each release records both of the above, the commits of the evaluation targets, and the SHA-256 of every published file.

## How a proof becomes evidence

A proof counts as evidence only when it has been **re-run from the pinned inputs inside the pinned image**, and the command that does so is written down beside it.  Each evidence node in an assurance case carries a `rerun` field holding that command.  The intent is that the red team can replay every proof and regenerate every piece of evidence without asking us anything.  `scripts/release/replay-evidence.py run` (or `make replay RELEASE=RELEASE.json`) runs every such command, each in a fresh checkout of the commit it names, and records the outcome.  If a `rerun` command does not work, that is a finding.

Every proof states what it assumes.  In Rocq that means its hypotheses and any axioms, and we record the output of `Print Assumptions` for each theorem we claim; the release check refuses a case whose evidence is still pending, so no theorem is offered without that record.  An unproved lemma left in a development (`Admitted`, or its equivalent in another prover) is treated as a contract violation and is never allowed to land silently.  If one remains, the assurance case lists it.

## How an assurance case is built

The project as a whole has one structured assurance case, [`../../specs/assurance/aivhai-case.md`](../../specs/assurance/aivhai-case.md), stated against its threat model, [`../../specs/assurance/threat-model.md`](../../specs/assurance/threat-model.md): every threat names the goal of the case that is to counter it, or the assumption, exclusion or known gap that answers it, and a script checks the two documents against each other.  Each claim offered to the red team also has a case of its own in [`assurance-case/`](assurance-case/), attached to the project case at the goal it bears on.  The format, explained in the [README there](assurance-case/README.md), is Goal Structuring Notation (GSN), a widely used notation for safety and security cases.  It is written as JSON so that a script can check it, and rendered to Markdown so that it can be read without any tool.

Three features of the format matter more than the rest:

- **Scope comes first.**  Each case opens with what it covers and, at greater length, what it does not.  A case that excludes nothing has not stated its scope, and the checker rejects it.
- **Assumptions are listed and tracked**: each is *open*, *discharged* (and by what), or *accepted* (and why).
- **Defeaters are part of the case.**  A defeater is a known reason to doubt the argument: a suspected error, an unresolved question, a negative result.  An open defeater is shown before the argument, not after it.  We do not remove a defeater because it is unflattering.

## Assurance is broad-spectrum

The programme asks for assurance cases grounded in formal verification, and machine-checked proofs are this project's deliverable.  Applied formal methods is broader than proof, though.  It runs from executable specifications and model-based testing, through runtime verification, to model checking and automatic and interactive theorem proving, and the project intends to use all of it on this SoC.

Each property is refined from a requirement to a design, and codified there in whatever form that level admits: contracts, inline assertions, test benches, verification benches.  It is then checked both dynamically, by executing models, RTL and firmware, and statically, by proof.  A test is reported as validation over the cases it runs, and a proof as verification under the assumptions it states.  [`../../specs/assurance/README.md`](../../specs/assurance/README.md) says how this applies to each layer of AIVHAI, and where the practice comes from.

## How AI assistance is used

Sigil Logic uses AI agents (its HOARDE system) to assist the work: drafting documentation, mining specifications for properties, searching for proofs, and keeping traceability and project records consistent.  Two rules bound that use.

- **A proof is checked by its proof assistant, not by an agent.**  Whether an agent or a person wrote a proof script makes no difference to whether Rocq accepts it; what we publish as evidence is the checker's verdict, re-runnable by anyone.
- **Every claim is reviewed by a person** before it is released.  The review asks what exactly was proved, under what assumptions, and whether the prose overstates it.  An agent may draft a hand-off note; a person signs it off.

## How work is organised

The project runs in 8-week sprints set by the funder: six weeks of building and verifying, one week of red-teaming, and one week of review and retargeting.  Sigil Logic releases to the red team weekly; [`schedule.md`](schedule.md) gives the cadence and the dates, and [`disclosure.md`](disclosure.md) says what each release contains and what is kept out.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
