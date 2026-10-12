#!/usr/bin/env python3
"""check-assurance-case.py -- validate and render AIVHAI structured assurance cases.

Specified in docs/red-team/assurance-case/README.md.  A case is a JSON file,
`<name>-case.json` (or, for the older worked cases, `<name>.case.json`),
holding a Goal Structuring Notation (GSN) argument plus
the two things a red team reads first: the assumptions and the defeaters.  Its
Markdown rendering, the same name ending `.md`, is generated and checked in, so the case
is readable on GitHub and in the public mirror without any tool.

    check-assurance-case.py DIR            validate every case in DIR, and fail
                                           if a rendering is missing or stale
    check-assurance-case.py --render DIR   rewrite the renderings
    check-assurance-case.py --release DIR  as DIR, and also refuse placeholders
                                           such as <DIGEST> in rerun commands and
                                           any PENDING evidence
    check-assurance-case.py --selftest     negative controls

Standard library only, because the CI image carries no PyYAML.
"""

import json
import re
import sys
import tempfile
from pathlib import Path

KINDS = {"goal", "strategy", "solution", "context", "assumption", "justification", "defeater"}
SUPPORT_TARGETS = {"goal", "strategy", "solution"}
CONTEXT_TARGETS = {"context", "assumption", "justification"}
CASE_STATUS = {"draft", "submitted", "superseded"}
ASSUMPTION_STATUS = {"open", "discharged", "accepted"}
DEFEATER_STATUS = {"open", "rebutted", "accepted"}
WORKDIR_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}$")
PIN_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}(:\S+)?$")
# Words that turn a scoped claim into an unscoped one (SL-AIVHAI-P04).  A goal
# containing one fails; rephrase the goal to say what was proved, over what.
# This is a vocabulary tripwire, not a P04 check: it cannot tell whether
# prose matches the formal statement it cites.  It reads every claim-making
# field (goals, strategies, justifications, evidence text, the summary, and
# claim_scope.covers), and ignores a match negated just before it ("does not
# guarantee"), since assumptions, exclusions and defeaters exist to say what
# is NOT claimed.
OVERCLAIM_RE = re.compile(r"\b(secure|guarantee[sd]?|impossible|bug-free|fully verified|verified correct"
                          r"|cannot be (bypassed|broken|circumvented|forged)|unforgeable|provably safe"
                          r"|is safe|prevents all|no attacker can|tamper-?proof)\b", re.I)
# Negated only if the negator is within the three words before the match.
NEGATION_RE = re.compile(r"(\b(not|no|never|without)|n't)(\s+\S+){0,2}\s*$", re.I)
# The one placeholder form: capitals in angle brackets (a shell redirection
# such as `make < in > out` is not one).
PLACEHOLDER_RE = re.compile(r"<(?=[^<>]{3,240}>)[A-Z][A-Z0-9 _,.-]{2,}(\s*\|[^<>]*)?>")
CLAIM_KINDS = {"goal", "strategy", "justification", "solution"}


def overclaims(text):
    for m in OVERCLAIM_RE.finditer(text or ""):
        if not NEGATION_RE.search(text[:m.start()]):
            return m.group(0)
    return None


