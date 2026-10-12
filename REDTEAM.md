# AIVHAI for the Red Team: a Roadmap of the Release

**Status**: Living document  
**Version**: 0.4.4  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53), [#210](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/210)  

---

This file is the map of Sigil Logic's release to the AIVHAI red team, Trail of Bits, engaged by ARIA.  It says what we ask you to evaluate, what else the release carries and why, how the pieces fit together, and where to start reading.  It is rewritten with every release; this version accompanies the **Sprint 1 hand-off, for the red-team week beginning Monday 2026-10-12**.

**This sprint is a practice run.**  The consortium is four weeks into the contract.  It is warming up its development and assurance pipeline and its strategy, and bringing the whole team onto the technologies and the methodology.  The hand-off is offered in that spirit.  **Nothing about AIVHAI's own hardware or firmware is proved yet**, and the documents say so wherever it matters.

**What we ask.**  In the very short term the consortium is beating the RVY instruction-set specification into shape.  Please take the two evaluation artifacts in §3, with their documentation, and tell us what we have done wrong.  Above all, we want any defect that could lead to security harm, whether a defect against the specification or against what the specification is meant to achieve, and especially one that motivates a change to the specification and the Sail model to fix it.  §4 shows, by example, the kind of defect we mean.

**About the links.**  Many documents here link to issues and pull requests in `Sigil-Logic/AIVHAI-Sigil`, Sigil Logic's private development repository, from which each release is exported.  We keep those links so that every statement traces to the record behind it.  They will not open for you today; access to that repository may be granted in a later sprint.  If a claim depends on something behind a link you cannot follow, that is a gap in the release, and we would like to hear about it.

## 1. What the project claims, and what it does not

The project's claim, which nothing here yet proves, is **structural non-bypass**: every memory effect of a tenant (an AI model, an agent, or the general-purpose OS) passes through a capability check it cannot avoid, so a tenant reaches only the memory it was explicitly given, and no tenant reaches the firmware's own state.  It is not a claim of **semantic benignity**, that any model or agent behaves well.  Availability, microarchitectural side channels and invasive physical attack are outside the formal claims.  [`docs/red-team/methodology.md`](docs/red-team/methodology.md) defines these terms for an outside reader; threat model §7 lists every exclusion with its justification.

For about the first twelve months every artifact is a model or a proof about a model.  There is no hardware to attack until remote FPGA access, planned for around month 14.

## 2. How the pieces fit

```
   upstream threat models                   prior work on CHERI and RISC-V
   (CHERIoT, Capabilities Limited's         (the property census, CAN-01 to CAN-18:
    model draft, Smepmp, IOPMP, ...)         what was stated, tested or proved, and where)
              |                                              |
              v                                              v
   THREAT MODEL  --- each threat's disposition --->  ASSURANCE CASE (GSN)
   TM-001..TM-050     names a goal, assumption,       G0: the platform claim
   ADV, AS, S         exclusion or known gap          G-a  ISA            (RVY Sail model)
   EXCL-1..8          <--- each goal's cited ----     G-c  microarchitecture (CVA6-CHERI)
   GAP-1..9                threats name it back       G-CF firmware        (the CF)
                                                      G-comp composition
                                                      A-1..A-6, D1..D3
                                                                |
                         every leaf is evidence, or undeveloped with the reason
                                                                |
             +----------------------------+---------------------+---------------------+
             |                            |                                           |
   RVY Sail plan (G-a1)       CHERIoT theorem (G-CF2)                   Capabilities Limited's
   a plan: nothing proved     a precedent, for pedagogy;               firmware (G-CF4, G-CF7, G-a1)
                              not an evaluation target                  attacked, not proved
```

- **The threat model** ([`specs/assurance/threat-model.md`](specs/assurance/threat-model.md)) is built from the threat models already published for the components AIVHAI reasons about, and §9 says, source by source, what it adopts and where it diverges.  It names eight assets, eight adversaries and eight attack surfaces, and fifty threats.  **It is a first draft**, written in week five, largely generated by Sigil Logic's HOARDE agents with light review, and not yet vetted in depth by the AIVHAI team, so read it, and tell us what is wrong with it, with that in mind.  Its form is open as well: we are considering organising it with the framework Free & Fair used for VoteSecure, codified and published both statically and as an interactive application, and we would value your view of whether that would help you ([`docs/red-team/prior-engagements.md`](docs/red-team/prior-engagements.md)).  Every threat ends in exactly the places its disposition column names: a goal of the case that is to counter it, an assumption, an exclusion (§7), or a known gap with an owner (§8).
- **The assurance case** ([`specs/assurance/aivhai-case.md`](specs/assurance/aivhai-case.md), from its JSON source) is a skeleton in Goal Structuring Notation.  **Like the threat model, it is a first draft**, written in week five, largely generated by HOARDE with light review, and not yet vetted in depth by the AIVHAI team; feedback is welcome with that in mind.  Its root is the proof series the project promised, decomposed by layer of the trusted computing base.  Every leaf goal is **undeveloped**, with the reason stated: it records obligations, not results.  A goal that discharges a requirement names it and the Table A sprint cell it comes from; a goal that is only part of a requirement says so.  Open defeaters, the known reasons to doubt the argument, are shown before the argument.
- **The two documents are checked against each other in both directions.**  Every threat's disposition names the most specific goal that is to counter it, and every threat a goal cites must name that goal in return.  `scripts/assurance/check-threat-model.py` enforces this in CI and in this release; threat model §10 lists its rules.
- **The record of prior work** ([`specs/assurance/property-provenance.md`](specs/assurance/property-provenance.md), with its row-level catalogue) is a census of what earlier CHERI and RISC-V work stated, tested or proved, condensed into eighteen canonical properties and mapped onto the case's goals.  The case carries it as one context node per layer.  It establishes precedent and obligation, never evidence: no CHERI ISA property has been proved over instruction sequences for a RISC-V CHERI ISA, and nothing has been proved about a capability-aware vector unit.
- **How every property is to be assured** is the subject of [`specs/assurance/README.md`](specs/assurance/README.md).  In the NINJA view, a property is refined from a requirement to a design.  There it is codified as contracts, inline assertions, test benches and verification benches, and it is checked both dynamically, by execution, and statically, by model checking and by automatic and interactive proof.  The programme's focus is on formally verified assurance cases, and the proofs are this project's deliverable, but the project means to bring the whole spectrum of applied formal methods to bear on this SoC, not only proof.
- **Precedents are attached, not counted.**  Murali Vijayaraghavan's CHERIoT mechanisations (the abstract specification in Rocq, the Guru-based `cheriot` core, and the program logic) are attached at the goals each bears on, as precedents for a method.  A result about a 32-bit design with no privilege hierarchy is not evidence about a 64-bit application core (threat model EXCL-8).

## 3. What we ask you to evaluate, and what else is here

**The two evaluation artifacts:**

| Artifact                                                                                                                                                                                         | Commit                                                                                                                                                                                  | What we ask                                                                                                                                                                                            | Where it sits                                                                                            |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| **The RVY Sail model**, Capabilities Limited's, with the most recent fixes, read against **the human-readable RVY draft specification**, which is written by hand and not derived from the model | `Capabilities-Limited/sail-cheri-riscv@84515a85ead058eb2cc8bffb45496979f2dbdd7c` (branch `0.9.9-undo-branch-restriction`); `riscv/riscv-cheri@2946806c10910c12c1b9dc6153e9b0d56ccd8ce6` | Any divergence of the model from the specification, or of either from the specification's intent, that could lead to security harm; one that would break one of the properties RP1 to RP5 matters most | Assumption A-1; goal G-a1 through RP1 to RP5; threats TM-001 to TM-003, TM-006, TM-049, TM-050           |
| **The bare-metal compartment firmware**, Hesham Almatary's, with its documentation (§5)                                                                                                          | `Capabilities-Limited/aivhai-fw-compartment@9691cf2e0c092f880f0aa57c7c3e70abf95b1b1e`                                                                                                   | Escape the compartment from code you supply, and any defect in the firmware or its documentation                                                                                                       | Goals G-CF4 and G-CF7, and G-a1 through the permissions the firmware leaves on; threats TM-013 to TM-016 |

**The model moved on the day of the hand-off.**  On 2026-10-11, Ben Laurie's Rocq proof of the firmware's prologue (Capabilities Limited, with Claude) found two divergences of the model from the RVY specification, and Peter Rugg and Jessica Clarke fixed both that day (§4).  No commit on `0.9.9-upgrade`, the branch named on 2026-10-08, carries all the fixes.  The model offered is therefore the tip of `0.9.9-undo-branch-restriction`, which is also the branch the firmware's build uses, so the audit and the firmware use one model.  The fixes still await Capabilities Limited's upstream review.

**Illustrative defect information.**  §4 gives the two defects found this week, both the changes themselves and Capabilities Limited's write-up of them [@Watson-26].  The write-up is in this release as [`docs/red-team/sprint-1/isa-issues-2026-10-11.md`](docs/red-team/sprint-1/isa-issues-2026-10-11.md), with two passages omitted at its author's request.

**The broader assurance corpus, for the longer-term vision.**  The release also carries what the project has built and gathered so far, to show where the work is going.  This material is **not** offered for evaluation this sprint:

- the project's threat model and its assurance-case skeleton (§2), with the census of prior assurance work they are read against;
- the formal work to date on compartmentalisation that the census draws on, notably the work of Peter Sewell's group and others on CHERI-MIPS and Morello, cited in the census and the bibliography;
- **the CHERIoT abstract specification, one of its Rocq theorems, and that theorem's assurance case.**  We include them for pedagogy: to show what a mechanised Rocq proof and a structured case around it look like, and to ask for your reflections on how such material is packaged and delivered.  **They are not red-team targets.**  CHERIoT is not AIVHAI's design, and nothing proved about it is evidence about AIVHAI.

The model is described in full, with the properties we intend to prove and how to build it, in [`docs/red-team/sprint-1/handoff.md`](docs/red-team/sprint-1/handoff.md).  The firmware is Capabilities Limited's, and its instructions and rules are Capabilities Limited's own hand-off; §5 says how Sigil Logic's threat model and case read it.  `RELEASE.json` names every artifact by its full commit; cite hashes, not tags.

## 4. The findings we most want: the model departing from the specification

The day before this hand-off, Capabilities Limited found two security-relevant divergences between the RVY Sail model and the RVY specification.  Ben Laurie, working with Claude on a Rocq proof of isolation properties of the compartment demo's prologue, found them.  Peter Rugg and Jessica Clarke fixed both the same day.  Capabilities Limited's write-up [@Watson-26], included in this release as [`docs/red-team/sprint-1/isa-issues-2026-10-11.md`](docs/red-team/sprint-1/isa-issues-2026-10-11.md), is the account of record.  Capabilities Limited describes these as preliminary research results from work in progress, to be validated further before the fixes are merged into the RISC-V International repository, and its analysis as neither comprehensive nor complete.  **They are the clearest example we have of the kind of finding we most want from this engagement**: a defect, against the specification or its intent, that could lead to security harm and that motivates a change to the specification and the model.  The `JALR` fix took two attempts, one from manual review and one from Ben Laurie's proof, and both are included:

- **A `JALR` to a sentry kept its tag while its address changed** (first attempt `716106581bb5`, from manual review; second `05b24fa`, from the proof).  The specification moved the failure of a jump's capability check from the jump to the next fetch, by clearing the target's tag.  The model sometimes left the tag set, permitting control flow across a protection-domain boundary.  The first attempt, on 2026-10-06, had been incomplete.  This divergence breaks RP5 and is threat TM-003.
- **`CBO.ZERO` left tags set on memory it zeroed** (fixes `84515a8` and `77e0312`).  Code inherited from earlier models assumed no single write covers more than two capabilities, and the cache-block zeroing instruction merged from upstream RISC-V breaks that assumption.  The result was tagged null capabilities that no valid capability derived, a provenance violation.  This divergence breaks RP4 and is threat TM-049.

**Why these matter more than their size.**  As the write-up puts it, the specification is likely to be derived from the model in future; the model is the golden reference in tandem verification of hardware, so a model bug can be copied into a core rather than caught in it, as CVA6-CHERI's jump was (threat TM-050); and a proof over a wrong model proves nothing about the intended design.  In the threat model these are TM-006 and assumption A-1, which the assurance case now records as having failed twice.

**Where we would look for more.**  Both came from the same places: a performance optimisation that moved a security check (deferred faults), an extension merged from upstream into code that carried an older assumption (write width), and an incomplete earlier fix.  The translation from CHERI-MIPS and Morello to RVY is a fourth source.  A divergence that would break one of RP1 to RP5 is the most valuable kind of finding; [`docs/red-team/sprint-1/handoff.md`](docs/red-team/sprint-1/handoff.md) states the five, and records both fixes under "Found before this hand-off".

## 5. The compartment firmware: the mini-CTF

Hesham Almatary's firmware (Capabilities Limited) is a bare-metal RVY image run on the Sail model.  Its trusted code, `fw_compartment.S`, bounds a program-counter capability to a 1 MiB-aligned compartment, removes the permission to access system registers, clears the default data capability, the integer registers and eight listed CSRs, and jumps into the compartment.  **You supply the compartment**, as a raw binary embedded at `compartment_enter`, and attack from inside it.  Capabilities Limited's instructions, which it gives the red team directly, define the attack scope; in summary:

- **The objective** is to escape RVY compartmentalisation and violate spatial memory safety: read, modify, or obtain capability authority over memory or capabilities outside the compartment.  The named assets are **`read_var`**, **`write_var`** and **`cheri_infinite_cap`**, an unbounded capability the bootstrap leaves in memory outside the compartment.
- **Out of scope**: changing `fw_compartment.S` or anything that runs before `compartment_enter` (your code may exercise the trap and return paths, but not change them); temporal memory safety; timing and side channels; availability.
- **Four build settings weaken the protections** one at a time: `BOUNDS`, `ASR`, `DDC` and `REGS_TEMP`.  Reaching an asset with one enabled is an expected demonstration; reaching one with none enabled is a finding.
- **Its author states four assumptions**: every permission except system-register access is left on the compartment's capability, so confinement rests on the architecture enforcing tags, bounds and monotonicity; floating-point, vector and counter state is not cleared, because the demo places nothing sensitive there; side channels are outside its threat model; and the compartment is padded so its bounds are representable, which still depends on its base and size.

**How the case reads a capture.**  The demo is attached to the case as context, not as evidence, and a capture becomes a defeater on the node it bears on (see [`docs/red-team/findings.md`](docs/red-team/findings.md)):

| What you achieve                                                                                                  | What it falsifies                                                                                                               | Threats                                |
|-------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| An asset reached with no weakening, through instruction behaviour: bounds widened, a seal removed, a tag forged   | The ISA's confinement as the Sail model implements it: G-a1 (RP1 to RP5), or A-1 where the model departs from the specification | TM-001, TM-002, TM-003, TM-006, TM-049 |
| An asset reached with no weakening, through the state the trampoline leaves: a register, a CSR, ambient authority | The boundary invariants at entry: G-CF4                                                                                         | TM-013 to TM-017                       |
| Information recovered from floating-point, vector or counter state                                                | Nothing in the demo, which assumes that state carries nothing; for the firmware to come, G-CF7                                  | TM-016, TM-031 to TM-033               |
| An asset reached with one weakening enabled                                                                       | Nothing: it shows the protection is load-bearing, which is the point of the setting                                             | TM-013 to TM-016                       |

A capture through bounds representability is the most interesting of these to us: whether a requested bound rounds to one within its source, under the RVY encoding, is RP2, and RP2 is the expected crux of the Sprint 1 proof.

**Why it matters beyond Sprint 1.**  In the DARPA FETT bug bounty, researchers were given a way to inject malicious software and told where the secrets were.  Over formal models, before hardware exists, the equivalent was an open question; for Sprint 1 the demo answers it with a compartment the red team populates and named assets to reach.

## 6. Where to start reading

| If you want to                                                          | Read, in order                                                                                                                                                                                    |
|-------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Get the whole picture in an hour                                        | This file, §4 first; [`handoff.md`](docs/red-team/sprint-1/handoff.md); [`known-gaps.md`](docs/red-team/known-gaps.md); threat model §1, §6 and §7; the case rendering's scope and open defeaters |
| Audit the Sail model                                                    | §4; hand-off Claim 1 (RP1 to RP5); the [RVY plan](docs/red-team/assurance-case/rvy-sail-monotonicity.case.md); threat model §6.1; case goals G-a to G-a3; census §4.1                             |
| Attack the compartment firmware                                         | §5 above and Capabilities Limited's instructions; threat model §1.2 and §6.3; case goals G-CF4 and G-CF7 and context C-CF4                                                                        |
| See what a Rocq proof and its case look like (pedagogy, not evaluation) | Hand-off Claim 2; the [CHERIoT case](docs/red-team/assurance-case/cheriot-thread-isolated-monotonicity.case.md) and its evidence under `.evidence/cheriot-abstract-spec/`; case context C-CF5     |
| See what later sprints must prove                                       | The case's undeveloped goals G-c1 to G-c5, G-CF1 to G-CF4, G-CF6, G-CF7 and G-comp, each with its reason; threat model §6.2 to §6.6 and §8; census §5.1                                           |
| Check that the documents hold together                                  | §8 below                                                                                                                                                                                          |

## 7. What is in this release

| Path                                                                 | What it is                                                                                                                 |
|----------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `REDTEAM.md`                                                         | This map                                                                                                                   |
| `RELEASE.json`                                                       | The private commit exported, every upstream pin, the container image digests, the targets, and every file's SHA-256        |
| `docs/red-team/`                                                     | The red-team package: the hand-off note, known gaps, methodology, disclosure, schedule, findings intake, prior engagements |
| `docs/red-team/assurance-case/`                                      | The two worked cases, the CHERIoT result (for pedagogy) and the RVY plan, and the case format                              |
| `specs/assurance/threat-model.md`                                    | The threat model                                                                                                           |
| `specs/assurance/aivhai-case.json`, `aivhai-case.md`                 | The project-level assurance case, and its rendering                                                                        |
| `specs/assurance/property-provenance.md`, `property-catalogue.jsonl` | The census of prior work, and the catalogue of rows it is built from                                                       |
| `docs/evidence-candidates.md`                                        | What the CHERIoT test suites and program logic could and could not support in the case                                     |
| `.evidence/cheriot-abstract-spec/`                                   | The recorded build log and `Print Assumptions` output for the CHERIoT theorem                                              |
| `infra/containers/`                                                  | The definitions of the toolchain images, which `RELEASE.json` pins by digest                                               |
| `scripts/release/`, `scripts/assurance/`                             | The case checker, the evidence replayer, and the threat-model cross-check                                                  |
| `docs/bibliography.md`, `docs/bib/`                                  | The sources cited, with the full texts we may republish                                                                    |
| `SECURITY.md`                                                        | How to report a problem                                                                                                    |

**Identifiers.**  `TM-`, `ADV-`, `AS-`, `S-`, `EXCL-` and `GAP-` are the threat model's; `G-`, `S-`, `C-`, `J-`, `A-` and `D-` are nodes of a case (each worked case numbers its own, so the CHERIoT case's D2 is the project case's D3); `RP1` to `RP5` are the hand-off's informal Sail properties; `CAN-` names a canonical property of the census.  Goals cite requirements as `AIVHAI-SYS-Rnn` and sprint commitments as Table A cells; the requirements specification is still a draft and is not in this release.

## 8. Checking it yourself

```bash
python3 scripts/release/check-assurance-case.py docs/red-team/assurance-case   # the worked cases
python3 scripts/release/check-assurance-case.py specs/assurance                # the project-level case
python3 scripts/assurance/check-threat-model.py                                # the threat model against the case
python3 scripts/release/replay-evidence.py list                               # every evidence node, and how to re-derive it
python3 scripts/release/replay-evidence.py run --release-json RELEASE.json    # re-derive them, in the pinned image (needs Docker, amd64)
```

The first two enforce the case format: a single root, every goal supported or undeveloped with a reason, every assumption and defeater with a status, evidence pinned to full commits, and a tripwire for absolute vocabulary such as *secure* or *guarantees*.  None of the three can tell whether prose matches the formal statement it cites; that is a reviewer's question, and a mismatch is a finding.  `run` takes the toolchain image's digest from this release; to run one evidence node's command by hand, set it the same way: `AIVHAI_PROVERS="$(jq -r '.pins.images["aivhai-provers"]' RELEASE.json)"`.

## 9. What is known to be missing

[`docs/red-team/known-gaps.md`](docs/red-team/known-gaps.md) is the full list, kept current with every release.  The gaps that most shape this hand-off:

- **No AIVHAI result is proved.**  The RVY monotonicity proof is a plan, RP1 to RP5 are statements of intent, and every leaf goal of the project case is undeveloped.
- **The CHERIoT theorem, included for pedagogy, may be vacuous.**  Its mis-stated hypothesis is corrected at the hand-off commit (defeater D1, rebutted), but no instruction is yet shown to satisfy the corrected hypothesis (D3, open).  We say so because a worked example should show its open doubts, not because we ask you to settle them.
- **The threat model's nine known gaps** (§8) are open, among them shared compartments and preemption, requester-ID integrity at the IOPMP, ownership of the IOMMU tables, runtime delegation of authority, and an unfrozen vector and matrix specification.
- **The Sail toolchain differs** from the model owner's: Capabilities Limited validates with Sail 0.18, the images carry Sail 0.20.2, and agreement on this model is still being measured.
- **The threat model is published in one form only.**  The interactive form that VoteSecure's practice calls for is not yet made.

## 10. Reporting, and what comes next

Report through [`SECURITY.md`](SECURITY.md); [`docs/red-team/findings.md`](docs/red-team/findings.md) says how a finding is classified and what happens to the claim it bears on, including the fixed procedure for a finding that invalidates a proof.  Cite the release commit and the target commit.

This first hand-off is a practice run, and we would value your view of the package itself as much as any finding: what was hard to find, to build, or to trust.  Releases follow a weekly cadence, every Friday while a sprint builds, with the release at the start of each red-team week the one offered for evaluation ([`docs/red-team/schedule.md`](docs/red-team/schedule.md)).  Each sprint adds an evaluation property, and this file, the threat model and the case are revised with it: an undeveloped goal becomes a supported one only with evidence a reader can re-derive.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
