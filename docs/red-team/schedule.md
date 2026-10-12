# Red-Team Cadence and Schedule

**Status**: Living document  
**Version**: 0.2.0  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

ARIA gives each 8-week sprint six weeks of building and verifying, one week of red-teaming (week 7), and one week of review and retargeting (week 8).  This document fixes how Sigil Logic's releases fit that rhythm, and it gives the provisional dates for all eight sprints.  How a release is made is in [`disclosure.md`](disclosure.md).

## The cadence

The cadence answers the norms Trail of Bits set out on 2026-10-08: incremental updates during weeks 1 to 6, so that they can choose where to focus in week 7, and **no large drop of new material just before week 7**.  Capabilities Limited added that a release should be a well-validated combination, with the compiler, the ISA model, and the specification synchronised.

| When                                  | What Sigil Logic releases                                                                                                                                           |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Fridays of weeks 1 to 5, afternoon PT | **A weekly release.**  Whatever has changed: models, specifications, documentation, assurance cases, evidence.  Each is a complete, consistent snapshot, not a diff |
| Friday of week 6                      | **The freeze candidate.**  No new targets or properties after this point; only corrections, documentation, and evidence for what is already released                |
| Monday of week 7, before 09:00 CET    | **The hand-off release.**  The freeze candidate plus corrections, with the hand-off note naming the targets and the properties offered for evaluation               |
| During week 7                         | No release.  Support on Slack, with calls as needed; a correction that a finding forces is released only if the red team asks for it                                |
| Week 8                                | Findings triaged ([`findings.md`](findings.md)); the next sprint's targets retargeted with ARIA through the prime                                                   |
| Any time                              | A finding is acknowledged within two working days (see [`../../SECURITY.md`](../../SECURITY.md))                                                                    |

**Why weekly and Friday.**  A sprint boundary is too coarse for a red team that wants to watch work develop, and a per-commit mirror is too fine to be validated.  Weekly releases match the project's internal rhythm, which is weekly throughout, so every release follows a week's review.  Friday gives the red team a stable state over their weekend and keeps Monday free for the consortium sync.

**The 09:00 CET cutoff is midnight Pacific.**  The hand-off release must therefore be cut by the end of Sunday, Pacific time.  In practice it is the week-6 Friday release, re-cut on Sunday only if a correction is needed.

**Sprint 1 is exempt from the freeze rule.**  It is the first cycle, the project had been under contract for four weeks at the hand-off, and the hand-off is explicitly a first showing of what a hand-off is rather than the full assurance package.  The weekly releases start with it.

## The provisional calendar

The calendar is anchored on the one date Trail of Bits and Capabilities Limited have confirmed: Sprint 1's red-team week begins on **Monday 2026-10-12**.  Every later sprint is placed on a strict 8-week grid from that date.

| Sprint | Week 1 begins | Week-5 release | Freeze candidate (week 6) | Hand-off (week 7) | Week 8 begins | Sprint ends | Milestone due date today |
|--------|---------------|----------------|---------------------------|-------------------|---------------|-------------|--------------------------|
| 1      | 2026-08-31    | 2026-10-02     | 2026-10-09                | 2026-10-12        | 2026-10-19    | 2026-10-23  | 2026-10-23               |
| 2      | 2026-10-26    | 2026-11-27     | 2026-12-04                | 2026-12-07        | 2026-12-14    | 2026-12-18  | 2026-12-16               |
| 3      | 2026-12-21    | 2027-01-22     | 2027-01-29                | 2027-02-01        | 2027-02-08    | 2027-02-12  | 2027-02-07               |
| 4      | 2027-02-15    | 2027-03-19     | 2027-03-26                | 2027-03-29        | 2027-04-05    | 2027-04-09  | 2027-04-01               |
| 5      | 2027-04-12    | 2027-05-14     | 2027-05-21                | 2027-05-24        | 2027-05-31    | 2027-06-04  | 2027-05-24               |
| 6      | 2027-06-07    | 2027-07-09     | 2027-07-16                | 2027-07-19        | 2027-07-26    | 2027-07-30  | 2027-07-17               |
| 7      | 2027-08-02    | 2027-09-03     | 2027-09-10                | 2027-09-13        | 2027-09-20    | 2027-09-24  | 2027-09-08               |
| 8      | 2027-09-27    | 2027-10-29     | 2027-11-05                | 2027-11-08        | 2027-11-15    | 2027-11-19  | 2027-10-31               |

**This calendar is provisional, and it disagrees with the milestones.**  The milestone due dates in the last column were set before the contract was signed, by dividing months 1 to 14 evenly.  They drift from the 8-week grid by up to 19 days by Sprint 8, and the grid's Sprint 8 ends 2027-11-19, close to the contract's end around 2027-12-07.  Two things decide which is right: the sprint calendar that ARIA and Capabilities Limited actually run, and the holiday weeks (Sprint 3 begins on 2026-12-21).  Until the prime confirms the calendar, each sprint's hand-off date is confirmed with Capabilities Limited at the start of that sprint, and this table and the milestones are corrected together.

## What each sprint's hand-off offers

The targets follow the sprint plan.  What is red-teamed in each sprint is decided with the consortium during the previous sprint's week 8, and recorded in that sprint's hand-off note.

| Sprint | Red-team target, as planned today                                                                                                                                                                                                                                             |
|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      | A practice run.  The RVY Sail ISA model without vector, read against the RVY draft specification for defects that could lead to security harm, and Capabilities Limited's bare-metal compartment firmware.  The CHERIoT materials accompany them for pedagogy, not evaluation |
| 2 to 8 | Set by each sprint's milestone description (`specs/infra/milestones.yml`) and retargeted in week 8; executable formal models are the only artifacts for roughly the first twelve months, with remote FPGA access around month 14                                              |

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
