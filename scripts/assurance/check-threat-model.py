#!/usr/bin/env python3
# check-threat-model.py -- the threat model and the assurance case, checked
# against each other in both directions.
#
# @req   AIVHAI-SYS-R12 (each sprint's property is stated with its assumptions)
# @design Threat, AssuranceCase
# @todo  #225 section 10, #226
#
# The threat model (specs/assurance/threat-model.md) dispositions every threat
# to a goal of the case, an assumption, an exclusion, or a known gap.  The case
# (specs/assurance/aivhai-case.json) cites threats in its goals, assumptions
# and gap nodes.  This script fails when the two disagree:
#
#   forward   every TM- row has an adversary and an asset defined in sections
#             3 and 4 (or a dash), a source, and a disposition; every G- it
#             names is a goal of the case, every A- an assumption, every GAP-
#             a gap of section 8 that the case carries as a context node, and
#             every EXCL- an exclusion of section 7 that the case's scope
#             excludes;
#   backward  every threat a goal, assumption or gap node of the case cites
#             names that node, or for a goal one of its sub-goals, in its
#             disposition;
#   coverage  every assumption and gap is used by some threat, and every
#             assumption and gap of the case exists in the threat model.  An
#             exclusion may be a scope statement with no threat of its own
#             (EXCL-1, semantic benignity, is one), so exclusions are not
#             required to be used.
#
# Usage:
#   check-threat-model.py [--threat-model PATH] [--case PATH]
#   check-threat-model.py --selftest
#
# Exit status 0 when consistent, 1 when not, 2 on a usage or parse error.
# Runs without a TTY and reads nothing but its two inputs.

import argparse
import json
import pathlib
import re
import sys

TM_DEFAULT = "specs/assurance/threat-model.md"
CASE_DEFAULT = "specs/assurance/aivhai-case.json"

RE_TM = re.compile(r"\bTM-(\d{3})\b")
RE_RANGE = re.compile(r"\bTM-(\d{3}) to TM-(\d{3})\b")
RE_GOAL = re.compile(r"\bG-[A-Za-z]+\d*\b")
RE_ASSUME = re.compile(r"\bA-\d+\b")
RE_EXCL = re.compile(r"\bEXCL-\d+\b")
RE_GAP = re.compile(r"\bGAP-\d+\b")


def rows(text, first_cell):
    """Table rows whose first cell matches first_cell, as lists of stripped cells."""
    out = []
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells and re.fullmatch(first_cell, cells[0]):
            out.append(cells)
    return out


def cited_threats(text):
    """Every TM- number a piece of prose cites, with 'TM-a to TM-b' expanded."""
    found = {int(n) for n in RE_TM.findall(text)}
    for a, b in RE_RANGE.findall(text):
        found.update(range(int(a), int(b) + 1))
    return found


def parse_threat_model(text):
    tm = {
        "assets": {r[0] for r in rows(text, r"AS-\d+")},
        "adversaries": {r[0] for r in rows(text, r"ADV-\d+")},
        "exclusions": {r[0] for r in rows(text, r"EXCL-\d+")},
        "gaps": {r[0] for r in rows(text, r"GAP-\d+")},
        "threats": {},
        "duplicates": [],
    }
    m = re.search(r"`A-n` an assumption of the case[^|]*", text)
    tm["assumptions"] = set(RE_ASSUME.findall(m.group(0))) if m else set()
    for r in rows(text, r"TM-\d{3}"):
        if r[0] in tm["threats"]:
            tm["duplicates"].append(r[0])
        tm["threats"][r[0]] = {"adversary": r[1], "asset": r[2], "source": r[5],
                               "disposition": r[-1]}
    return tm


def descendants(nodes, nid):
    seen, todo = set(), [nid]
    while todo:
        n = todo.pop()
        if n in seen:
            continue
        seen.add(n)
        todo.extend(nodes.get(n, {}).get("supported_by", []))
    return seen


