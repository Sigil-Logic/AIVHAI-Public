# Disclosure to the Red Team

**Status**: Living document  
**Version**: 0.2.1  
**Date**: 2026-10-10  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

This document specifies how Sigil Logic's AIVHAI work reaches the red team: what each release contains, what can never be in one, how a release is cut, and who cuts it.  The schedule is in [`schedule.md`](schedule.md).

Sigil Logic develops in a private repository and publishes to a public one, `Sigil-Logic/AIVHAI-Public`.  The red team, Trail of Bits, reads the public repository and has no access to the private one.  Every release is one signed commit in the public repository.  That commit holds a filtered copy of one commit of the private repository, together with a manifest saying which commit it was.

## What a release contains

Every release has the same parts.  The weekly releases carry whatever has changed; the hand-off release at the start of red-team week carries all of them, current.

| Part                | What it is                                                                                                                    | Where in the release                                |
|---------------------|-------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| Hand-off note       | What is offered for evaluation, the exact statements claimed, their assumptions, what is excluded, and how to build           | `docs/red-team/sprint-N/handoff.md`                 |
| Targets             | The models and specifications under evaluation, each named by repository and **full commit hash**                             | The hand-off note, and `RELEASE.json`               |
| Upstream pins       | The `AIVHAI-Everything` commit that pins every upstream the claims are made over                                              | `RELEASE.json` → `pins.aivhai_everything`           |
| Toolchain images    | The container images that build and check everything, by digest, with their Dockerfiles and any customised tool builds stated | `RELEASE.json` → `pins.images`; `infra/containers/` |
| Assurance cases     | The structured argument for each claim, with every assumption and every open doubt listed                                     | `docs/red-team/assurance-case/`                     |
| Executable evidence | For every piece of evidence, the command that re-derives it inside the images                                                 | The `rerun` field of each evidence node             |
| Known gaps          | What we know is missing, unproved, or doubtful, stated before anyone finds it                                                 | `docs/red-team/known-gaps.md`                       |
| Methodology         | How the specifications, proofs, and cases were produced                                                                       | `docs/red-team/methodology.md`                      |
| Findings route      | How to report a finding, and what happens to it                                                                               | `SECURITY.md`, `docs/red-team/findings.md`          |
| Manifest            | The source commit, every pin, every file's SHA-256, and every waiver the leak scan applied                                    | `RELEASE.json`                                      |

**Cite commit hashes, not tags.**  Each release is also tagged `release/<name>` for convenience, but a tag can be moved and a hash cannot.  Trail of Bits reports against hashes, and so do we.

**Negative results are disclosed.**  A proof attempted and abandoned, or an assumption found to be unsound, is recorded in the assurance case as a defeater or an undeveloped goal, not removed from it.  A red team learns more from a failed proof than from a successful one, and it would find the gap anyway.

## What must never cross

These categories must never appear in the public repository:

1. **Cost, rate, staffing, and hiring material** (project policy SL-AIVHAI-P05): budgets, salaries, rates, invoices, effort allocations, and hiring deliberations.  These belong in the program repository, AIVHAI-Project-Management, which nothing is ever exported from.
2. **Third-party texts we may not republish.**  The project bibliography ([`../bibliography.md`](../bibliography.md)) records a `redistribute` verdict for every full text it stores.  A file under `docs/bib/` crosses only if a `yes` entry names it and no other entry does.
3. **Credentials.**
4. **Partner-confidential material**: anything a consortium partner gave us that it has not published.

Only the second is enforced mechanically for every file, and only within `docs/bib/`: a PDF anywhere else fails the release, so third-party full texts must live there.  The first and third are caught by pattern, which is a tripwire with known gaps, listed below.  The fourth cannot be detected by pattern at all.  All four therefore rest first on the allowlist: nothing crosses unless someone has decided, in a reviewed change, that it should.

## The filter

The filter is [`release/public-allowlist.txt`](../../release/public-allowlist.txt), applied by [`scripts/release/export-public.py`](../../scripts/release/export-public.py).  The allowlist has three kinds of entry: `include` patterns, `exclude` patterns that remove paths an `include` matched, and `overlay` lines that publish a tracked file under another name (the public `README.md` and `LICENSE`).  Patterns are shell-style globs in which `*` also matches `/`.  Four controls follow, and a release passes only if all four do.

