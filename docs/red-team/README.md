# AIVHAI Red-Team Package

**Status**: Living document  
**Version**: 0.2.1  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

This directory is Sigil Logic's material for the AIVHAI red team, Trail of Bits, engaged by ARIA.  It is published in every release to `Sigil-Logic/AIVHAI-Public`.  Start with [`../../REDTEAM.md`](../../REDTEAM.md) at the root of the release, which maps this directory, the threat model, the project-level assurance case and the evaluation targets onto one another.

## Reading order

1. **The current hand-off**: [`sprint-1/handoff.md`](sprint-1/handoff.md).  It covers what is offered for evaluation, the exact claims and their scope, and how to build.
2. **[`known-gaps.md`](known-gaps.md)**: what we know is missing or in doubt.
3. **The threat model**, [`../../specs/assurance/threat-model.md`](../../specs/assurance/threat-model.md): who attacks what, through which interface, and which goal, assumption, exclusion or known gap answers each threat.
4. **The assurance cases**: the project-level case, [`../../specs/assurance/aivhai-case.md`](../../specs/assurance/aivhai-case.md), a skeleton whose every leaf is an obligation; and the two worked cases in [`assurance-case/`](assurance-case/), with assumptions and open doubts first.
5. **[`methodology.md`](methodology.md)**: how the specifications, proofs, and cases were produced, and what the project does and does not claim.
6. **[`../../SECURITY.md`](../../SECURITY.md)** and **[`findings.md`](findings.md)**: how to report a finding, and what happens to it.

## The rest

| Document                                         | What it covers                                                                                      |
|--------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| [`schedule.md`](schedule.md)                     | The weekly release cadence and the provisional dates of all eight sprints                           |
| [`disclosure.md`](disclosure.md)                 | What a release contains, what never crosses into one, and how a release is cut                      |
| [`prior-engagements.md`](prior-engagements.md)   | FETT and VoteSecure as exemplars, and where each comparison stops holding                           |
| [`templates/`](templates/)                       | The hand-off note and weekly release note templates                                                 |

## Every release is pinned

`RELEASE.json`, at the root of each release, names:

- the private commit it was exported from;
- the `AIVHAI-Everything` commit that pins every upstream;
- the container images, by digest;
- the evaluation artifacts and the other pinned material, such as the CHERIoT development included for pedagogy, by commit;
- the SHA-256 of every file.

Please cite commit hashes rather than tags in any report.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
