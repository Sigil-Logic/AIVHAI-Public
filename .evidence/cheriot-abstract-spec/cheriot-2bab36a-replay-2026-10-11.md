# Evidence — the CHERIoT case's evidence replayed end to end at `2bab36a`

**Status**: Frozen snapshot  
**Version**: 1.0.0  
**Date**: 2026-10-11  
**Project**: AIVHAI  
**Issue**: [#210](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/210), [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

`scripts/release/replay-evidence.py run` over every evidence node of the Sprint 1 release, as the red team would run it.  Each node is checked out fresh at the commit it pins, and its `rerun` command is run there.  The release's three evidence nodes are E1, E2 and E3 of the CHERIoT case, all against the hand-off commit `Sigil-Logic/cheriot-abstract-spec@2bab36ad8c0bd25765d0f2dba1e12654abd4157f`.  The run used the merged Sprint 1 tree (#239, #220, #231, #237, #246 and #256 merged in landing order), with the image the case's E2 and E3 were recorded in:

`ghcr.io/sigil-logic/aivhai-provers@sha256:baf1d248d3e30da5cb18809e4095723b52eefcf825882bb0bfcbf4a3ec634cd7`

It ran on an arm64 laptop under Docker Desktop, with the amd64 image under emulation (`DOCKER_DEFAULT_PLATFORM=linux/amd64`), not on fm.  FM has podman only, and the replayer's commands call `docker`.  That it ran there at all is evidence that the recipe needs nothing but Docker and the pinned image.

| Node | Command (as recorded in the case)                               | Exit | Status | Seconds |
|------|-----------------------------------------------------------------|------|--------|---------|
| E1   | `sed -n '2531,2880p' src/Properties.v…`                         | 0    | ok     | 0.6     |
| E2   | `docker run --rm -v "$PWD":/work -w /work "$AIVHAI_PROVERS" b…` | 0    | ok     | 6.7     |
| E3   | `docker run --rm -v "$PWD":/work -w /work "$AIVHAI_PROVERS" b…` | 0    | ok     | 4.6     |

**3 nodes; 0 failed.**  The E2 log ends `Closed under the global context`.  The E3 log compiles all five source files, with only the known non-primitive-record warning at `Properties.v` line 986.  The record [`cheriot-2bab36a-replay.json`](cheriot-2bab36a-replay.json) is the replayer's own output, with local paths replaced by `<work>`, and the three logs beside it are verbatim.

```bash
AIVHAI_PROVERS=ghcr.io/sigil-logic/aivhai-provers@sha256:baf1d248d3e30da5cb18809e4095723b52eefcf825882bb0bfcbf4a3ec634cd7
DOCKER_DEFAULT_PLATFORM=linux/amd64 python3 scripts/release/replay-evidence.py run --provers "$AIVHAI_PROVERS" --work <work>
```

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