1. **The allowlist.**  A tracked file crosses only if an `include` names it and no `exclude` removes it, or if an `overlay` names it.  An overlay is refused if its source is excluded, if source or destination is under `docs/bib/`, if its destination is not a plain relative path, or if its destination is reserved: any `.git` component, in any letter case, or `RELEASE.json`.  The default is private: a file added to the repository stays private until a reviewed change to the allowlist says otherwise.  An allowlist was chosen over a denylist because a denylist leaks every new file by default (decision of 2026-10-09).
2. **Bibliography verdicts.**  Under `docs/bib/`, a file crosses only if it appears in the `fulltext` field of a `redistribute: yes` entry and in no entry with another verdict; a conflict resolves to private.  An unregistered file never crosses.  A PDF outside `docs/bib/` fails the release.
3. **LFS resolution.**  Any file that begins like a Git LFS pointer must resolve to its content; a release refuses to publish a pointer in place of a PDF.  The CI dry run fetches no LFS objects and so does not exercise this control; the exporter's selftest and the real cut do.
4. **The content scan.**  Every exported file except the bibliography's third-party texts is scanned against the rules below, and so is the generated `RELEASE.json`, whose pins come from outside the commit.  Text in UTF-16 or UTF-32 with a byte-order mark is decoded first; other binary files are scanned as bytes, for the failing rules only.

These findings **fail** the release:

| Rule             | Catches                                                                                                                                                                                                                                                              |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `currency`       | Sums in pounds, euros, or dollars: by symbol (`£12`, `€12`, `$12`, `$1.50`, `$1,200`, `$12k`, `US$12`, `1200$`), by code (`GBP 12`, `12 GBP`), or in words (`5 million euros`, `1.2m euros`); a `$` after a digit, `$` or `{` is not money, so shell parameters pass |
| `compensation`   | Salary, on-cost, day or hourly rate, billing rate, payroll, invoices, equity, overhead rate, budgeted hours                                                                                                                                                          |
| `staffing`       | Hiring, recruitment, headcount, FTE, W-2 employment                                                                                                                                                                                                                  |
| `programme-repo` | The names of Sigil Logic's program repository and four other private repositories that hold proposal, business, organization, and timesheet material                                                                                                                 |
| `secret`         | GitHub tokens; AWS access key ids (`AKIA`, `ASIA`) and secret-key assignments; Google API keys; `sk-` style API keys; Slack tokens; private keys; `password =` style assignments                                                                                     |
| `infrastructure` | AWS account ARNs, instance and security-group ids, private network addresses                                                                                                                                                                                         |

One rule fails a real release but only warns in the CI dry run: `placeholder`, an unfilled `<PLACEHOLDER>` in capitals of three or more characters.  That is the one placeholder form the templates use; it lets a hand-off note carry its holes during the week, and makes that form impossible to ship.  Other forms (`TODO`, `[TBD]`, lower-case holes) are not detected.

Two rules only **warn**, and the manifest records each occurrence: `private-tracker`, a link to an issue or pull request in this private repository, which a public reader cannot follow, and `email`, an e-mail address other than a GitHub no-reply address.  Provenance lines are exempt from `private-tracker`: a NINJA header's `Issue`, `Review`, and `Design` lines, and a script header's `# Issue:` line and the issue links that continue it.  They disclose nothing beyond an issue's existence.

**Known gaps in the scan.**  It cannot recognise partner-confidential prose, a personnel judgement phrased without a trigger word, a sum written without a currency marker, a credential in a shape it does not list, or text in an encoding other than UTF-8 that carries no byte-order mark.  Private repositories other than the five it names, including `AIVHAI-Everything`, are not flagged.  That is why the scan is a backstop and the allowlist, with its review, is the primary control.

**Waivers.**  The patterns are deliberately broad.  A false positive is excused by a `waive` line in the allowlist.  Each `waive` line names the path, the rule, and a regular expression for the line, and must give a reason.  A waiver whose regular expression matches any of a fixed set of unrelated probe lines (as `.*`, `.+`, `\S`, and `[^x]` all do) is refused, so a waiver must be anchored to the text of the line it excuses.  Every waiver that a release uses is listed in its manifest.  A false negative cannot be undone, so the trade is deliberate.