def problems_of(case, release=False):
    p = []
    for field in ("case", "title", "status", "date", "claim_scope", "nodes"):
        if field not in case:
            p.append(f"missing top-level field `{field}`")
    if p:
        return p
    if case["status"] not in CASE_STATUS:
        p.append(f"status `{case['status']}` not one of {sorted(CASE_STATUS)}")
    scope = case["claim_scope"]
    for field in ("covers", "excludes"):
        if not isinstance(scope.get(field), list) or not scope.get(field):
            p.append(f"claim_scope.{field} must be a non-empty list: a case that excludes nothing "
                     f"has not stated its scope")
    nodes = {}
    for n in case["nodes"]:
        nid = n.get("id")
        if not nid:
            p.append(f"node without id: {n}")
            continue
        if nid in nodes:
            p.append(f"{nid}: duplicate id")
        nodes[nid] = n
        if n.get("kind") not in KINDS:
            p.append(f"{nid}: kind `{n.get('kind')}` not one of {sorted(KINDS)}")
        if not n.get("text"):
            p.append(f"{nid}: empty text")
    for nid, n in nodes.items():
        kind = n.get("kind")
        for t in n.get("supported_by", []):
            if t not in nodes:
                p.append(f"{nid}: supported_by unknown node {t}")
            elif nodes[t].get("kind") not in SUPPORT_TARGETS:
                p.append(f"{nid}: supported_by {t}, a {nodes[t].get('kind')}")
        for t in n.get("in_context_of", []):
            if t not in nodes:
                p.append(f"{nid}: in_context_of unknown node {t}")
            elif nodes[t].get("kind") not in CONTEXT_TARGETS:
                p.append(f"{nid}: in_context_of {t}, a {nodes[t].get('kind')}")
        if kind in ("goal", "strategy") and not n.get("supported_by") and not n.get("undeveloped"):
            p.append(f"{nid}: {kind} with no support must say `undeveloped` and why")
        if n.get("undeveloped") and len(n["undeveloped"].strip()) < 20:
            p.append(f"{nid}: the `undeveloped` reason is too short to tell a reader anything")
        if n.get("undeveloped") and case.get("status") != "draft":
            p.append(f"{nid}: undeveloped in a {case.get('status')} case; a plan is not a result")
        if n.get("undeveloped") and n.get("supported_by"):
            p.append(f"{nid}: both supported and undeveloped")
        word = overclaims(n.get("text", "")) if kind in CLAIM_KINDS else None
        if word:
            p.append(f"{nid}: {kind} text overclaims ({word!r}); state what is proved, over what")
        if kind == "solution":
            ev = n.get("evidence") or {}
            pin = ev.get("artifact", "")
            if pin == "PENDING":
                if case["status"] != "draft":
                    p.append(f"{nid}: PENDING evidence in a {case['status']} case")
                elif release:
                    p.append(f"{nid}: PENDING evidence cannot be released; record it, or mark the "
                             f"goals it supports undeveloped with the reason")
            elif not PIN_RE.match(pin):
                p.append(f"{nid}: evidence.artifact must be owner/repo@<40-hex commit>[:path] or "
                         f"PENDING, got {pin!r}")
            if ev.get("workdir") and not WORKDIR_RE.match(ev["workdir"]):
                p.append(f"{nid}: evidence.workdir must be owner/repo@<40-hex commit>, got {ev['workdir']!r}")
            if not ev.get("rerun"):
                p.append(f"{nid}: evidence.rerun missing: evidence nobody can re-derive is assertion")
            elif release and PLACEHOLDER_RE.search(ev["rerun"]):
                p.append(f"{nid}: evidence.rerun still has a placeholder "
                         f"{PLACEHOLDER_RE.search(ev['rerun']).group(0)!r}; fill it before release")
        if kind == "assumption":
            if n.get("status") not in ASSUMPTION_STATUS:
                p.append(f"{nid}: assumption status must be one of {sorted(ASSUMPTION_STATUS)}")
            if n.get("status") == "discharged" and not n.get("discharged_by"):
                p.append(f"{nid}: discharged, but discharged_by is empty")
        if kind == "defeater":
            if n.get("status") not in DEFEATER_STATUS:
                p.append(f"{nid}: defeater status must be one of {sorted(DEFEATER_STATUS)}")
            if not n.get("defeats") or n["defeats"] not in nodes:
                p.append(f"{nid}: defeater must name the node it defeats")
    for field, text in [("summary", case.get("summary", ""))] + [
            ("claim_scope.covers", c) for c in scope.get("covers", [])]:
        word = overclaims(text)
        if word:
            p.append(f"{field} overclaims ({word!r})")
    # Every context, assumption and justification is attached to something.
    referenced = {t for n in nodes.values() for t in n.get("in_context_of", [])}
    for nid, n in nodes.items():
        if n.get("kind") in CONTEXT_TARGETS and nid not in referenced:
            p.append(f"{nid}: {n['kind']} is attached to no node (in_context_of)")
    # Exactly one root goal, and the support graph is acyclic and reaches all.
    supported = {t for n in nodes.values() for t in n.get("supported_by", [])}
    roots = [nid for nid, n in nodes.items() if n.get("kind") == "goal" and nid not in supported]
    if len(roots) != 1:
        p.append(f"expected exactly one root goal, found {roots}")
    seen, stack = set(), []

    def visit(nid):
        if nid in stack:
            p.append(f"support cycle through {nid}")
            return
        if nid in seen:
            return
        seen.add(nid)
        stack.append(nid)
        for t in nodes.get(nid, {}).get("supported_by", []):
            visit(t)
        stack.pop()

    for r in roots:
        visit(r)
        has_assumption = any(nodes.get(t, {}).get("kind") == "assumption"
                             for t in nodes[r].get("in_context_of", []))
        if not has_assumption and not case.get("assumptions_none"):
            p.append(f"{r}: the root goal states no assumption; attach one, or say why there are "
                     f"none in `assumptions_none`")
    for nid, n in nodes.items():
        if n.get("kind") in SUPPORT_TARGETS and nid not in seen:
            p.append(f"{nid}: not reachable from the root goal")
    return p


