# Prior Engagements and Exemplars

**Status**: Living document  
**Version**: 0.1.0  
**Date**: 2026-10-09  
**Project**: AIVHAI  
**Issue**: [#53](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/53)  

---

Two earlier engagements shaped what Sigil Logic offers the red team, and both were mentioned at the introductory call on 2026-09-17.  This page gives the pointers, says what each is an example *of*, and says where each comparison stops holding, so that neither is read as a claim about AIVHAI.

## FETT: what a red team was given last time

The DARPA SSITH program's *Finding Exploits to Thwart Tampering* (FETT) bug bounty, in 2020, put RISC-V processors with hardware security features in front of external researchers.  Galois ran it for DARPA, with Sigil Logic's PI, Joe Kiniry, among those who ran it.  The researcher-facing site, `fett.securehardware.org`, no longer resolves, but the materials were released as open source and remain public:

| What                                                                                                   | Where                                                                                                                                |
|--------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| Bug-bounty documentation, build instructions, and the target-system design (in Lando) — **start here** | [`GaloisInc/BESSPIN-Tool-Suite/docs/bugBounty2020/`](https://github.com/GaloisInc/BESSPIN-Tool-Suite/tree/master/docs/bugBounty2020) |
| The researcher portal, including its *Learn* section                                                   | [`GaloisInc/BESSPIN-FETT-Portal`](https://github.com/GaloisInc/BESSPIN-FETT-Portal)                                                  |
| The administration portal                                                                              | [`GaloisInc/BESSPIN-FETT-Admin-Portal`](https://github.com/GaloisInc/BESSPIN-FETT-Admin-Portal)                                      |
| The AWS environment and its CloudFormation templates                                                   | [`GaloisInc/BESSPIN-FETT-Portal-AWS-Environment`](https://github.com/GaloisInc/BESSPIN-FETT-Portal-AWS-Environment)                  |
| The instance-lifecycle service                                                                         | [`GaloisInc/BESSPIN-FETT-AWSHelperService`](https://github.com/GaloisInc/BESSPIN-FETT-AWSHelperService)                              |
| An index of everything BESSPIN released                                                                | [`GaloisInc/BESSPIN`](https://github.com/GaloisInc/BESSPIN)                                                                          |
| The program's public page                                                                              | [fett.darpa.mil](https://fett.darpa.mil/)                                                                                            |

The written account is D. M. Zimmerman, J. R. Kiniry, R. N. Tadros, and D. Hand, *"FETT: Deploying RISC-V Systems-on-Chip to the Cloud for Security Research,"* GOMACTech 2021.

**What it is an example of.**  The standard of provision: researchers got all designs, all code, all containers, and all tools.  They also got a direct means of injecting malicious software and the precise locations of the secrets and critical software to target.  The `bugBounty2020` documentation is the operational record of how targets were provisioned and checked before being handed over.  That is the shape of the remote FPGA access this project plans for around month 14.

**Where the comparison stops.**  FETT was a bug bounty over finished hardware running real software.  AIVHAI, for most of its life, is a proof program over executable formal models, with no hardware to attack.  FETT's injection path does not translate directly; what does is described as an open item in [`known-gaps.md`](known-gaps.md).

## VoteSecure: a structured threat model and assurance case

VoteSecure is an end-to-end verifiable cryptographic voting SDK by Free & Fair, built with the same methodology Sigil Logic applies here.  It has a complete Tamarin model and a partial Cryptol model of its protocol.

| What                                                                                                                                                | Where                                                                                                         |
|-----------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| Release with the threat model as a flat hyperlinked PDF and a self-contained interactive HTML application (`threat-model.pdf`, `threat-model.html`) | [VoteSecure v1.4](https://github.com/FreeAndFair/VoteSecure/releases/tag/v1_4)                                |
| The assurance case: an AdvoCATE project, with its skeleton generated from the models by script                                                      | [`FreeAndFair/VoteSecure/assurance/`](https://github.com/FreeAndFair/VoteSecure/tree/main/assurance)          |
| The CI workflows that validate both on every change                                                                                                 | `test-validity-of-threat-model.yml` and `test-validity-of-assurance-case-skeleton.yml` in the same repository |

**What it is an example of.**  Three things carry over:

- The threat model is delivered in two forms, because how it is read matters as much as how it is written.
- The assurance case is generated from models, not drawn by hand.
- Both are checked mechanically in CI, which is what makes "structured and traceable" more than a description.

The AIVHAI cases follow the second and third practices with a lighter, tool-neutral format; see [`assurance-case/README.md`](assurance-case/README.md).

**Where the comparison stops.**  VoteSecure is an election-system software SDK, and its threat model is about voters, officials, and networks.  AIVHAI is a CHERI system-on-chip, and its threats are tenants attempting to escape their compartments.  The form transfers; the content does not.  VoteSecure also uses AdvoCATE; AIVHAI does not, and keeps its cases in plain structured GSN instead (see [`assurance-case/README.md`](assurance-case/README.md)).

## Capabilities Limited's materials

Capabilities Limited has run its own red-team exercises, including a DARPA crowdsourced exercise over CHERI.  Robert Watson has offered open-source red-team training material.  Both descend from the same DARPA lineage as FETT, so a single reading list is better than two.  Their pointers will be added here once Capabilities Limited shares them, together with the CHERI papers and technical reports the red team is likely to read; most are already in the project bibliography ([`../bibliography.md`](../bibliography.md)).

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
