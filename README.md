# AIVHAI-Public

**Status**: Living document  
**Version**: 0.2.1  
**Date**: 2026-10-11  
**Project**: AIVHAI  

---

This repository is Sigil Logic's public release channel for **AIVHAI** (AI Verified Hardware for AI), an ARIA Safeguarded AI project led by Capabilities Limited with lowRISC, Sigil Logic, Cherified Systems, and Google Research.  AIVHAI is building and formally verifying a capability-mediated edge AI accelerator: the CVA6-CHERI application core with an integrated, capability-aware Coral NPU, governed by CHERI compartmentalisation firmware.  Sigil Logic's part is the formal modelling, the proofs, and the assurance case.

## What this repository is

Each commit here is **one release**: a filtered copy of one commit of Sigil Logic's private working repository.  Nothing is developed here, and the history is the history of releases, not of the work.

- **[`RELEASE.json`](RELEASE.json)** says which private commit a release came from, the full list of upstream repositories the claims are made over with the commit of each (copied from Sigil Logic's pin repository, `AIVHAI-Everything`, so that every release is self-contained), the container image digests that reproduce the toolchain, any evaluation targets, and the SHA-256 of every file.
- **[`REDTEAM.md`](REDTEAM.md)** is where to start: what each release offers for evaluation, and how the threat model, the assurance case, the record of prior work and the targets fit together.
- **[`docs/red-team/`](docs/red-team/)** holds the red-team package: each sprint's hand-off note, the known gaps, the methodology, the worked assurance cases, the schedule, and the disclosure process.
- **[`specs/assurance/`](specs/assurance/)** holds the threat model, the project-level assurance case, and the census of prior work.
- **[`SECURITY.md`](SECURITY.md)** says how to report a problem.

**About the links.**  Many documents here link to issues and pull requests in `Sigil-Logic/AIVHAI-Sigil`, Sigil Logic's private development repository, from which each release is exported.  We keep those links so that every statement traces to the record behind it.  They will not open for you today; access to that repository may be granted in a later sprint.  If a claim depends on something behind a link you cannot follow, that is a gap in the release, and we would like to hear about it.

**Cite commit hashes, not tags.**  Releases are tagged `release/<name>` for convenience, but tags are mutable and hashes are not.

## What it is not

This is not where the project's hardware, firmware, or upstream models live.  Those are in their owners' repositories, and the releases here pin them by commit.  Releases are made weekly while a sprint is building, and the release at the start of each red-team week is the one offered for evaluation; see [`docs/red-team/schedule.md`](docs/red-team/schedule.md).

## Licence

Sigil Logic's own material here is released under CC-BY-4.0 (documents and assurance cases) and the BSD 2-Clause License (scripts and Dockerfiles); see [`LICENSE`](LICENSE).  Third-party documents under `docs/bib/` are included only where their own licences permit redistribution, and each keeps its own licence, recorded in [`docs/bibliography.md`](docs/bibliography.md).

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
