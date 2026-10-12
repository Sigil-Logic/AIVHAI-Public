# Sprint N Hand-off to the Red Team

**Status**: Static artifact  
**Version**: 1.0.0  
**Date**: YYYY-MM-DD  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

<!-- TEMPLATE.  Copy to docs/red-team/sprint-N/handoff.md and fill every
     section.  Delete these comments.  Rules:
     - Every target and every claim is named by FULL commit hash.
     - The first paragraph states each claim's scope restriction; a scope
       restriction in a footnote is a defect.
     - No link to the private tracker; the note is read in the public mirror.
     - Nothing here may claim more than the assurance cases do.  The second
       reader checks this note against them before the release is cut. -->

This is Sigil Logic's hand-off for Sprint N's red-team week, which begins on **YYYY-MM-DD**.  In one paragraph: what is offered, the claim stated with its scope, and what is explicitly not offered.

## What to evaluate

| Target | Repository and commit | What we ask you to look at |
|--------|-----------------------|----------------------------|
|        | `owner/repo@<40-hex>` |                            |

## The claims

For each claim: the exact formal statement, quoted from the source with a file and line reference; its assumptions; what it excludes; its assurance case; and its proof state (proved, partially proved with named open obligations, or stated only).

## How to build and re-run

The exact commands, inside the images named in `RELEASE.json`, from a clean clone.  No step may be missing.

## Known gaps this sprint

What is new in [`../known-gaps.md`](../known-gaps.md) since the last hand-off, and the open defeaters in the assurance cases.

## Changes since the last hand-off

The weekly releases since the last hand-off, by public commit hash, with one line each.

## Findings from earlier sprints

Each earlier finding, its classification, and its resolution or current state.

## How to report

See [`../../../SECURITY.md`](../../../SECURITY.md).  Cite this release's commit hash.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
