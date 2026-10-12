# The Coral NPU Image

**Status**: Living document  
**Version**: 0.1.0  
**Date**: 2026-09-22  
**Project**: AIVHAI  
**Issue**: [#67](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/67)  

---

**There is no `Dockerfile` in this directory, and that is the design.**

[PLAT-D30](../../../specs/platform/decisions.md) settles that the Coral NPU toolchain is its own image, on the servers, **built from the Dockerfiles the corpus already carries** rather than from ones we author.  Copying Google's definitions here would create a second copy to drift — the failure this whole programme keeps paying for elsewhere — so `build.sh coral` builds them where they live, in `AIVHAI-Everything` at its pinned commits.

## The two definitions

| Definition                                                                               | Produces                                |
|------------------------------------------------------------------------------------------|-----------------------------------------|
| `Hardware/Google/coralnpu/utils/coralnpu.dockerfile`                                     | the Bazel environment, on Debian trixie |
| `Hardware/Google/coralnpu/toolchain/build_scripts/toolchain_rockylinux_image.dockerfile` | the toolchain image, on Rocky Linux 8.4 |

Both were verified present on 2026-09-22.

## Why this is not a layer

Its chain — Bazel 7.4.1, Scala 2.13.18, a JVM, `llvm-firtool` 1.114.0, cocotb, MPACT-RISCV, and a **patched** Verilator through `rules_hdl` — shares nothing with the Galois or Sail chains.  The four tool layers exist so the three hosts share what they have in common; a set intersecting none of them gains nothing from being a layer and would impose its size on every image taking the base.

It is also built on Debian and Rocky Linux rather than our Ubuntu 22.04.  That is a consequence of reusing Google's definitions, and is accepted rather than fought — which is only tolerable *because* it is a separate image.

## Usage

```bash
AIVHAI_EVERYTHING=~/Sandboxes/SigilLogic/AIVHAI-Everything \
  infra/containers/build.sh coral
```

The corpus path is a parameter rather than a guess: this image is the one thing in the set whose build context is not in this repository.

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
