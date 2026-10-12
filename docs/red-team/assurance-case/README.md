# Assurance Cases

**Status**: Living document  
**Version**: 0.3.1  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

An assurance case is the argument from evidence to a claim: what is claimed, why the evidence supports it, what it rests on, and what might undermine it.  Every proved claim and every proof target that Sigil Logic offers the red team has one, in this directory.  Informal properties offered only as audit hypotheses (RP2 to RP5 in the Sprint 1 hand-off) do not yet have one.

## The project-level case, and how these attach to it

The project's own case is [`../../../specs/assurance/aivhai-case.md`](../../../specs/assurance/aivhai-case.md): the proof series as a goal structure, grounded in the threat model ([`../../../specs/assurance/threat-model.md`](../../../specs/assurance/threat-model.md)), with every leaf goal undeveloped and the reason given.  It is written in this format and checked by the same script.  The two cases below attach to it as context, pinned by commit, not as evidence: the RVY plan beneath its goal G-a1, and the CHERIoT theorem beneath G-CF2, as a precedent for the method that goal is expected to follow.

## The two worked examples

These are the Sprint 1 best-practice examples of the format.  They are chosen to be opposites.  The CHERIoT case is included for pedagogy: to show what a mechanised Rocq proof and a structured case around it look like, and to invite reflection on how such material is packaged.  It is not a red-team target, and CHERIoT is not AIVHAI's design.

| Case                                                                                 | What it shows                                                                                                                                                                                                           |
|--------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [CHERIoT thread-isolated monotonicity](cheriot-thread-isolated-monotonicity.case.md) | A **real result**, honestly scoped: a proved theorem whose scope makes it vacuous outside same-domain traces, whose main hypothesis carries most of the weight, and which has an open defeater raised by its own author |
| [RVY Sail monotonicity](rvy-sail-monotonicity.case.md)                               | A **plan**, with nothing proved: every leaf goal undeveloped and the reason given, so that a reader can tell a plan from a result at a glance                                                                           |

Read the scope and the open defeaters of each before its argument.  The rendering puts them first for that reason.

## The format

A case is Goal Structuring Notation (GSN), held as JSON in `<name>-case.json` and rendered to `<name>-case.md`, following the repository's hyphenated file names.  The two worked examples here keep their earlier names, `<name>.case.json` and `<name>.case.md`, because the project case pins them by path; the tools accept both forms.  The JSON is the source; the Markdown is generated, checked in, and checked for staleness, so the case is readable on GitHub and in the public mirror without any tool.

| Node kind       | GSN element                 | What it holds                                                                                                                                                                                                                        |
|-----------------|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `goal`          | Goal                        | A claim.  If nothing supports it yet, it says `undeveloped` and why                                                                                                                                                                  |
| `strategy`      | Strategy                    | How a goal is broken into sub-goals                                                                                                                                                                                                  |
| `solution`      | Solution                    | Evidence, pinned to `owner/repo@<40-hex commit>[:path:line]`, with the `rerun` command that re-derives it, and optionally a `workdir` (`owner/repo@<40-hex>`) where that command runs when it differs from the artifact's repository |
| `context`       | Context                     | Definitions and facts the argument is read against                                                                                                                                                                                   |
| `assumption`    | Assumption                  | Something the argument relies on, with a status: `open`, `discharged` (by what), or `accepted` (why)                                                                                                                                 |
| `justification` | Justification               | Why a strategy is sound                                                                                                                                                                                                              |
| `defeater`      | (eliminative argumentation) | A reason to doubt a node, with a status: `open`, `rebutted`, or `accepted`                                                                                                                                                           |

Each case also has a `claim_scope` with `covers` and `excludes` lists.  Both must be non-empty.

## What the checker enforces

`scripts/release/check-assurance-case.py docs/red-team/assurance-case` runs in `make ci` and in the release workflow, together with its own negative controls (`--selftest`).  It fails when any of the following holds:

- the case has no single root goal, or the support graph has a cycle, or a goal, strategy, or evidence node cannot be reached from the root;
- a context, assumption, or justification is attached to no node;
- the root goal states no assumption, and the case does not say in `assumptions_none` why it has none;
- a goal or strategy has neither support nor an `undeveloped` reason, the reason is too short to inform, or a goal is both;
- a case whose status is not `draft` still has an undeveloped goal or `PENDING` evidence: a plan cannot be relabelled as a result;
- evidence is not pinned to a full commit hash, or has no `rerun` command;
- an assumption or defeater has no status, a defeater names no target, or a `discharged` assumption does not say by what;
- the scope's `excludes` list is empty;
- **claim-making prose uses absolute vocabulary**: a goal, strategy, justification, evidence description, the summary, or a `covers` entry contains a word such as *secure*, *guarantees*, *unforgeable*, *cannot be circumvented*, *prevents all*, or *provably safe*, unless it is negated (*does not guarantee*);
- a rendering is missing or out of date.

With `--release`, which `cut-release.sh` runs on the cases at the released commit, it also refuses a placeholder such as `<DIGEST>` in a `rerun` command.  Commands that need the toolchain image use the shell variable `$AIVHAI_PROVERS`, which the reader sets from the release manifest: `AIVHAI_PROVERS="$(jq -r '.pins.images["aivhai-provers"]' RELEASE.json)"`.

**Replaying the evidence.**  `scripts/release/replay-evidence.py run` re-derives every evidence node: it checks out the node's `workdir` (by default the artifact's own repository and commit), runs `rerun` there with bash, and records each result in `replay.json`.  A `rerun` command therefore runs with that checkout as its working directory and does not clone anything itself.  `replay-evidence.py list` shows every node without running anything.

**An assumption's status** reads as follows.  *Open* means it is a hypothesis of the result that has not been shown to hold of any concrete system; *discharged* means another result establishes it; *accepted* means it is taken as given, with the reason stated.

**The vocabulary check is a tripwire, not a review.**  The checker cannot tell whether a goal's prose matches the formal statement it cites.  That is the reviewer's first question, and the reason every release has a second reader.

```bash
# After editing a case:
python3 scripts/release/check-assurance-case.py --render docs/red-team/assurance-case
python3 scripts/release/check-assurance-case.py docs/red-team/assurance-case
python3 scripts/release/check-assurance-case.py --selftest
```

## Why this format, and not a dedicated tool

VoteSecure, the exemplar described in [`../prior-engagements.md`](../prior-engagements.md), uses NASA's AdvoCATE and generates its case skeleton from models.  **AIVHAI does not use AdvoCATE** (decided by Joe Kiniry, 2026-10-09).  Its assurance cases, including the project-level case, are plain, structured, semi-formal GSN in this format: readable without any tool, importable by any GSN tool, and checked in CI.  AdvoCATE is an Eclipse application, while this project's artifacts are Sail, Rocq, Guru, and SystemVerilog.  VoteSecure remains an exemplar of the practice, not of the tool.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