def check(tm_text, case):
    p = []
    tm = parse_threat_model(tm_text)
    nodes = {n["id"]: n for n in case["nodes"]}
    goals = {i for i, n in nodes.items() if n["kind"] == "goal"}
    case_assumptions = {i for i, n in nodes.items() if n["kind"] == "assumption"}
    case_gaps = {i for i, n in nodes.items() if n["kind"] == "context" and RE_GAP.fullmatch(i)}
    excluded = set(RE_EXCL.findall(" ".join(case["claim_scope"]["excludes"])))

    if not tm["threats"]:
        return ["threat model: no TM- rows found"]
    for d in tm["duplicates"]:
        p.append(f"{d}: identifier used twice")
    used = {"A": set(), "EXCL": set(), "GAP": set()}
    for tid, t in sorted(tm["threats"].items()):
        for adv in re.findall(r"ADV-\d+", t["adversary"]) or ([] if t["adversary"] == "—" else [None]):
            if adv is None:
                p.append(f"{tid}: adversary '{t['adversary']}' names no ADV- and is not a dash")
            elif adv not in tm["adversaries"]:
                p.append(f"{tid}: adversary {adv} is not defined in section 4")
        for asset in re.findall(r"AS-\d+", t["asset"]) or ([] if t["asset"] == "—" else [None]):
            if asset is None:
                p.append(f"{tid}: asset '{t['asset']}' names no AS- and is not a dash")
            elif asset not in tm["assets"]:
                p.append(f"{tid}: asset {asset} is not defined in section 3")
        if not t["source"]:
            p.append(f"{tid}: no source")
        disp = t["disposition"]
        names = (RE_GOAL.findall(disp), RE_ASSUME.findall(disp), RE_EXCL.findall(disp), RE_GAP.findall(disp))
        if not any(names):
            p.append(f"{tid}: disposition names no goal, assumption, exclusion or gap")
        for g in names[0]:
            if g not in goals:
                p.append(f"{tid}: disposition names {g}, which is not a goal of the case")
        for a in names[1]:
            used["A"].add(a)
            if a not in case_assumptions:
                p.append(f"{tid}: disposition names {a}, which is not an assumption of the case")
        for e in names[2]:
            used["EXCL"].add(e)
            if e not in tm["exclusions"]:
                p.append(f"{tid}: disposition names {e}, which section 7 does not define")
            elif e not in excluded:
                p.append(f"{tid}: {e} is not among the case's claim_scope excludes")
        for g in names[3]:
            used["GAP"].add(g)
            if g not in tm["gaps"]:
                p.append(f"{tid}: disposition names {g}, which section 8 does not define")
            elif g not in case_gaps:
                p.append(f"{tid}: {g} has no context node in the case")

    for nid, n in sorted(nodes.items()):
        if n["kind"] not in ("goal", "assumption") and nid not in case_gaps:
            continue
        accept = descendants(nodes, nid) if n["kind"] == "goal" else {nid}
        for num in sorted(cited_threats(n.get("text", ""))):
            tid = f"TM-{num:03d}"
            if tid not in tm["threats"]:
                p.append(f"{nid}: cites {tid}, which the threat model does not define")
                continue
            disp = tm["threats"][tid]["disposition"]
            named = set(RE_GOAL.findall(disp)) | set(RE_ASSUME.findall(disp)) | set(RE_GAP.findall(disp))
            if not named & accept:
                p.append(f"{nid}: cites {tid}, whose disposition ({disp}) names neither {nid} nor a sub-goal of it")

    for a in sorted(tm["assumptions"] - used["A"]):
        p.append(f"{a}: an assumption no threat is dispositioned to")
    for g in sorted(tm["gaps"] - used["GAP"]):
        p.append(f"{g}: a gap no threat is dispositioned to")
    for a in sorted(case_assumptions - tm["assumptions"]):
        p.append(f"{a}: an assumption of the case that the threat model's register does not list")
    for g in sorted(case_gaps - tm["gaps"]):
        p.append(f"{g}: a gap node of the case that section 8 does not define")
    return p


SELF_TM = """
| `A-n` an assumption of the case, carried in its register: A-1 one thing |
| AS-1 | weights | yes | yes | note |
| ADV-1 | tenant | x | y | src |
| TM-001 | ADV-1 | AS-1 | E | a threat | src | G-x1 |
| TM-002 | ADV-1 | AS-1 | I | a threat | src | A-1 |
| TM-003 | —     | —    | — | a threat | src | EXCL-1; GAP-1 |
| EXCL-1 | thing | why | src |
| GAP-1 | gap | TM-003 | owner |
"""
SELF_CASE = {
    "claim_scope": {"covers": ["x"], "excludes": ["thing (EXCL-1)"]},
    "nodes": [
        {"id": "G0", "kind": "goal", "text": "root", "supported_by": ["G-x"]},
        {"id": "G-x", "kind": "goal", "text": "layer", "supported_by": ["G-x1"]},
        {"id": "G-x1", "kind": "goal", "text": "leaf (threat TM-001)", "undeveloped": "reason"},
        {"id": "A-1", "kind": "assumption", "status": "open", "text": "one thing (TM-002)"},
        {"id": "GAP-1", "kind": "context", "text": "gap (TM-003)"},
    ],
}