# ------------------------------------------------------------------ rendering

def render(case, source_name):
    nodes = {n["id"]: n for n in case["nodes"]}
    supported = {t for n in nodes.values() for t in n.get("supported_by", [])}
    root = next(nid for nid, n in nodes.items() if n["kind"] == "goal" and nid not in supported)
    out = [f"# {case['title']}", "",
           f"**Status**: Static artifact, generated from `{source_name}`; do not edit  ",
           f"**Version**: {case.get('version', '0.1.0')}  ",
           f"**Date**: {case['date']}  ",
           "**Project**: AIVHAI  ",
           "", "---", "",
           f"Case `{case['case']}`, status **{case['status']}**.  "
           f"Generated by `scripts/release/check-assurance-case.py`; the JSON is the source.", ""]
    if case.get("summary"):
        out += [case["summary"], ""]
    out += ["## Scope of the claim", "", "**Covers:**", ""]
    out += [f"- {c}" for c in case["claim_scope"]["covers"]]
    out += ["", "**Does not cover:**", ""]
    out += [f"- {c}" for c in case["claim_scope"]["excludes"]]
    open_def = [n for n in nodes.values() if n["kind"] == "defeater" and n["status"] == "open"]
    if open_def:
        out += ["", "## Open defeaters", "",
                "Reasons to doubt the argument that are not yet resolved.  Read these before the argument.", ""]
        for d in open_def:
            out += [f"- **{d['id']}** (against {d['defeats']}): {d['text']}"
                    + (f"  Raised: {d['raised']}." if d.get("raised") else "")]
    out += ["", "## Assumptions", "", "Every assumption the argument rests on, and whether it is discharged.", ""]
    for a in (n for n in nodes.values() if n["kind"] == "assumption"):
        tail = f"  Discharged by: {a['discharged_by']}." if a.get("discharged_by") else ""
        out += [f"- **{a['id']}** [{a['status']}]: {a['text']}{tail}"]
    out += ["", "## Argument", ""]

    def walk(nid, depth):
        n = nodes[nid]
        label = {"goal": "Goal", "strategy": "Strategy", "solution": "Evidence"}[n["kind"]]
        line = f"{'  ' * depth}- **{nid}** {label}: {n['text']}"
        if n.get("undeveloped"):
            line += f"  *Undeveloped: {n['undeveloped']}*"
        ctx = n.get("in_context_of", [])
        if ctx:
            line += "  (in context of " + ", ".join(ctx) + ")"
        out.append(line)
        if n["kind"] == "solution":
            ev = n["evidence"]
            out.append(f"{'  ' * (depth + 1)}- Artifact: `{ev['artifact']}`")
            out.append(f"{'  ' * (depth + 1)}- Re-derive: `{ev['rerun']}`")
        for t in n.get("supported_by", []):
            walk(t, depth + 1)

    walk(root, 0)
    others = [n for n in nodes.values() if n["kind"] in ("context", "justification")]
    if others:
        out += ["", "## Context and justifications", ""]
        out += [f"- **{n['id']}** ({n['kind']}): {n['text']}" for n in others]
    closed = [n for n in nodes.values() if n["kind"] == "defeater" and n["status"] != "open"]
    if closed:
        out += ["", "## Resolved defeaters", ""]
        out += [f"- **{d['id']}** [{d['status']}] (against {d['defeats']}): {d['text']}"
                + (f"  Resolution: {d['resolution']}" if d.get("resolution") else "") for d in closed]
    out += ["", "<!--", "Local Variables:", "auto-fill-mode: nil", "End:", "-->", ""]
    return "\n".join(out)