The exporter has negative controls (`export-public.py selftest`): each plants one kind of leak in a scratch repository and checks that the exporter refuses it.  They cover every rule, overlay misuse including `.git` and `RELEASE.json`, broad waivers, conflicting bibliography verdicts, stray PDFs, non-canonical LFS pointers, secrets inside binaries and UTF-16 text, and leaks smuggled into `RELEASE.json`.  CI runs them on every pull request.

## Cutting a release

A release is cut by a person, because Sigil Logic's policy is that every commit is signed and no automation here yet holds a signing key.  The organization ruleset that would enforce signing on the platform was found disabled on 2026-10-09, so `cut-release.sh` verifies the signatures itself.

```bash
# Dry run: what would cross, and would the scan pass?  CI runs the same
# checks on every pull request and every Friday at 20:00 UTC.
make release-check

# The release: a signed commit and a signed tag in a local clone of
# AIVHAI-Public, with the push command printed for review.
scripts/release/cut-release.sh 2026-10-16 --everything <AIVHAI-Everything commit>

# A hand-off release names its evaluation targets, recorded in the manifest.
# Every target must be a full 40-hex commit.
scripts/release/cut-release.sh 2026-10-12-sprint-1-handoff \
  --everything <commit> \
  --target sail-cheri-riscv=Capabilities-Limited/sail-cheri-riscv@84515a85ead058eb2cc8bffb45496979f2dbdd7c \
  --target riscv-cheri=riscv/riscv-cheri@2946806c10910c12c1b9dc6153e9b0d56ccd8ce6 \
  --target cheriot-abstract-spec=Sigil-Logic/cheriot-abstract-spec@<handoff commit>
```

`cut-release.sh` does the following, in order:

1. It refuses a commit that is not on `main`, unless `--allow-unmerged` is given, in which case the manifest records it.
2. It refuses any `--target` that is not a full commit hash.
3. It copies the whole AIVHAI-Everything manifest into `RELEASE.json`.  The red team has write access to that private repository, so that it can push its own branches back to us as feedback; the copy makes each release self-contained for every other reader, and for anyone checking a release years later.
4. It resolves the current digest of every `aivhai-*` image.
5. It checks the assurance cases at the released commit in release mode.
6. It exports, failing on any placeholder.
7. It replaces the whole public tree, so that a file removed from the allowlist disappears.
8. It commits and tags, and verifies that both commit and tag are signed.
9. It pushes commit and tag atomically, and only with `--push`.

**Release names.**  `YYYY-MM-DD` for a weekly release; `YYYY-MM-DD-sprint-N-handoff` for the release at the start of a red-team week.

**After pushing**, the release manager:

1. Posts the public commit hash and a two-line summary in the shared red-team channel, `#aria-aivhai-redteam` on the CHERI-CPU Slack.
2. Records the hash on the sprint's hand-off issue.
3. For a hand-off release, also e-mails the Trail of Bits contacts, since they asked for deadlines and escalations by e-mail.

## Who releases

The **release manager** for a sprint is named on the sprint's hand-off issue.  By default it is the Sigil Logic performer most active in that sprint.  Every release also needs a **second reader** before it is pushed, because a release states Sigil Logic's position to a consortium partner and to the funder's red team.  The second reader reviews the hand-off note's claims against the assurance cases, using the review question of project policy SL-AIVHAI-P04: *what exactly was proved, under what assumptions, and does the prose overstate it?*

## What is not automated yet

- **Unattended release.**  It waits for the HOARDE GitHub App to hold a signing key, as the `metrics-*` refs do.  Until then CI runs the dry run on the release slot and a person cuts the release.
- **A partner-material detector.**  None is planned: the allowlist is the control.
- **Threat-model publication in two forms** (a flat hyperlinked document and an interactive one).  The threat model is released from the Sprint 1 hand-off on as a flat hyperlinked document, [`../../specs/assurance/threat-model.md`](../../specs/assurance/threat-model.md); the interactive form is not yet made; see [`known-gaps.md`](known-gaps.md).

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