def selftest():
    import copy
    ok = []

    def expect(name, tm_text, case, want):
        got = check(tm_text, case)
        hit = any(want in x for x in got) if want else not got
        ok.append(hit)
        print(f"  {'PASS' if hit else 'FAIL'}  {name}" + ("" if hit else f": {got}"))

    expect("consistent pair passes", SELF_TM, SELF_CASE, None)
    expect("layer goal cited by a leaf's threat is accepted", SELF_TM,
           {**SELF_CASE, "nodes": SELF_CASE["nodes"][:1] + [{**SELF_CASE["nodes"][1], "text": "layer (TM-001)"}] + SELF_CASE["nodes"][2:]}, None)
    expect("unknown goal", SELF_TM.replace("| G-x1 |", "| G-x9 |"), SELF_CASE, "G-x9, which is not a goal")
    expect("duplicate identifier", SELF_TM + "| TM-001 | ADV-1 | AS-1 | E | again | src | G-x1 |\n", SELF_CASE, "used twice")
    expect("undefined adversary", SELF_TM.replace("| TM-001 | ADV-1", "| TM-001 | ADV-7"), SELF_CASE, "ADV-7 is not defined")
    expect("undefined asset", SELF_TM.replace("| TM-001 | ADV-1 | AS-1", "| TM-001 | ADV-1 | AS-4"), SELF_CASE, "AS-4 is not defined")
    expect("empty disposition", SELF_TM.replace("| G-x1 |", "| see #4 |"), SELF_CASE, "names no goal")
    c = copy.deepcopy(SELF_CASE); c["claim_scope"]["excludes"] = ["nothing"]
    expect("exclusion missing from scope", SELF_TM, c, "not among the case's claim_scope excludes")
    c = copy.deepcopy(SELF_CASE); c["nodes"] = [n for n in c["nodes"] if n["id"] != "GAP-1"]
    expect("gap without a context node", SELF_TM, c, "no context node")
    c = copy.deepcopy(SELF_CASE); c["nodes"][2]["text"] = "leaf (TM-002)"
    expect("goal cites a threat sent elsewhere", SELF_TM, c, "names neither G-x1")
    c = copy.deepcopy(SELF_CASE); c["nodes"][2]["text"] = "leaf (TM-001 to TM-003)"
    expect("range citation expanded", SELF_TM, c, "cites TM-002")
    c = copy.deepcopy(SELF_CASE); c["nodes"][2]["text"] = "leaf (TM-099)"
    expect("goal cites an undefined threat", SELF_TM, c, "does not define")
    expect("unused gap", SELF_TM.replace("| EXCL-1; GAP-1 |", "| EXCL-1 |"), SELF_CASE, "GAP-1: a gap no threat")
    expect("unused assumption", SELF_TM.replace("| A-1 |", "| G-x1 |"), {**SELF_CASE, "nodes": [n for n in SELF_CASE["nodes"] if n["id"] != "A-1"]}, "A-1: an assumption no threat")
    c = copy.deepcopy(SELF_CASE); c["nodes"].append({"id": "A-2", "kind": "assumption", "status": "open", "text": "x"})
    expect("case assumption absent from the register", SELF_TM, c, "A-2: an assumption of the case")
    print(f"selftest: {sum(ok)}/{len(ok)} cases behaved")
    return 0 if all(ok) else 1


def main():
    ap = argparse.ArgumentParser(description="Check the threat model and the assurance case against each other.")
    ap.add_argument("--threat-model", default=TM_DEFAULT)
    ap.add_argument("--case", default=CASE_DEFAULT)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    try:
        tm_text = pathlib.Path(a.threat_model).read_text(encoding="utf-8")
        case = json.loads(pathlib.Path(a.case).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"check-threat-model: {e}", file=sys.stderr)
        return 2
    problems = check(tm_text, case)
    for x in problems:
        print(f"  RED {x}")
    n = len(parse_threat_model(tm_text)["threats"])
    print(f"check-threat-model: {n} threats against {len(case['nodes'])} case nodes: "
          + ("OK" if not problems else f"FAIL ({len(problems)} findings)"))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