CASE_GLOBS = ("*-case.json", "*.case.json")


def case_files(directory):
    """Every case in DIRECTORY: `<name>-case.json`, or the older `<name>.case.json`."""
    return sorted({p for g in CASE_GLOBS for p in Path(directory).glob(g)})


def rendering_of(path):
    """A case's Markdown rendering: its own name, ending `.md`."""
    return path.with_suffix(".md")


def run(directory, write, release=False):
    cases = case_files(directory)
    if not cases:
        print(f"no *-case.json or *.case.json in {directory}")
        return 1
    bad = 0
    for path in cases:
        try:
            case = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            print(f"{path}: not JSON: {e}")
            bad += 1
            continue
        probs = problems_of(case, release)
        for pr in probs:
            print(f"{path}: {pr}")
        if probs:
            bad += 1
            continue
        md = rendering_of(path)
        text = render(case, path.name)
        if write:
            md.write_text(text)
            print(f"rendered {md}")
        elif not md.exists() or md.read_text() != text:
            print(f"{md}: missing or stale; run scripts/release/check-assurance-case.py --render {directory}")
            bad += 1
        else:
            print(f"ok       {path.name}")
    return 1 if bad else 0


def selftest():
    good = {"case": "t", "title": "T", "status": "draft", "date": "2026-10-09",
            "claim_scope": {"covers": ["x"], "excludes": ["y"]},
            "nodes": [
                {"id": "G1", "kind": "goal", "text": "P holds of model M at commit C",
                 "supported_by": ["S1"], "in_context_of": ["A1"]},
                {"id": "S1", "kind": "strategy", "text": "by induction", "supported_by": ["E1", "G2"]},
                {"id": "E1", "kind": "solution", "text": "the proof",
                 "evidence": {"artifact": "o/r@" + "a" * 40 + ":f.v:1", "rerun": "make"}},
                {"id": "G2", "kind": "goal", "text": "lemma L", "undeveloped": "the lemma is not yet stated"},
                {"id": "A1", "kind": "assumption", "text": "well-formed", "status": "open"},
                {"id": "D1", "kind": "defeater", "text": "maybe vacuous", "status": "open", "defeats": "A1"}]}
    fails = []

    def mutate(name, f, expect_bad=True):
        c = json.loads(json.dumps(good))
        f(c)
        bad = bool(problems_of(c))
        if bad != expect_bad:
            fails.append(name)

    mutate("good case passes", lambda c: None, expect_bad=False)
    mutate("overclaiming goal", lambda c: c["nodes"][0].update(text="The core is secure"))
    mutate("unpinned evidence", lambda c: c["nodes"][2]["evidence"].update(artifact="o/r@main"))
    mutate("no rerun", lambda c: c["nodes"][2]["evidence"].pop("rerun"))
    mutate("pending in submitted case", lambda c: (c.update(status="submitted"),
                                                   c["nodes"][2]["evidence"].update(artifact="PENDING")))
    mutate("unsupported goal", lambda c: c["nodes"][3].pop("undeveloped"))
    mutate("empty exclusions", lambda c: c["claim_scope"].update(excludes=[]))
    mutate("cycle", lambda c: c["nodes"][1]["supported_by"].append("G1") or c["nodes"].append(
        {"id": "G0", "kind": "goal", "text": "r", "supported_by": ["G1"]}))
    mutate("assumption without status", lambda c: c["nodes"][4].pop("status"))
    mutate("defeater naming nothing", lambda c: c["nodes"][5].update(defeats="Z9"))
    mutate("discharged without discharger", lambda c: c["nodes"][4].update(status="discharged"))
    mutate("overclaim in a strategy", lambda c: c["nodes"][1].update(text="by induction, which is unforgeable"))
    mutate("negated claim word is fine", lambda c: c["nodes"][1].update(text="by induction; this does not guarantee liveness"),
           expect_bad=False)
    mutate("overclaim in the summary", lambda c: c.update(summary="The design prevents all attacks."))
    mutate("orphan assumption", lambda c: c["nodes"].append({"id": "A9", "kind": "assumption", "text": "x", "status": "open"}))
    mutate("root goal without assumptions", lambda c: c["nodes"][0].update(in_context_of=[]) or c["nodes"].pop(4))
    mutate("undeveloped goal in a submitted case", lambda c: c.update(status="submitted"))
    mutate("undeveloped reason too short", lambda c: c["nodes"][3].update(undeveloped="tbd"))
    mutate("unreachable goal", lambda c: c["nodes"].append({"id": "G9", "kind": "goal", "text": "x", "undeveloped": "an unattached plan item"}))
    mutate("duplicate id", lambda c: c["nodes"].append(dict(c["nodes"][2])))
    mutate("supported and undeveloped", lambda c: c["nodes"][1].update(undeveloped="both at once, which is wrong"))
    mutate("defeater without status", lambda c: c["nodes"][5].pop("status"))
    mutate("workdir not pinned", lambda c: c["nodes"][2]["evidence"].update(workdir="o/r@main"))
    mutate("negation far before the word does not excuse it",
           lambda c: c["nodes"][1].update(text="The proof is not vacuous and the core is secure"))
    pend = json.loads(json.dumps(good))
    pend["nodes"][2]["evidence"]["artifact"] = "PENDING"
    if problems_of(pend, release=False) or not problems_of(pend, release=True):
        fails.append("PENDING evidence: passes a check, fails a release")
    redir = json.loads(json.dumps(good))
    redir["nodes"][2]["evidence"]["rerun"] = "make < in > out"
    if problems_of(redir, release=True):
        fails.append("a shell redirection is not a placeholder")
    rel = json.loads(json.dumps(good))
    rel["nodes"][2]["evidence"]["rerun"] = "docker run img@<DIGEST> make"
    if not problems_of(rel, release=True) or problems_of(rel, release=False):
        fails.append("rerun placeholder: fails a release, passes a check")
    with tempfile.TemporaryDirectory() as d:
        Path(d, "t.case.json").write_text(json.dumps(good))
        if run(d, False) == 0:
            fails.append("missing rendering not detected")
        run(d, True)
        if run(d, False) != 0:
            fails.append("fresh rendering rejected")
    with tempfile.TemporaryDirectory() as d:
        Path(d, "t-case.json").write_text(json.dumps(good))
        run(d, True)
        if not Path(d, "t-case.md").exists() or run(d, False) != 0:
            fails.append("a <name>-case.json case is not found or not rendered to <name>-case.md")
    for f in fails:
        print("SELFTEST FAIL: " + f)
    print("selftest: " + ("FAIL" if fails else "PASS (30 cases)"))
    return 1 if fails else 0


def main(argv):
    if argv == ["--selftest"]:
        return selftest()
    if len(argv) == 2 and argv[0] == "--render":
        return run(argv[1], True)
    if len(argv) == 2 and argv[0] == "--release":
        return run(argv[1], False, release=True)
    if len(argv) == 1:
        return run(argv[0], False)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
