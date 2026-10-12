#!/usr/bin/env python3
"""replay-evidence.py -- re-derive the evidence an assurance case cites.

DRAFT (#53 B5).  Every evidence node in an AIVHAI assurance case carries the
command that re-derives it (`evidence.rerun`).  This script runs those
commands, each in a fresh checkout of the repository and commit it names, so
that anyone (the red team first of all) can replay every proof without
assembling anything by hand.

    replay-evidence.py list [DIR ...]
        Print every evidence node: case, node, artifact, where it runs, and
        its command.  No network, no execution.

    replay-evidence.py run [DIR ...] [--case NAME] [--node ID]
                           [--release-json PATH | --provers IMAGE]
                           [--work DIR] [--keep] [--dry-run]
        Replay the selected nodes.  For each one: clone the workdir
        repository, check out its pinned commit, run `rerun` with bash in that
        checkout, and record the exit status, duration, and a log.  Writes
        `replay.json` in the work directory.  Exit 1 if any replay fails.

DIR defaults to docs/red-team/assurance-case and specs/assurance (those that
exist).

Conventions the cases follow (docs/red-team/assurance-case/README.md):
  * `evidence.artifact` is `owner/repo@<40-hex>[:path]`, or `PENDING`
    (skipped, and reported).
  * `evidence.workdir`, optional, is `owner/repo@<40-hex>`: where `rerun`
    runs.  It defaults to the artifact's repository and commit.  It exists
    because a recorded log lives in one repository while the command that
    regenerates it runs in another.
  * `rerun` runs with the checkout as its working directory, and may use
    `$AIVHAI_PROVERS`, which this script sets from RELEASE.json's
    pins.images["aivhai-provers"] or from --provers.

Not yet done (this is a draft): comparing a replay's output with the
recorded artifact, pinning the clone's submodules, and running inside the
CI image.  Today a replay succeeds when its command exits 0.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

DEFAULT_DIRS = ["docs/red-team/assurance-case", "specs/assurance"]
PIN_RE = re.compile(r"^(?P<repo>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)@(?P<sha>[0-9a-f]{40})(:(?P<path>\S+))?$")


def evidence_nodes(dirs):
    out = []
    for d in dirs:
        for f in sorted({p for g in ("*-case.json", "*.case.json") for p in Path(d).glob(g)}):
            case = json.loads(f.read_text())
            for n in case.get("nodes", []):
                if n.get("kind") != "solution":
                    continue
                ev = n.get("evidence") or {}
                artifact = ev.get("artifact", "")
                workdir = ev.get("workdir")
                if not workdir:
                    m = PIN_RE.match(artifact)
                    workdir = f"{m['repo']}@{m['sha']}" if m else None
                out.append({"case": case.get("case", f.stem), "node": n["id"], "file": str(f),
                            "artifact": artifact, "workdir": workdir, "rerun": ev.get("rerun", "")})
    return out


def provers_from(release_json):
    r = json.loads(Path(release_json).read_text())
    return r.get("pins", {}).get("images", {}).get("aivhai-provers")


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def checkout(workdir, into):
    m = PIN_RE.match(workdir or "")
    if not m:
        raise ValueError(f"workdir {workdir!r} is not owner/repo@<40-hex>")
    url = f"https://github.com/{m['repo']}.git"
    for step in (["git", "init", "-q", str(into)],
                 ["git", "-C", str(into), "remote", "add", "origin", url],
                 ["git", "-C", str(into), "fetch", "-q", "--depth", "1", "origin", m["sha"]],
                 ["git", "-C", str(into), "checkout", "-q", "FETCH_HEAD"]):
        r = run(step)
        if r.returncode != 0:
            raise RuntimeError(f"{' '.join(step)}: {r.stderr.strip()}")


def cmd_list(args):
    nodes = evidence_nodes(args.dirs)
    for n in nodes:
        state = "PENDING" if n["artifact"] == "PENDING" else "pinned"
        print(f"{n['case']}  {n['node']}  [{state}]")
        print(f"    artifact: {n['artifact']}")
        print(f"    runs in:  {n['workdir'] or '(no pinned workdir)'}")
        print(f"    rerun:    {n['rerun']}")
    print(f"{len(nodes)} evidence node(s) in {', '.join(args.dirs)}")
    return 0


def cmd_run(args):
    nodes = [n for n in evidence_nodes(args.dirs)
             if (not args.case or n["case"] == args.case) and (not args.node or n["node"] == args.node)]
    provers = args.provers or (provers_from(args.release_json) if args.release_json else None)
    env = dict(os.environ)
    if provers:
        env["AIVHAI_PROVERS"] = provers
    work = Path(args.work or tempfile.mkdtemp(prefix="aivhai-replay-"))
    work.mkdir(parents=True, exist_ok=True)
    results, failed = [], 0
    for n in nodes:
        tag = f"{n['case']}/{n['node']}"
        rec = {"case": n["case"], "node": n["node"], "artifact": n["artifact"],
               "workdir": n["workdir"], "rerun": n["rerun"]}
        if n["artifact"] == "PENDING":
            rec["status"] = "skipped: evidence PENDING"
        elif not n["workdir"]:
            rec["status"] = "skipped: no pinned workdir"
        elif "$AIVHAI_PROVERS" in n["rerun"] and not provers:
            rec["status"] = "skipped: needs --release-json or --provers for $AIVHAI_PROVERS"
        elif args.dry_run:
            rec["status"] = "dry run"
            print(f"would run {tag} in {n['workdir']}:\n    {n['rerun']}")
        else:
            d = work / f"{n['case']}-{n['node']}"
            shutil.rmtree(d, ignore_errors=True)
            log = work / f"{n['case']}-{n['node']}.log"
            t0 = time.time()
            try:
                checkout(n["workdir"], d)
                r = subprocess.run(["bash", "-c", n["rerun"]], cwd=d, env=env,
                                   stdout=open(log, "w"), stderr=subprocess.STDOUT)
                rec["exit"] = r.returncode
                rec["status"] = "ok" if r.returncode == 0 else "FAILED"
            except Exception as e:  # checkout or launch failure is a failed replay
                rec["status"], rec["error"] = "FAILED", str(e)
            rec["seconds"] = round(time.time() - t0, 1)
            rec["log"] = str(log)
            if not args.keep:
                shutil.rmtree(d, ignore_errors=True)
        failed += rec["status"] == "FAILED"
        results.append(rec)
        print(f"{rec['status']:<10} {tag}")
    (work / "replay.json").write_text(json.dumps(
        {"provers": provers, "dirs": args.dirs, "results": results}, indent=2) + "\n")
    print(f"{len(results)} node(s); {failed} failed; record in {work / 'replay.json'}")
    return 1 if failed else 0


def main(argv):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("list", "run"):
        s = sub.add_parser(name)
        s.add_argument("dirs", nargs="*")
        if name == "run":
            s.add_argument("--case")
            s.add_argument("--node")
            g = s.add_mutually_exclusive_group()
            g.add_argument("--release-json", help="take $AIVHAI_PROVERS from a release manifest")
            g.add_argument("--provers", help="the aivhai-provers image reference, by digest")
            s.add_argument("--work", help="work directory (default: a new temporary one)")
            s.add_argument("--keep", action="store_true", help="keep each checkout after its replay")
            s.add_argument("--dry-run", action="store_true")
    args = p.parse_args(argv)
    args.dirs = args.dirs or [d for d in DEFAULT_DIRS if Path(d).is_dir()]
    return {"list": cmd_list, "run": cmd_run}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
