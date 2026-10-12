# AIVHAI Bibliography

**Status**: Living document  
**Version**: 1.5.0  
**Date**: 2026-10-09  
**Project**: AIVHAI  
**Issue**: [#119](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/119)  

---

Every document this project cites is listed here, once.  Specifications, proofs, models, and issues cite an entry by its key, and [`bibliography.bib`](bibliography.bib) is generated from this file so that LaTeX documents can use the same entries.

This file has two halves.  The first says how the bibliography works: how to cite, how keys and files are named, and what each field means.  The second, [Register](#register), is the entries themselves.  Most of the rules in the first half are enforced by [`scripts/bibliography.py`](../scripts/bibliography.py), which runs in `make check` and in CI.  Two are left to review: that a collision suffix (`-19a`, `-19b`) is assigned correctly, and that a `why` sentence names the issue that needs the entry.

## How to cite

Write the key in square brackets with an `@`, as pandoc does:

| Where                    | How                                                                   |
|--------------------------|-----------------------------------------------------------------------|
| Markdown                 | `[@BauereissCampbellSewellEtAl-22]`                                   |
| Several at once          | `[@NienhuisJoannouBauereissEtAl-20; @HammondAlmeidaBauereissEtAl-25]` |
| With a location          | `[@BauereissCampbellSewellEtAl-22, sec. 4]`                           |
| Sail, SystemVerilog, BSV | `// [@ArmstrongBauereissCampbellEtAl-25]` or `/* ... */`              |
| Rocq                     | `(* [@HammondAlmeidaBauereissEtAl-25] *)`                             |
| Cryptol                  | `// [@RISCVInternational-26b]`                                        |

**From a NINJA semantic property.**  An `@see` annotation may point at a paper in the bibliography.  Write the key bracketed, `@see [@BauereissCampbellSewellEtAl-22]`, in a Markdown document or in a Sail, Rocq, SystemVerilog, BSV, or Cryptol comment, so that the gate checks it resolves.  A bare `@see BauereissCampbellSewellEtAl-22` is not checked.

Only bracketed citations are supported.  A bare `@key` is not a citation here, though pandoc would read it as one, because a bare `@` is NINJA's semantic-property syntax (`@req`, `@design`) and is used throughout the repository.  The gate checks the bracketed citations it finds in Markdown, Sail, Rocq, Verilog and SystemVerilog, BSV, Cryptol, LaTeX, Lean, and AsciiDoc files, and fails if a key has no entry.  It approximates pandoc's rules: in Markdown, text in fenced code blocks, code spans, HTML comments, and display math is not cited, a bracket, backtick, or `$$` after an odd number of backslashes is escaped, a citation group may contain nested brackets, and it may run across a line break within its paragraph.  It does not recognise indented code blocks, so a citation-like string in one is still checked.  It does not look at shell scripts, so Bash's `"${a[@]}"` is never mistaken for a citation.

**Citations are checked, not yet rendered.**  Turning a citation into a formatted reference with `pandoc --citeproc` waits for the documentation conventions to be set in the process and methodology work under [#51](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/51).  The syntax was chosen so that nothing will need rewriting when it arrives.

## How to add an entry

1. Work out the key (next section).
2. Add the entry under [Register](#register), in alphabetical order of key (the gate enforces the order), with every required field.  The example below shows the shape.
3. If there is a PDF, put it at `docs/bib/<key>.pdf`.  Git LFS stores it automatically, because of `.gitattributes`; run `git lfs install` once per clone first.  Then run `scripts/bibliography.py transliterate <key>` to write `docs/bib/<key>.md`, and list both files in the entry's `fulltext` field.
4. Run `make bib` to regenerate `bibliography.bib`.
5. If the entry is `redistribute: no`, run `scripts/bibliography.py audit-table` to update the pre-public audit's table.
6. Run `make check`, which runs `scripts/bibliography.py check` among the other gates.  Commit the register, the `.bib`, the audit if it changed, and any files under `docs/bib/` together.

A minimal entry, for a PDF that may be republished:

```markdown
### SmithJones-24

- **type**: article
- **author**: Ann Smith and Bo Jones
- **title**: A Paper About Capabilities
- **journal**: Some Journal
- **year**: 2024
- **doi**: 10.1234/example
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (stated on the first page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/SmithJones-24.pdf, docs/bib/SmithJones-24.md
- **pinned**: doi:10.1234/example
- **why**: One sentence on what AIVHAI uses it for, naming the issue that needs it (#4).
```

## Keys and file names

The key and the full-text file name are the same string, and both come from the document's authors and year:

`<Author1><Author2><Author3>[EtAl]-<YY>`

- **Surnames only**, in the order printed on the document, at most three.  With more than three authors, the first three are followed by `EtAl`.
- **`YY`** is the two-digit year of publication, and is always present.  For a living document, it is the year of the version that was read.
- **Surnames are written in CamelCase**, with accents removed and spaces, hyphens, and apostrophes dropped: `van der Maas` becomes `VanDerMaas`.  To keep a multi-word surname together, write the author as `van der Maas, Marno`.
- **An organization** with no named authors is written in braces in the `author` field, `{RISC-V International}`, and becomes `RISCVInternational` in the key.
- **Two documents with the same key** take a lowercase letter after the year: `-19a`, `-19b`.

So the paper by Hammond, Almeida, Bauereiss, Campbell, Stark, and Sewell from 2025 is `HammondAlmeidaBauereissEtAl-25`, and its full text is `docs/bib/HammondAlmeidaBauereissEtAl-25.pdf`.  The gate derives the key from the `author` and `year` fields and fails if they disagree.

## Fields

Each entry is a level-3 heading holding its key, followed by one `- **field**: value` line per field.

**BibTeX fields** are copied into `bibliography.bib`.  Use the ones that apply: `author`, `editor`, `title`, `journal`, `booktitle`, `series`, `volume`, `number`, `pages`, `publisher`, `institution`, `school`, `organization`, `edition`, `version`, `howpublished`, `month`, `year`, `doi`, `url`.  Separate authors with ` and `.  Write `doi` bare, without `https://doi.org/`.  An entry needs a `doi`, a `url`, or both.

**Register fields** say what the entry is to this project.  They are all required, and they stay in this file:

| Field          | Values                                                                                          | Meaning                                                                                                  |
|----------------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| `type`         | `article`, `inproceedings`, `incollection`, `techreport`, `phdthesis`, `manual`, `book`, `misc` | The BibTeX entry type                                                                                    |
| `status`       | `published`, `ratified`, `frozen`, `draft`, `under-development`, `living`                       | The document's lifecycle state                                                                           |
| `observed`     | a date, `YYYY-MM-DD`                                                                            | When `status` was last checked.  A status without a date is not a fact                                   |
| `licence`      | free text                                                                                       | The licence or copyright position, read from the document or its repository, never from an API           |
| `redistribute` | `yes`, `no`                                                                                     | Whether the full text, and a transliteration of it, may be published openly.  See below                  |
| `ip-class`     | `background`, `foreground`                                                                      | Whether the document predates this project or is created by it ([SL-AIVHAI-P02](../specs/ai/project.md)) |
| `access`       | `public`, `paywalled`, `consortium-only`                                                        | Whether a reader outside the consortium can obtain it                                                    |
| `fulltext`     | `none`, or the paths of the files under `docs/bib/`                                             | The committed full text and its transliteration                                                          |
| `pinned`       | free text                                                                                       | What fixes the exact text cited: a DOI, a report number, a release tag, or a commit                      |
| `why`          | one sentence                                                                                    | Why AIVHAI cites it, naming the issue that needs it                                                      |

**A document that is still changing** (`draft`, `under-development`, or `living`) must also give a `version`, so that a citation names the text that was actually read and not whatever the URL serves today.

## Full texts, transliterations, and publication

Full texts live in [`docs/bib/`](bib/), stored with Git LFS so the repository stays small to clone.  Continuous integration checks the LFS pointers and never downloads the PDFs.

**Every PDF has a Markdown transliteration beside it**, with the same name and a `.md` extension.  It is machine-made and unedited, and it exists so that people and agents can search and read the text.  It loses figures, and it may garble mathematics, tables, and multi-column layout.  Its header names the PDF it came from, and the PDF is authoritative wherever the two disagree.  A web document with no PDF may keep a Markdown snapshot under the same rule.

**This repository is headed for open release, and most of these documents are not ours.**  That is what `redistribute` is for:

- `yes` means the licence plainly permits republishing the full text: CC-BY, CC-BY-SA, CC0, or a BSD, MIT, or Apache licence on the source.
- `no` means it does not, or that it could not be established.  Publisher copyright is `no`, even when the paper is free to download.

A transliteration is a derivative of its PDF and always takes the PDF's verdict.  **The public mirror ([#51](https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/51) D1) must leave out every file of a `redistribute: no` entry**, and the pre-public audit checks it ([`pre-public-audit.md`](pre-public-audit.md) B-2).  Citing a document is always allowed; republishing it is what the verdict governs.

The shared Drive folder `AIVHAI/Bibliography` was the planned home for full texts, and is superseded by `docs/bib/`.

## Register

### AirdAlmataryAmayaGarciaEtAl-25

- **type**: manual
- **author**: Thomas Aird and Hesham Almatary and Amaya Garcia, Andres and John Baldwin and Paul Buxton and David Chisnall and Jessica Clarke and Brooks Davis and Nathaniel Wesley Filardo and Franz A. Fuchs and Timothy Hutt and Alexandre Joannou and Martin Kaiser and Tariq Kurd and Ben Laurie and van der Maas, Marno and Maja Malenko and A. Theodore Markettos and David McKay and Jamie Melling and Stuart Menefy and Simon W. Moore and Peter G. Neumann and Robert Norton and Alexander Richardson and Michael Roe and Peter Rugg and Peter Sewell and Carl Shaw and Ricki Tura and Robert N. M. Watson and Toby Wenman and Jonathan Woodruff and Jason Zhijingcheng Yu
- **title**: RISC-V Specification for CHERI Extensions
- **organization**: RISC-V International
- **version**: 0.9.3 (2025-01-16, Development state)
- **month**: jan
- **year**: 2025
- **url**: https://github.com/riscv/riscv-cheri/releases/tag/v0.9.3-prerelease
- **status**: under-development
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, copyright 2024 RISC-V International (the specification's "Copyright and license information" page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/AirdAlmataryAmayaGarciaEtAl-25.pdf, docs/bib/AirdAlmataryAmayaGarciaEtAl-25.md
- **pinned**: release tag v0.9.3-prerelease (commit 0a391091b9db)
- **why**: The CHERI RISC-V version that Capabilities Limited's `sail-cheri-riscv` branch `cva6-zcheri-compare` models, and so the starting point of the Sail work in #3; the attribution rests on instruction naming, since the branch states no version.

### AirdAlmataryAmayaGarciaEtAl-26a

- **type**: manual
- **author**: Thomas Aird and Hesham Almatary and Amaya Garcia, Andres and John Baldwin and Paul Buxton and David Chisnall and Jessica Clarke and Brooks Davis and Nathaniel Wesley Filardo and Franz A. Fuchs and Timothy Hutt and Alexandre Joannou and Martin Kaiser and Tariq Kurd and Ben Laurie and van der Maas, Marno and Maja Malenko and A. Theodore Markettos and David McKay and Jamie Melling and Stuart Menefy and Simon W. Moore and Peter G. Neumann and Robert Norton and Alexander Richardson and Michael Roe and Peter Rugg and Peter Sewell and Carl Shaw and Ricki Tura and Robert N. M. Watson and Toby Wenman and Jonathan Woodruff and Jason Zhijingcheng Yu and Robert Riglar and Florian Schmaus
- **title**: RISC-V Specification for CHERI Extensions
- **organization**: RISC-V International
- **version**: 0.9.9 (intermediate release 20260810, Stable state)
- **month**: aug
- **year**: 2026
- **url**: https://github.com/riscv/riscv-cheri/releases/tag/v0.9.9-ar20260810
- **status**: draft
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, copyright 2026 RISC-V International (the specification's "Copyright and license information" page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/AirdAlmataryAmayaGarciaEtAl-26a.pdf, docs/bib/AirdAlmataryAmayaGarciaEtAl-26a.md
- **pinned**: release tag v0.9.9-ar20260810 (commit 85b52d3e3ca6)
- **why**: The RVY version, with Y-prefixed instructions, that the `0.9.9-upgrade` Sail branch targets, and that #3 and #52 C3 align the model with.

### AirdAlmataryAmayaGarciaEtAl-26b

- **type**: manual
- **author**: Thomas Aird and Hesham Almatary and Amaya Garcia, Andres and John Baldwin and Paul Buxton and David Chisnall and Jessica Clarke and Brooks Davis and Nathaniel Wesley Filardo and Franz A. Fuchs and Timothy Hutt and Alexandre Joannou and Martin Kaiser and Tariq Kurd and Ben Laurie and van der Maas, Marno and Maja Malenko and A. Theodore Markettos and David McKay and Jamie Melling and Stuart Menefy and Simon W. Moore and Peter G. Neumann and Robert Norton and Alexander Richardson and Michael Roe and Peter Rugg and Peter Sewell and Carl Shaw and Ricki Tura and Robert N. M. Watson and Toby Wenman and Jonathan Woodruff and Jason Zhijingcheng Yu and Robert Riglar and Florian Schmaus
- **title**: RISC-V Specification for CHERI Extensions
- **organization**: RISC-V International
- **version**: 0.9.10 (intermediate release 20260929, Stable state)
- **month**: sep
- **year**: 2026
- **url**: https://github.com/riscv/riscv-cheri/releases/tag/v0.9.10-ar20260929
- **status**: draft
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, copyright 2026 RISC-V International (the specification's "Copyright and License Information" page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/AirdAlmataryAmayaGarciaEtAl-26b.pdf, docs/bib/AirdAlmataryAmayaGarciaEtAl-26b.md
- **pinned**: release tag v0.9.10-ar20260929 (commit e966603ea4f7)
- **why**: The newest RVY release when observed, one day old; the reference point for how far the 0.9.9 model must move (#52 C3).

### Almatary-26a

- **type**: misc
- **author**: Hesham Almatary
- **title**: Instruction for building and running a proof of concept firmware compartmentalisation demo
- **organization**: Capabilities Limited
- **version**: Google Doc `20261009-firmware-demo-poc-compartmentalisation`, as read on 2026-10-11, its text unchanged since its revision of 2026-10-10 (attack objective and stated assumptions added to §6), with a comment thread of 2026-10-11 on omitting the device-tree step; first read 2026-10-09, with formatting and spelling edited by Robert Watson that day.  An AIVHAI team document still under review by team members, to be re-snapshotted when it settles (Joe Kiniry, 2026-10-09)
- **year**: 2026
- **url**: https://docs.google.com/document/d/1V8simjvy0kpNX4kKGvpG5-hhuSPkLhVDSdGwyCfuNMM/edit
- **status**: living
- **observed**: 2026-10-11
- **licence**: Copyright Capabilities Limited; shared with the consortium as a Google Doc; no licence stated
- **redistribute**: no
- **ip-class**: foreground
- **access**: consortium-only
- **fulltext**: docs/bib/Almatary-26a.md
- **pinned**: Google Doc as read on 2026-10-11 (Google Docs exposes no stable revision identifier); the demo's trusted code is `Capabilities-Limited/aivhai-fw-compartment` at `9691cf2e0c092f880f0aa57c7c3e70abf95b1b1e` (2026-10-10) `fw_compartment.S`, `cheribuild` branch `aivhai-opensbi`
- **why**: The Sprint 1 red-team target's attack scope and its four deliberately weakenable protections (BOUNDS, ASR, DDC, REGS_TEMP), which the AIVHAI threat model takes as the first compartment-boundary threats (#225, #53).  Delivered to the Trail of Bits red team for Sprint 1; `redistribute: no` still holds for the public mirror.

### Almatary-26b

- **type**: misc
- **author**: Hesham Almatary
- **title**: AIVHAI – Simple Firmware Compartmentalisation Model Draft
- **organization**: Capabilities Limited
- **version**: Google Doc as read on 2026-10-10, its text unchanged since 2026-10-09, carrying review comments by Robert Watson and Brooks Davis dated 2026-10-07 and by Ben Laurie dated 2026-10-10.  An AIVHAI team document still under review by team members, to be re-snapshotted when it settles (Joe Kiniry, 2026-10-09)
- **year**: 2026
- **url**: https://docs.google.com/document/d/1k12LYR0Z4gmKQ1lyvNLedUsreBsPNN9JyGmxky-599s/edit
- **status**: draft
- **observed**: 2026-10-10
- **licence**: Copyright Capabilities Limited; shared with the consortium as a Google Doc; no licence stated
- **redistribute**: no
- **ip-class**: foreground
- **access**: consortium-only
- **fulltext**: docs/bib/Almatary-26b.md
- **pinned**: Google Doc as read on 2026-10-10 (Google Docs exposes no stable revision identifier); the snapshot reproduces the open review comments because they identify the design questions
- **why**: Capabilities Limited's security model for the compartmentalisation firmware (adversary, assets, guarantee, exclusions, thirteen core rules), which the AIVHAI threat model adopts as the firmware-layer adversary model and the assurance case instantiates at G-CF (#225, #226, #1).  Not to be associated with the proof-of-concept demo (Hesham Almatary, 2026-10-09).

### AmarAndersonChenEtAl-26

- **type**: manual
- **author**: Saar Amar and Owen Anderson and Tony Chen and David Chisnall and Felix Domke and Nathaniel Wesley Filardo and Kunyan Liu and Robert M. Norton and Yucong Tao and Murali Vijayaraghavan and Robert N. M. Watson and Hongyan Xia
- **title**: CHERIoT Architecture Specification
- **version**: 1.0, built 2026-07-28 from CHERIoT-Platform/cheriot-sail commit 518813ec3e595f79930d9129eaded2521831cbe2
- **month**: jul
- **year**: 2026
- **url**: https://cheriot.org/cheriot-sail/cheriot-architecture.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (the specification's front matter); the embedded Sail model is BSD-2-Clause
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/AmarAndersonChenEtAl-26.pdf, docs/bib/AmarAndersonChenEtAl-26.md
- **pinned**: commit 518813ec3e595f79930d9129eaded2521831cbe2 of CHERIoT-Platform/cheriot-sail; a v1.0 release PDF of 2025-11-03 also exists
- **why**: The CHERIoT ISA, whose isolation model AIVHAI extends to 64 bits (#59); its Appendix B.1 lists SMT-validated properties of the capability encoding, such as `prop_setbounds`, which are candidate properties for RVY (#4, #122; suggested by Jonathan Woodruff).

### AmarChenChisnallEtAl-25

- **type**: inproceedings
- **author**: Saar Amar and Tony Chen and David Chisnall and Nathaniel Wesley Filardo and Ben Laurie and Hugo Lefeuvre and Kunyan Liu and Simon W. Moore and Robert Norton-Wright and Margo Seltzer and Yucong Tao and Robert N. M. Watson and Hongyan Xia
- **title**: CHERIoT RTOS: An OS for Fine-Grained Memory-Safe Compartments on Low-Cost Embedded Devices
- **booktitle**: Proceedings of the ACM SIGOPS 31st Symposium on Operating Systems Principles (SOSP '25)
- **pages**: 67--84
- **publisher**: ACM
- **month**: oct
- **year**: 2025
- **doi**: 10.1145/3731569.3764844
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202510-sosp-cheriot-rtos.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, copyright the authors (first page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/AmarChenChisnallEtAl-25.pdf, docs/bib/AmarChenChisnallEtAl-25.md
- **pinned**: doi:10.1145/3731569.3764844
- **why**: The authoritative description of the CHERIoT RTOS compartment model whose isolation guarantees AIVHAI extends to 64-bit application cores (#59, #122).

### AmarChisnallChenEtAl-23

- **type**: inproceedings
- **author**: Saar Amar and David Chisnall and Tony Chen and Nathaniel Wesley Filardo and Ben Laurie and Kunyan Liu and Robert Norton and Simon W. Moore and Yucong Tao and Robert N. M. Watson and Hongyan Xia
- **title**: CHERIoT: Complete Memory Safety for Embedded Devices
- **booktitle**: 56th Annual IEEE/ACM International Symposium on Microarchitecture (MICRO '23)
- **publisher**: ACM
- **pages**: 641--653
- **month**: oct
- **year**: 2023
- **doi**: 10.1145/3613424.3614266
- **url**: https://cheriot.org/papers/2023-micro-cheriot-uarch.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, copyright held by the authors (first page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/AmarChisnallChenEtAl-23.pdf, docs/bib/AmarChisnallChenEtAl-23.md
- **pinned**: doi:10.1145/3613424.3614266
- **why**: The architecture paper for CHERIoT, the 32-bit isolation design whose model AIVHAI extends to a 64-bit application core (#59).

### ArmstrongBauereissCampbellEtAl-19

- **type**: article
- **author**: Alasdair Armstrong and Thomas Bauereiss and Brian Campbell and Alastair Reid and Kathryn E. Gray and Robert M. Norton and Prashanth Mundkur and Mark Wassell and Jon French and Christopher Pulte and Shaked Flur and Ian Stark and Neel Krishnaswami and Peter Sewell
- **title**: ISA Semantics for ARMv8-A, RISC-V, and CHERI-MIPS
- **journal**: Proceedings of the ACM on Programming Languages
- **volume**: 3
- **number**: POPL
- **pages**: 71:1--71:31
- **month**: jan
- **year**: 2019
- **doi**: 10.1145/3290384
- **url**: https://www.cl.cam.ac.uk/~pes20/sail/sail-popl2019.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "© 2019 Copyright held by the owner/author(s)", personal and classroom use only (first page of the author copy); Crossref reports CC-BY-4.0 for the ACM version of record, which could not be read to confirm
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ArmstrongBauereissCampbellEtAl-19.pdf, docs/bib/ArmstrongBauereissCampbellEtAl-19.md
- **pinned**: doi:10.1145/3290384
- **why**: The founding Sail paper, defining the language and its generation of Isabelle and Coq definitions that the RVY model extension of #3 and its proofs build on (#57).

### ArmstrongBauereissCampbellEtAl-25

- **type**: manual
- **author**: Alasdair Armstrong and Thomas Bauereiss and Brian Campbell and Shaked Flur and Kathryn E. Gray and Robert Norton-Wright and Christopher Pulte and Peter Sewell
- **title**: The Sail instruction-set semantics specification language
- **version**: doc/asciidoc/manual.adoc as last changed upstream in 35d20365 (2025-02-24), read at Sigil-Logic/sail branch sail2 commit 5745ea9e5369ab4fc51de6f8b773dd8ebc323357
- **year**: 2025
- **url**: https://alasdair.github.io/manual.html
- **status**: living
- **observed**: 2026-09-30
- **licence**: BSD-2-Clause (the repository LICENSE; `doc/` is not carved out, except `doc/asciidoc/manual.css`, which is MIT)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ArmstrongBauereissCampbellEtAl-25.md
- **pinned**: commit 5745ea9e5369ab4fc51de6f8b773dd8ebc323357 of Sigil-Logic/sail; the alasdair.github.io page is an older rendering, of 2024-09-12
- **why**: The reference manual for the Sail language that the RVY and VME model of #3, and the Sail prelude and skills of #2 and #52 B1, are written against (#57).

### BauereissCampbellSewellEtAl-22

- **type**: inproceedings
- **author**: Thomas Bauereiss and Brian Campbell and Thomas Sewell and Alasdair Armstrong and Lawrence Esswood and Ian Stark and Graeme Barnes and Robert N. M. Watson and Peter Sewell
- **title**: Verified Security for the Morello Capability-enhanced Prototype Arm Architecture
- **booktitle**: Programming Languages and Systems: 31st European Symposium on Programming, ESOP 2022
- **series**: Lecture Notes in Computer Science
- **volume**: 13240
- **pages**: 174--203
- **publisher**: Springer
- **year**: 2022
- **doi**: 10.1007/978-3-030-99336-8_7
- **url**: https://www.cl.cam.ac.uk/~pes20/morello-proofs-esop2022.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, "© The Author(s) 2022" (pages 174 and 203 of the Springer open-access chapter)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/BauereissCampbellSewellEtAl-22.pdf, docs/bib/BauereissCampbellSewellEtAl-22.md
- **pinned**: doi:10.1007/978-3-030-99336-8_7
- **why**: A mechanised Isabelle/HOL proof of reachable capability monotonicity, up to domain crossing, for the full Morello ISA; the prior result #4 positions itself against, and a template for stating it (#57, #4).

### BauereissNortonWrightClarke-21

- **type**: misc
- **author**: Thomas Bauereiss and Robert Norton-Wright and Jessica Clarke
- **title**: cap_properties.sail: SMT-checked properties of the CHERI-RISC-V compressed-capability helper functions
- **version**: CTSRD-CHERI/sail-cheri-riscv-verif commit 4da8fd10e323ab67b92a771b02f5e989067ff81a; the file last changed 2021-07-28
- **year**: 2021
- **url**: https://github.com/CTSRD-CHERI/sail-cheri-riscv-verif/blob/4da8fd10e323ab67b92a771b02f5e989067ff81a/cap_properties.sail
- **status**: living
- **observed**: 2026-09-30
- **licence**: BSD-2-Clause (the file header, copyright 2019-2021 its three authors)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/BauereissNortonWrightClarke-21.md
- **pinned**: commit 4da8fd10e323ab67b92a771b02f5e989067ff81a; the repository is unmaintained since 2022 and, per Peter Rugg, partly bit-rotted
- **why**: The only published properties of CHERI-RISC-V capability encoding, checked by SMT rather than proved over the ISA; "easy starting points" for #4's lemmas about RVY compression (#4, #122; suggested by Peter Rugg).

### ChengMarkettosJoannouEtAl-25

- **type**: inproceedings
- **author**: Jianyi Cheng and A. Theodore Markettos and Alexandre Joannou and Paul Metzger and Matthew Naylor and Peter Rugg and Timothy M. Jones
- **title**: Adaptive CHERI Compartmentalization for Heterogeneous Accelerators
- **booktitle**: Proceedings of the 52nd Annual International Symposium on Computer Architecture (ISCA '25)
- **pages**: 2002--2016
- **publisher**: ACM
- **month**: jun
- **year**: 2025
- **doi**: 10.1145/3695053.3731062
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202506-isca-capchecker.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, copyright the authors (first page)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ChengMarkettosJoannouEtAl-25.pdf, docs/bib/ChengMarkettosJoannouEtAl-25.md
- **pinned**: doi:10.1145/3695053.3731062
- **why**: Prior art on mediating accelerator and peripheral memory accesses with CHERI capabilities (CapChecker), more finely than an IOMMU; a reference point for peripheral DMA behind the IOPMP and IOMMU, since AIVHAI's own accelerator is in the core (#1, #122, #227).

### CHERIoTPlatform-26

- **type**: misc
- **author**: {CHERIoT Platform}
- **title**: CHERIoT RTOS architecture: the loader, the switcher, the scheduler, and the allocator (docs/architecture.md)
- **organization**: Microsoft and the CHERIoT Platform contributors
- **version**: CHERIoT-Platform/cheriot-rtos commit 17ae734ba98e4f084bfaa2bf07f0447ca4d7e127 (2026-09-07)
- **year**: 2026
- **url**: https://github.com/CHERIoT-Platform/cheriot-rtos/blob/17ae734ba98e4f084bfaa2bf07f0447ca4d7e127/docs/architecture.md
- **status**: living
- **observed**: 2026-10-09
- **licence**: MIT (the repository's LICENSE)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: none
- **pinned**: commit 17ae734ba98e4f084bfaa2bf07f0447ca4d7e127, pinned without a fork in AIVHAI-Everything as `Tools/CHERIoT-Platform/cheriot-rtos` (#176, #232)
- **why**: States what each CHERIoT TCB component is trusted for, with the switcher as "the most privileged component that runs with access to untrusted data"; the per-component trust statements the AIVHAI threat model's firmware surfaces trace to (#225, #232).

### Chisnall-26

- **type**: misc
- **author**: David Chisnall
- **title**: CHERIoT Programmers' Guide: Safe and Secure Compartmentalisation (public draft)
- **version**: public draft built from CHERIoT-Platform/book commit 3d520968374ae0fcbf1ad6d34b89631f3637270b (2026-08-24)
- **year**: 2026
- **url**: https://cheriot.org/book/cheriot-programmers-guide.pdf
- **status**: living
- **observed**: 2026-09-30
- **licence**: CC BY-NC 4.0, copyright David Chisnall; portions from CHERIoT RTOS under MIT (page 2 of the PDF, and `book.igk` in the book's `text` directory)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Chisnall-26.pdf, docs/bib/Chisnall-26.md
- **pinned**: commit 3d520968374ae0fcbf1ad6d34b89631f3637270b of CHERIoT-Platform/book (PDF SHA-256 ed96945b22fc72bd768d4471cbc024ce5ab71efeee9c33fccaf849e6204976ad); a first edition was published by Sci Semiconductor on 2025-04-14, ISBN 979-8230585220
- **why**: The fullest account of the CHERIoT compartment, switcher, loader, sealing, and audit model, which AIVHAI extends to 64 bits (#55, #59); the NC licence rules out embedding it in agent preludes.

### ChisnallDavisGudkaEtAl-17

- **type**: inproceedings
- **author**: David Chisnall and Brooks Davis and Khilan Gudka and David Brazdil and Alexandre Joannou and Jonathan Woodruff and A. Theodore Markettos and J. Edward Maste and Robert Norton and Stacey Son and Michael Roe and Simon W. Moore and Peter G. Neumann and Ben Laurie and Robert N. M. Watson
- **title**: CHERI JNI: Sinking the Java Security Model into the C
- **booktitle**: Proceedings of the Twenty-Second International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS 2017)
- **publisher**: ACM
- **pages**: 569--583
- **month**: apr
- **year**: 2017
- **doi**: 10.1145/3037697.3037725
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201704-asplos-cherijni.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the preprint (first page: "Copyright notice will appear here once 'preprint' option is removed"); ACM on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ChisnallDavisGudkaEtAl-17.pdf, docs/bib/ChisnallDavisGudkaEtAl-17.md
- **pinned**: doi:10.1145/3037697.3037725
- **why**: Background: CHERI confining untrusted native code behind a managed runtime's policy, loosely analogous to confining tenants under the firmware (#1, #122).

### ChisnallRothwellWatsonEtAl-15

- **type**: inproceedings
- **author**: David Chisnall and Colin Rothwell and Robert N. M. Watson and Jonathan Woodruff and Munraj Vadera and Simon W. Moore and Michael Roe and Brooks Davis and Peter G. Neumann
- **title**: Beyond the PDP-11: Architectural Support for a Memory-Safe C Abstract Machine
- **booktitle**: Proceedings of the Twentieth International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS 2015)
- **publisher**: ACM
- **pages**: 117--130
- **month**: mar
- **year**: 2015
- **doi**: 10.1145/2694344.2694367
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201503-asplos2015-cheri-cmachine.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "Copyright is held by the owner/author(s). Publication rights licensed to ACM." (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ChisnallRothwellWatsonEtAl-15.pdf, docs/bib/ChisnallRothwellWatsonEtAl-15.md
- **pinned**: doi:10.1145/2694344.2694367
- **why**: Background: how the ISA was refined to support a memory-safe C abstract machine, which explains design choices the monotonicity proof inherits (#4, #122).

### DavisWatsonRichardsonEtAl-19

- **type**: inproceedings
- **author**: Brooks Davis and Robert N. M. Watson and Alexander Richardson and Peter G. Neumann and Simon W. Moore and John Baldwin and David Chisnall and Jessica Clarke and Nathaniel Wesley Filardo and Khilan Gudka and Alexandre Joannou and Ben Laurie and A. Theodore Markettos and J. Edward Maste and Alfredo Mazzinghi and Edward Tomasz Napierala and Robert M. Norton and Michael Roe and Peter Sewell and Stacey Son and Jonathan Woodruff
- **title**: CheriABI: Enforcing Valid Pointer Provenance and Minimizing Pointer Privilege in the POSIX C Run-time Environment
- **booktitle**: Proceedings of the Twenty-Fourth International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS '19)
- **pages**: 379--393
- **publisher**: ACM
- **month**: apr
- **year**: 2019
- **doi**: 10.1145/3297858.3304042
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201904-asplos-cheriabi.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: copyright held by the owner/author(s), publication rights licensed to ACM (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/DavisWatsonRichardsonEtAl-19.pdf, docs/bib/DavisWatsonRichardsonEtAl-19.md
- **pinned**: doi:10.1145/3297858.3304042
- **why**: A kernel that acts on memory only through capabilities userspace delegates to it, the pattern the firmware and the capability-aware NPU and DMA path must follow (#1, #122).

### FilardoGutsteinWoodruffEtAl-20

- **type**: inproceedings
- **author**: Nathaniel Wesley Filardo and Brett F. Gutstein and Jonathan Woodruff and Sam Ainsworth and Lucian Paul-Trifu and Brooks Davis and Hongyan Xia and Edward Tomasz Napierala and Alexander Richardson and John Baldwin and David Chisnall and Jessica Clarke and Khilan Gudka and Alexandre Joannou and A. Theodore Markettos and Alfredo Mazzinghi and Robert M. Norton and Michael Roe and Peter Sewell and Stacey Son and Timothy M. Jones and Simon W. Moore and Peter G. Neumann and Robert N. M. Watson
- **title**: Cornucopia: Temporal Safety for CHERI Heaps
- **booktitle**: 2020 IEEE Symposium on Security and Privacy (SP)
- **pages**: 608--625
- **publisher**: IEEE
- **month**: may
- **year**: 2020
- **doi**: 10.1109/SP40000.2020.00098
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2020oakland-cornucopia.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no licence statement on the author PDF; IEEE copyright on the version of record
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/FilardoGutsteinWoodruffEtAl-20.pdf, docs/bib/FilardoGutsteinWoodruffEtAl-20.md
- **pinned**: doi:10.1109/SP40000.2020.00098
- **why**: Mostly background: heap revocation using tagged memory, relevant to whether the firmware must revoke capabilities delegated to a tenant or the NPU before reuse (#1, #122).

### FilardoGutsteinWoodruffEtAl-24

- **type**: inproceedings
- **author**: Nathaniel Wesley Filardo and Brett F. Gutstein and Jonathan Woodruff and Jessica Clarke and Peter Rugg and Brooks Davis and Mark Johnston and Robert Norton and David Chisnall and Simon W. Moore and Peter G. Neumann and Robert N. M. Watson
- **title**: Cornucopia Reloaded: Load Barriers for CHERI Heap Temporal Safety
- **booktitle**: Proceedings of the 29th ACM International Conference on Architectural Support for Programming Languages and Operating Systems, Volume 2 (ASPLOS '24)
- **pages**: 251--268
- **publisher**: ACM
- **month**: apr
- **year**: 2024
- **doi**: 10.1145/3620665.3640416
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202404asplos-cornucopia-reloaded.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: ACM author-rights notice, personal and classroom use only (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/FilardoGutsteinWoodruffEtAl-24.pdf, docs/bib/FilardoGutsteinWoodruffEtAl-24.md
- **pinned**: doi:10.1145/3620665.3640416
- **why**: A per-page capability load barrier for revocation; relevant if the ISA model must carry load-barrier and revocation state, and otherwise background on temporal safety (#4, #122).

### FuchsWoodruffMooreEtAl-21

- **type**: inproceedings
- **author**: Franz A. Fuchs and Jonathan Woodruff and Simon W. Moore and Peter G. Neumann and Robert N. M. Watson
- **title**: Developing a Test Suite for Transient-Execution Attacks on RISC-V and CHERI-RISC-V
- **booktitle**: Fifth Workshop on Computer Architecture Research with RISC-V (CARRV 2021), co-located with ISCA 2021
- **month**: jun
- **year**: 2021
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202106-carrv-transient-execution.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "© 2021 Association for Computing Machinery" with the ACM permission block (first page of the author version)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/FuchsWoodruffMooreEtAl-21.pdf, docs/bib/FuchsWoodruffMooreEtAl-21.md
- **pinned**: the URL above, SHA-256 a26ab7fbe9a04f92c7139551269ce39da6e9be0798660ac615427ed04d79dc86; no DOI
- **why**: Red-team context: CHERI-RISC-V out-of-order cores stay exposed to transient-execution attacks, which supports keeping side channels outside the formal boundary (#53, #122).

### FuchsWoodruffRuggEtAl-23

- **type**: inproceedings
- **author**: Franz A. Fuchs and Jonathan Woodruff and Peter Rugg and van der Maas, Marno and Alexandre Joannou and Alexander Richardson and Jessica Clarke and Nathaniel Wesley Filardo and Brooks Davis and John Baldwin and Peter G. Neumann and Simon W. Moore and Robert N. M. Watson
- **title**: Architectural Contracts for Safe Speculation
- **booktitle**: 2023 IEEE 41st International Conference on Computer Design (ICCD)
- **pages**: 578--586
- **publisher**: IEEE
- **month**: nov
- **year**: 2023
- **doi**: 10.1109/ICCD58817.2023.00093
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202311-iccd-speculation-contracts.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no licence statement on the author PDF (only "Distribution Statement A: Approved for public release"); IEEE copyright on the version of record
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/FuchsWoodruffRuggEtAl-23.pdf, docs/bib/FuchsWoodruffRuggEtAl-23.md
- **pinned**: doi:10.1109/ICCD58817.2023.00093
- **why**: ISA-level speculation contracts a microarchitecture can be checked against: red-team context, and help in scoping side channels outside the CVA6-CHERI correctness claim (#53, #1, #122).

### FuchsWoodruffRuggEtAl-24

- **type**: inproceedings
- **author**: Franz A. Fuchs and Jonathan Woodruff and Peter Rugg and Alexandre Joannou and Jessica Clarke and John Baldwin and Brooks Davis and Peter G. Neumann and Robert N. M. Watson and Simon W. Moore
- **title**: Safe Speculation for CHERI
- **booktitle**: 2024 IEEE 42nd International Conference on Computer Design (ICCD)
- **pages**: 364--372
- **publisher**: IEEE
- **month**: nov
- **year**: 2024
- **doi**: 10.1109/ICCD63220.2024.00063
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202411-iccd-cap-contracts.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY, applied by the authors to the accepted manuscript (first-page footnote); the committed PDF is that manuscript, with no IEEE banner
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/FuchsWoodruffRuggEtAl-24.pdf, docs/bib/FuchsWoodruffRuggEtAl-24.md
- **pinned**: doi:10.1109/ICCD63220.2024.00063
- **why**: The capability speculation contract and a transient capability-forgery attack: bears on whether CVA6-CHERI correctness should speak to speculation, and is red-team context for side channels, which lie outside the formal boundary (#1, #53, #122).

### Gao-26

- **type**: misc
- **author**: Dapeng Gao
- **title**: compartmentalization(7): library-based compartmentalization (CheriBSD manual page)
- **organization**: CTSRD-CHERI
- **version**: CTSRD-CHERI/cheribsd commit 88f39900c32928d807dba245fba138808c666f34 (2026-07-20); the page last changed in e2919be888284c2c55b4e21fd73b396018e278b2 (2026-06-10)
- **year**: 2026
- **url**: https://github.com/CTSRD-CHERI/cheribsd/blob/88f39900c32928d807dba245fba138808c666f34/share/man/man7/compartmentalization.7
- **status**: living
- **observed**: 2026-10-09
- **licence**: BSD-2-Clause (the file header; copyright 2022 Dapeng Gao)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Gao-26.md
- **pinned**: commit 88f39900c32928d807dba245fba138808c666f34, path `share/man/man7/compartmentalization.7`.  Deliberately not a submodule of AIVHAI-Everything: 2.2 GB for one page (#232)
- **why**: The SECURITY section is the cleanest published example of a named TCB plus enumerated known holes, the exclusions style the AIVHAI threat model follows; it also states the trusted-toolchain assumption that excludes build-system supply-chain attacks (#225, #232).

### GaoBaldwinClarkeEtAl-26

- **type**: inproceedings
- **author**: Dapeng Gao and John Baldwin and Jessica Clarke and Nicholas C. Connolly and Brooks Davis and Franz A. Fuchs and Alfredo Mazzinghi and Daniel Moghimi and Peter Rugg and Domagoj Stolfa and Konrad Witaszczyk and Simon W. Moore and Robert N. M. Watson
- **title**: Efficient Linkage-Based Compartmentalization on CHERI
- **booktitle**: Proceedings of the 2026 ACM SIGSAC Conference on Computer and Communications Security (CCS '26)
- **publisher**: ACM
- **version**: arXiv:2609.36731v1 (2026-09-29), accepted to CCS '26
- **month**: nov
- **year**: 2026
- **doi**: 10.1145/3830454.3846528
- **url**: https://arxiv.org/abs/2609.36731
- **status**: frozen
- **observed**: 2026-09-30
- **licence**: CC BY-NC-ND 4.0, copyright the authors (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/GaoBaldwinClarkeEtAl-26.pdf, docs/bib/GaoBaldwinClarkeEtAl-26.md
- **pinned**: arXiv:2609.36731v1; the printed DOI did not yet resolve on 2026-09-30
- **why**: CHERI compartmentalisation at library-linkage granularity on application-class cores, including Codasip's CHERI-RISC-V X730: a design point for how the firmware might structure 64-bit compartments (#59, #122).

### GaoWatson-23

- **type**: inproceedings
- **author**: Dapeng Gao and Robert N. M. Watson
- **title**: Library-based Compartmentalisation on CHERI
- **booktitle**: Programming Languages for Architecture (PLARCH 2023), co-located with PLDI 2023
- **month**: jun
- **year**: 2023
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202306-plarch-library-based-compartmentalisation.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no licence or copyright statement on the document
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/GaoWatson-23.pdf, docs/bib/GaoWatson-23.md
- **pinned**: the URL above, SHA-256 0905d1ae63b6fcafa1e09b358f96c9d866c6b99cf0266bee293604d4728c58dc; no DOI
- **why**: Background: software compartmentalisation by dynamic linkage on Morello, a contrast to the firmware-level compartments of the isolation work (#59, #122).

### Google-26a

- **type**: misc
- **author**: {Google}
- **title**: CoralNPU Overview
- **organization**: Google
- **version**: google-coral/coralnpu commit 8e4df09b4ea7e065e02d14ce3ae033d40dfd973a (2026-09-30); the file last changed in 81036e734e (2026-09-21)
- **year**: 2026
- **url**: https://github.com/google-coral/coralnpu/blob/8e4df09b4ea7e065e02d14ce3ae033d40dfd973a/doc/overview.md
- **status**: living
- **observed**: 2026-09-30
- **licence**: Apache-2.0 (the repository's LICENSE; the document states nothing of its own)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Google-26a.md
- **pinned**: commit 8e4df09b4ea7e065e02d14ce3ae033d40dfd973a
- **why**: The only citable technical description of the Coral NPU that AIVHAI makes capability-aware, including its experimental Zvt (VME) implementation (#48, #1).

### Google-26b

- **type**: misc
- **author**: {Google}
- **title**: Example: Running the MobileNet CNN (Coral NPU guide)
- **organization**: Google
- **version**: page last updated 2026-04-08
- **year**: 2026
- **url**: https://developers.google.com/coral/guides/software/run-mobilenet
- **status**: living
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 for the text, Apache-2.0 for code samples (page footer)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Google-26b.md
- **pinned**: the snapshot of the page as last updated 2026-04-08
- **why**: How a LiteRT model is compiled and run on the Coral NPU simulator, the workload the capability-aware NPU must keep running (#1; followed by Hesham Almatary, #122).

### Google-26c

- **type**: misc
- **author**: {Google}
- **title**: Bare-metal programming on Coral NPU (Coral NPU guide)
- **organization**: Google
- **version**: page last updated 2026-02-12
- **year**: 2026
- **url**: https://developers.google.com/coral/guides/software/bare-metal-prog
- **status**: living
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 for the text, Apache-2.0 for code samples (page footer)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Google-26c.md
- **pinned**: the snapshot of the page as last updated 2026-02-12
- **why**: The bare-metal programming model of the Coral NPU, the layer the compartmentalisation firmware sits beside (#1; followed by Hesham Almatary, #122).

### GrisenthwaiteBarnesWatsonEtAl-23

- **type**: article
- **author**: Richard Grisenthwaite and Graeme Barnes and Robert N. M. Watson and Simon W. Moore and Peter Sewell and Jonathan Woodruff
- **title**: The Arm Morello Evaluation Platform—Validating CHERI-Based Security in a High-Performance System
- **journal**: IEEE Micro
- **volume**: 43
- **number**: 3
- **pages**: 50--57
- **month**: may
- **year**: 2023
- **doi**: 10.1109/MM.2023.3264676
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202305ieeemicro-morello-platform.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY, applied by the authors to the author version (first page); IEEE copyright on the version of record
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/GrisenthwaiteBarnesWatsonEtAl-23.pdf, docs/bib/GrisenthwaiteBarnesWatsonEtAl-23.md
- **pinned**: doi:10.1109/MM.2023.3264676
- **why**: A high-performance CHERI implementation with tagged memory and formally proven architectural properties: precedent for pairing an ISA-level proof with a real core, as #4 and CVA6-CHERI do (#4, #122).

### GudkaWatsonAndersonEtAl-15

- **type**: inproceedings
- **author**: Khilan Gudka and Robert N. M. Watson and Jonathan Anderson and David Chisnall and Brooks Davis and Ben Laurie and Ilias Marinos and Peter G. Neumann and Alex Richardson
- **title**: Clean Application Compartmentalization with SOAAP
- **booktitle**: Proceedings of the 22nd ACM SIGSAC Conference on Computer and Communications Security (CCS 2015)
- **publisher**: ACM
- **pages**: 1016--1031
- **month**: oct
- **year**: 2015
- **doi**: 10.1145/2810103.2813611
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2015ccs-soaap.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "Copyright is held by the owner/author(s). Publication rights licensed to ACM." (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/GudkaWatsonAndersonEtAl-15.pdf, docs/bib/GudkaWatsonAndersonEtAl-15.md
- **pinned**: doi:10.1145/2810103.2813611
- **why**: Background: a method for analysing how to split software into compartments, context for decomposition decisions around the firmware (#59, #122).

### HammondAlmeidaBauereissEtAl-25

- **type**: article
- **author**: Angus Hammond and Ricardo Almeida and Thomas Bauereiss and Brian Campbell and Ian Stark and Peter Sewell
- **title**: Morello-Cerise: A Proof of Strong Encapsulation for the Arm Morello Capability Hardware Architecture
- **journal**: Proceedings of the ACM on Programming Languages
- **volume**: 9
- **number**: PLDI
- **pages**: 226:1--226:23
- **month**: jun
- **year**: 2025
- **doi**: 10.1145/3729329
- **url**: https://www.cl.cam.ac.uk/~pes20/pldi25-paper646-camera-ready.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (first page of the camera-ready, in final ACM format)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/HammondAlmeidaBauereissEtAl-25.pdf, docs/bib/HammondAlmeidaBauereissEtAl-25.md
- **pinned**: doi:10.1145/3729329
- **why**: A mechanised proof, in Iris and Rocq over Isabelle-proved ISA properties, of strong encapsulation across domain crossings on Morello; the template for the compartment-isolation claims beyond monotonicity in #1 (#57, #4).

### JoannouRuggWoodruffEtAl-24

- **type**: article
- **author**: Alexandre Joannou and Peter Rugg and Jonathan Woodruff and Franz A. Fuchs and van der Maas, Marno and Matthew Naylor and Michael Roe and Robert N. M. Watson and Peter G. Neumann and Simon W. Moore
- **title**: Randomized Testing of RISC-V CPUs using Direct Instruction Injection
- **journal**: IEEE Design & Test
- **volume**: 41
- **number**: 1
- **pages**: 40--49
- **month**: feb
- **year**: 2024
- **doi**: 10.1109/MDAT.2023.3262741
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202402-testrig.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY, applied by the authors to the accepted manuscript (acknowledgements); the committed PDF is that manuscript, and IEEE holds copyright in the version of record
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/JoannouRuggWoodruffEtAl-24.pdf, docs/bib/JoannouRuggWoodruffEtAl-24.md
- **pinned**: doi:10.1109/MDAT.2023.3262741
- **why**: TestRIG, tandem testing of RISC-V and CHERI implementations against the Sail model: the validation route for CVA6-CHERI alongside the correctness proofs, and a tool we fork (#1, #122).

### JoannouWoodruffKovacsicsEtAl-17

- **type**: inproceedings
- **author**: Alexandre Joannou and Jonathan Woodruff and Robert Kovacsics and Simon W. Moore and Alex Bradbury and Hongyan Xia and Robert N. M. Watson and David Chisnall and Michael Roe and Brooks Davis and Edward Napierala and John Baldwin and Khilan Gudka and Peter G. Neumann and Alfredo Mazzinghi and Alex Richardson and Stacey Son and A. Theodore Markettos
- **title**: Efficient Tagged Memory
- **booktitle**: 2017 IEEE International Conference on Computer Design (ICCD)
- **pages**: 641--648
- **publisher**: IEEE
- **month**: nov
- **year**: 2017
- **doi**: 10.1109/ICCD.2017.112
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201711-iccd2017-efficient-tags.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author copy; IEEE copyright on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/JoannouWoodruffKovacsicsEtAl-17.pdf, docs/bib/JoannouWoodruffKovacsicsEtAl-17.md
- **pinned**: doi:10.1109/ICCD.2017.112
- **why**: The in-memory tag table beside the DRAM controller, which decides where peripheral DMA must keep or clear capability tags; relevant to the IOPMP and IOMMU path the firmware depends on (#1, #122, #227).

### Killian-25

- **type**: misc
- **author**: Earl A. Killian
- **title**: VME Design Considerations
- **version**: Draft 0.1.1 (20250831a)
- **month**: aug
- **year**: 2025
- **url**: https://lf-riscv.atlassian.net/wiki/spaces/VMEX/overview
- **status**: draft
- **observed**: 2026-09-30
- **licence**: none stated in the document
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Killian-25.pdf, docs/bib/Killian-25.md
- **pinned**: Draft 0.1.1, dated 2025-08-31, attached to the VME Task Group's Confluence space
- **why**: A Task Group member's analysis of the design trade-offs behind VME, useful for reading the specification's choices (#48).

### MarkettosBaldwinBukinEtAl-20

- **type**: inproceedings
- **author**: A. Theodore Markettos and John Baldwin and Ruslan Bukin and Peter G. Neumann and Simon W. Moore and Robert N. M. Watson
- **title**: Position Paper: Defending Direct Memory Access with CHERI Capabilities
- **booktitle**: Hardware and Architectural Support for Security and Privacy (HASP '20)
- **pages**: 1--9
- **publisher**: ACM
- **month**: oct
- **year**: 2020
- **doi**: 10.1145/3458903.3458910
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2020hasp-cheri-dma.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "© 2020 Association for Computing Machinery" on the author PDF; Crossref reports CC-BY-4.0 for the ACM version of record, which could not be fetched to confirm
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/MarkettosBaldwinBukinEtAl-20.pdf, docs/bib/MarkettosBaldwinBukinEtAl-20.md
- **pinned**: doi:10.1145/3458903.3458910
- **why**: The DMA threat and capability-based protection for peripherals: the antecedent for peripheral DMA behind the IOPMP and IOMMU, which AIVHAI's firmware depends on (#1, #122, #227).

### MazzinghiSohanWatson-18

- **type**: inproceedings
- **author**: Alfredo Mazzinghi and Ripduman Sohan and Robert N. M. Watson
- **title**: Pointer Provenance in a Capability Architecture
- **booktitle**: Proceedings of the 10th USENIX Workshop on the Theory and Practice of Provenance (TaPP 2018)
- **publisher**: USENIX Association
- **month**: jul
- **year**: 2018
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2018tapp-tracing-cameraready.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "(c) 2018 Copyright held by the owner/author(s)" with a personal and classroom use notice (first page of the camera-ready)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/MazzinghiSohanWatson-18.pdf, docs/bib/MazzinghiSohanWatson-18.md
- **pinned**: the camera-ready at the URL above; no DOI was assigned (USENIX page https://www.usenix.org/conference/tapp2018/presentation/mazzinghi)
- **why**: Background: traces how capabilities derive from one another at run time, an illustration of the derivation relation the monotonicity proof reasons about (#4, #122).

### MemarianGomesDavisEtAl-19

- **type**: article
- **author**: Kayvan Memarian and Victor B. F. Gomes and Brooks Davis and Stephen Kell and Alexander Richardson and Robert N. M. Watson and Peter Sewell
- **title**: Exploring C Semantics and Pointer Provenance
- **journal**: Proceedings of the ACM on Programming Languages
- **volume**: 3
- **number**: POPL
- **pages**: 67:1--67:32
- **publisher**: ACM
- **month**: jan
- **year**: 2019
- **doi**: 10.1145/3290380
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201901-popl-cerberus.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "Copyright held by the owner/author(s)" with the ACM personal-use notice (first page); Crossref reports CC-BY-4.0 for the version of record, not confirmed from a document
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/MemarianGomesDavisEtAl-19.pdf, docs/bib/MemarianGomesDavisEtAl-19.md
- **pinned**: doi:10.1145/3290380
- **why**: Background: a formal semantics of C pointer provenance, of use if the firmware's C prototypes need a source-level provenance model (#1, #122).

### MemarianMatthiesenLingardEtAl-16

- **type**: inproceedings
- **author**: Kayvan Memarian and Justus Matthiesen and James Lingard and Kyndylan Nienhuis and David Chisnall and Robert N. M. Watson and Peter Sewell
- **title**: Into the Depths of C: Elaborating the De Facto Standards
- **booktitle**: Proceedings of the 37th ACM SIGPLAN Conference on Programming Language Design and Implementation (PLDI 2016)
- **publisher**: ACM
- **pages**: 1--15
- **month**: jun
- **year**: 2016
- **doi**: 10.1145/2908080.2908081
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201606-pldi2016-clanguage.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author version; ACM on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/MemarianMatthiesenLingardEtAl-16.pdf, docs/bib/MemarianMatthiesenLingardEtAl-16.md
- **pinned**: doi:10.1145/2908080.2908081
- **why**: Background: the Cerberus C semantics and its provenance memory model, for stating what C-level firmware code may assume about pointers on capability hardware (#1, #122).

### MetzgerMarkettosNapieralaEtAl-25

- **type**: inproceedings
- **author**: Paul Metzger and A. Theodore Markettos and Edward Tomasz Napierała and Matthew Naylor and Robert N. M. Watson and Timothy M. Jones
- **title**: Deprivileging Low-Level GPU Drivers Efficiently with User-Space Processes and CHERI Compartments
- **booktitle**: Proceedings of the 2025 ACM SIGSAC Conference on Computer and Communications Security (CCS '25)
- **pages**: 2699--2713
- **publisher**: ACM
- **month**: oct
- **year**: 2025
- **doi**: 10.1145/3719027.3765036
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/202510-ccs-gpu-driver-compartments.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC BY-ND 4.0, copyright the authors (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/MetzgerMarkettosNapieralaEtAl-25.pdf, docs/bib/MetzgerMarkettosNapieralaEtAl-25.md
- **pinned**: doi:10.1145/3719027.3765036
- **why**: Puts an accelerator (GPU) driver in a CHERI compartment and moves the device's page-table management into a vetted component: directly relevant to how the firmware mediates an untrusted accelerator driver and the NPU's memory mappings (#1, #122).

### Naylor-25

- **type**: misc
- **author**: Matthew Naylor
- **title**: CHERICapProps.bsv: properties of the CHERI capability library
- **version**: CTSRD-CHERI/cheri-cap-lib commit 1d2c0b953ba8e46a6503df7537a8eb02d8df6b5a (2025-03-07)
- **year**: 2025
- **url**: https://github.com/CTSRD-CHERI/cheri-cap-lib/blob/1d2c0b953ba8e46a6503df7537a8eb02d8df6b5a/CHERICapProps.bsv
- **status**: living
- **observed**: 2026-09-30
- **licence**: BERI Hardware-Software License v1.0, an Apache-2.0 derivative (the file header and the repository's LICENCE)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Naylor-25.md
- **pinned**: commit 1d2c0b953ba8e46a6503df7537a8eb02d8df6b5a; `cheri-cap-lib` is also one of our IP forks
- **why**: Bluespec properties of the capability library CVA6-CHERI uses, the RTL-side counterpart of the Sail encoding properties (#1 target c, #122; suggested by Peter Rugg).

### NaylorWoodruff-17

- **type**: misc
- **author**: Matthew Naylor and Jonathan Woodruff
- **title**: Cap128PointerModifyTest.bsv: a CHERI-MIPS 128-bit capability pointer-modification testbench
- **version**: CTSRD-CHERI/beri commit cef1b41d52592cfa7454ddf59f9f2994e447cd66 (2017-03-27)
- **year**: 2017
- **url**: https://github.com/CTSRD-CHERI/beri/blob/cef1b41d52592cfa7454ddf59f9f2994e447cd66/cheri/trunk/Test/Cap128PointerModifyTest/Cap128PointerModifyTest.bsv
- **status**: published
- **observed**: 2026-09-30
- **licence**: BERI Hardware-Software License v1.0, an Apache-2.0 derivative (the file header; the repository's NOTICE is reproduced in the snapshot)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/NaylorWoodruff-17.md
- **pinned**: commit cef1b41d52592cfa7454ddf59f9f2994e447cd66, the repository's last
- **why**: The most relevant CHERI-MIPS testbench for capability compression, per Jonathan Woodruff, and a source of test vectors for the compression lemmas the monotonicity proof needs; other tests sit in the same directory (#4, #122).

### Neumann-18

- **type**: incollection
- **author**: Peter G. Neumann
- **title**: Fundamental Trustworthiness Principles in CHERI
- **booktitle**: New Solutions for Cybersecurity
- **editor**: Howard Shrobe and David L. Shrier and Alex Pentland
- **pages**: 199--238
- **publisher**: MIT Press
- **month**: jan
- **year**: 2018
- **doi**: 10.7551/mitpress/11636.003.0009
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2017mit-cybersecurity-cheri-princ-web.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author's working draft of 2017-03-06; MIT Press copyright on the published chapter
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Neumann-18.pdf, docs/bib/Neumann-18.md
- **pinned**: doi:10.7551/mitpress/11636.003.0009; the committed PDF is the 2017 working draft, titled without "in CHERI"
- **why**: Background: trustworthiness principles as applied to CHERI, which frame AIVHAI's scoped assurance claims (#1, #122).

### Nienhuis-21

- **type**: phdthesis
- **author**: Kyndylan Nienhuis
- **title**: Verified Security Properties for the Capability-Enhanced CHERI-MIPS Architecture
- **school**: University of Cambridge, Computer Laboratory
- **month**: sep
- **year**: 2021
- **doi**: 10.17863/CAM.83267
- **url**: https://www.repository.cam.ac.uk/items/08709808-c895-4ebc-83fe-3971d0e63a0a
- **status**: published
- **observed**: 2026-09-30
- **licence**: All Rights Reserved (the repository record's rights statement)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/Nienhuis-21.pdf, docs/bib/Nienhuis-21.md
- **pinned**: doi:10.17863/CAM.83267; the thesis page is dated September 2021, and the deposit is of 2022
- **why**: The full development of the CHERI-MIPS monotonicity and compartment-isolation proofs summarised in [@NienhuisJoannouBauereissEtAl-20], and one of the three proof papers Robert Watson named as references for the architectural sketch (#4, #122).

### NienhuisJoannouBauereissEtAl-20

- **type**: inproceedings
- **author**: Kyndylan Nienhuis and Alexandre Joannou and Thomas Bauereiss and Anthony Fox and Michael Roe and Brian Campbell and Matthew Naylor and Robert M. Norton and Simon W. Moore and Peter G. Neumann and Ian Stark and Robert N. M. Watson and Peter Sewell
- **title**: Rigorous engineering for hardware security: Formal modelling and proof in the CHERI design and implementation process
- **booktitle**: 2020 IEEE Symposium on Security and Privacy (SP)
- **pages**: 1003--1020
- **publisher**: IEEE
- **month**: may
- **year**: 2020
- **doi**: 10.1109/SP40000.2020.00055
- **url**: https://www.cl.cam.ac.uk/~pes20/cheri-formal.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: IEEE copyright on the published version; the committed PDF is the author accepted version, which states no licence
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/NienhuisJoannouBauereissEtAl-20.pdf, docs/bib/NienhuisJoannouBauereissEtAl-20.md
- **pinned**: doi:10.1109/SP40000.2020.00055
- **why**: The first mechanised proofs, in Isabelle, of reachable capability monotonicity and compartment isolation for a complete CHERI ISA (CHERI-MIPS); the other prior result #4 must cite (#57, #4).

### PloixArmstrongMelhamEtAl-25

- **type**: misc
- **author**: Louis-Emile Ploix and Alasdair Armstrong and Tom Melham and Ray Lin and Haolong Wang and Anastasia Courtney
- **title**: Comprehensive Formal Verification of Observational Correctness for the CHERIoT-Ibex Processor
- **publisher**: arXiv
- **number**: arXiv:2502.04738v1
- **month**: feb
- **year**: 2025
- **url**: https://arxiv.org/abs/2502.04738
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (declared on the arXiv abstract page; the PDF prints none)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/PloixArmstrongMelhamEtAl-25.pdf, docs/bib/PloixArmstrongMelhamEtAl-25.md
- **pinned**: arXiv:2502.04738v1
- **why**: The Oxford method (Sail translated to SystemVerilog, then proved observationally equivalent in Jasper) that the unpublished COSMIC proof of CVA6-CHERI extends; the only published account of it (#1, target c).

### RISCVInternational-25a

- **type**: manual
- **author**: {RISC-V International}
- **title**: The RISC-V Instruction Set Manual, Volume I: Unprivileged Architecture
- **organization**: RISC-V International
- **version**: 20250508
- **month**: may
- **year**: 2025
- **url**: https://github.com/riscv/riscv-isa-manual/releases/tag/20250508
- **status**: ratified
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (the Preamble, page 1)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/RISCVInternational-25a.pdf, docs/bib/RISCVInternational-25a.md
- **pinned**: release tag 20250508 (riscv-unprivileged-20250508.pdf, SHA-256 cef2e63c08c6f82cf7acc9056a589954f5b1adf6f7dccaa38cd75278b093e984)
- **why**: The ratified unprivileged ISA, including the vector extension RVV 1.0 in chapter 30, on which RVY, CVA6-CHERI, and VME are all defined (#3, #48).

### RISCVInternational-25b

- **type**: manual
- **author**: {RISC-V International}
- **title**: The RISC-V Instruction Set Manual, Volume II: Privileged Architecture
- **organization**: RISC-V International
- **version**: 20250508
- **month**: may
- **year**: 2025
- **url**: https://github.com/riscv/riscv-isa-manual/releases/tag/20250508
- **status**: ratified
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (the Preamble, page 1)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/RISCVInternational-25b.pdf, docs/bib/RISCVInternational-25b.md
- **pinned**: release tag 20250508 (riscv-privileged-20250508.pdf, SHA-256 d0228bbecc76943aaa5685e381e0263a8c750d18b1b0c452b086b0ddd15a4955)
- **why**: The ratified privileged ISA (modes, traps, PMP, virtual memory) that the firmware isolation proofs and the core-correctness proofs rest on (#1).

### RISCVInternational-25c

- **type**: misc
- **author**: {RISC-V International}
- **title**: Vector-Matrix Extension (VME) Charter
- **organization**: RISC-V International, Vector Matrix Extension Task Group (RVG-686)
- **month**: aug
- **year**: 2025
- **url**: https://lf-riscv.atlassian.net/wiki/spaces/VMEX/pages/663912452
- **status**: published
- **observed**: 2026-09-30
- **licence**: none stated on the page
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/RISCVInternational-25c.md
- **pinned**: Confluence page 663912452, version 9 of 2025-08-03
- **why**: The Task Group's own statement of VME's scope and exclusions, against which the specification text can be read (#48).

### RISCVInternational-26a

- **type**: misc
- **author**: {RISC-V International}
- **title**: Zvt Family of Vector Matrix Extensions, Version 0.4 (Internal Review draft)
- **organization**: RISC-V International, Vector Matrix Extension Task Group
- **version**: 0.4, Internal Review draft built 2026-08-31
- **month**: sep
- **year**: 2026
- **url**: https://lists.riscv.org/g/tech-announce/attachment/786/0
- **status**: under-development
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0: built from riscv/riscv-isa-manual, whose LICENSE is CC-BY-4.0 and whose preamble extends it to future versions; the 16-page excerpt itself prints only "© RISC-V International"
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/RISCVInternational-26a.pdf, docs/bib/RISCVInternational-26a.md
- **pinned**: SHA-256 2a4e9695f35d8de0b8f19d98a835158f788ef84013b289a3b480de1fb011f830 (the PDF attached to tech-announce message 786, 2026-09-04)
- **why**: The VME text as circulated for Internal Review; it predates three later commits, so [@RISCVInternational-26b] is the newer text (#48, #3).

### RISCVInternational-26b

- **type**: misc
- **author**: {RISC-V International}
- **title**: Zvt Family of Vector Matrix Extensions, Version 0.4 (pull-request text)
- **organization**: RISC-V International, Vector Matrix Extension Task Group
- **version**: src/unpriv/zvt.adoc in riscv/riscv-isa-manual#2997 at head 31a76665e9fc532199c21b99f1311bc8345bc532 (2026-09-21)
- **month**: sep
- **year**: 2026
- **url**: https://github.com/riscv/riscv-isa-manual/pull/2997
- **status**: under-development
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0 (the LICENSE of riscv/riscv-isa-manual)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/RISCVInternational-26b.md
- **pinned**: commit 31a76665e9fc532199c21b99f1311bc8345bc532 of riscv/riscv-isa-manual; freeze projected for 2026-12-07 (Jira RVS-3923)
- **why**: The newest VME text, and the one the Sail VME model of #3 should be written against until the freeze (#48).

### RISCVInternational-26c

- **type**: misc
- **author**: {RISC-V International}
- **title**: RISC-V IOPMP Architecture Specification
- **organization**: RISC-V International
- **version**: riscv-non-isa/riscv-iopmp commit b2d6a5c9698a6286a8989e0ebb7cb9d09a0a15cc (2026-10-02)
- **year**: 2026
- **url**: https://github.com/riscv-non-isa/riscv-iopmp/blob/b2d6a5c9698a6286a8989e0ebb7cb9d09a0a15cc/chapter3.adoc
- **status**: living
- **observed**: 2026-10-09
- **licence**: CC-BY-4.0 (the repository's LICENSE)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: none
- **pinned**: commit b2d6a5c9698a6286a8989e0ebb7cb9d09a0a15cc, forked as `Sigil-Logic/riscv-iopmp` and pinned in AIVHAI-Everything as `Hardware/RISC-V/riscv-iopmp` (#232)
- **why**: The specification of the control on peripheral DMA that the compartmentalisation firmware depends on for its own protection (#227); its Configuration Protection chapter, and its implementation-defined requester-ID tagging, are sources of the AIVHAI threat model (#225).

### RISCVInternational-26d

- **type**: misc
- **author**: {RISC-V International}
- **title**: RISC-V IOMMU Architecture Specification
- **organization**: RISC-V International
- **version**: riscv-non-isa/riscv-iommu commit 875e15459ef7ac99dfd313b2a8c0a19dba742e59 (2026-10-09)
- **year**: 2026
- **url**: https://github.com/riscv-non-isa/riscv-iommu/blob/875e15459ef7ac99dfd313b2a8c0a19dba742e59/src/iommu_intro.adoc
- **status**: living
- **observed**: 2026-10-09
- **licence**: CC-BY-4.0 (the repository's LICENSE)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: none
- **pinned**: commit 875e15459ef7ac99dfd313b2a8c0a19dba742e59, forked as `Sigil-Logic/riscv-iommu` and pinned in AIVHAI-Everything as `Hardware/RISC-V/riscv-iommu` (#232)
- **why**: The second control on peripheral DMA (#227); its Usage models section is the only attacker text it carries, cited by the AIVHAI threat model (#225).

### SewellBauereissCampbellEtAl-22

- **type**: misc
- **author**: Peter Sewell and Thomas Bauereiss and Brian Campbell and Robert N. M. Watson
- **title**: Formal CHERI: rigorous engineering and design-time proof of full-scale architecture security properties
- **howpublished**: Light Blue Touchpaper (University of Cambridge security group blog)
- **month**: jul
- **year**: 2022
- **url**: https://www.lightbluetouchpaper.org/2022/07/22/formal-cheri/
- **status**: published
- **observed**: 2026-09-30
- **licence**: no licence statement on the page; the post has no byline, and the author list is the Cambridge CHERI publications page's
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/SewellBauereissCampbellEtAl-22.md
- **pinned**: Internet Archive capture of 2026-06-13, https://web.archive.org/web/20260613141141/https://www.lightbluetouchpaper.org/2022/07/22/formal-cheri/
- **why**: A plain-language account of the Sail CHERI models and the design-time proofs of monotonicity and encapsulation that #4 and the Sail VME model build on (#4, #3, #122).

### Watson-26

- **type**: misc
- **author**: Robert N. M. Watson
- **title**: AIVHAI: Sprint 1 ISA issues identified
- **organization**: Capabilities Limited
- **version**: Google Doc as read on 2026-10-11 after its revision of 23:12 UTC, which adds a caveat that the results are preliminary and marks two passages not for public release; with comments by Jessica Clarke and Robert Watson.  A write-up for the AIVHAI team still being revised, to be re-snapshotted when it settles
- **year**: 2026
- **url**: https://docs.google.com/document/d/126qqL2Lal_ZZOBmMC-XBc7fuwM2QKCgQdbrD4n6J5Eo/edit
- **status**: living
- **observed**: 2026-10-11
- **licence**: Copyright Capabilities Limited; no licence stated.  Two passages are marked not for public release by the author (2026-10-11); a copy without them, `docs/red-team/sprint-1/isa-issues-2026-10-11.md`, is delivered to the red team with Joe Kiniry's approval, the red team being under NDA within the Safeguarded AI programme
- **redistribute**: no
- **ip-class**: foreground
- **access**: consortium-only
- **fulltext**: docs/bib/Watson-26.md
- **pinned**: Google Doc as read on 2026-10-11 (Google Docs exposes no stable revision identifier); the fixes it describes are `Capabilities-Limited/sail-cheri-riscv` `05b24fa`, `77e0312` and `84515a8`, carried by the Sprint 1 model pin `84515a8`
- **why**: Capabilities Limited's account of the two divergences of the RVY Sail model from the specification that Ben Laurie's Rocq proof of the compartment prologue found on 2026-10-11, and why model bugs matter: the source of threat model TM-003's completion and of TM-049, the evidence behind assumption A-1's two recorded failures in the assurance case, and the example `REDTEAM.md` gives of the findings most wanted (#255, #225, #226, #53).

### WatsonBaldwinChisnallEtAl-25

- **type**: article
- **author**: Robert N. M. Watson and John Baldwin and David Chisnall and Tony Chen and Jessica Clarke and Brooks Davis and Nathaniel Wesley Filardo and Brett Gutstein and Graeme Jenkinson and Ben Laurie and Alfredo Mazzinghi and Simon W. Moore and Peter G. Neumann and Hamed Okhravi and Alex Rebert and Alex Richardson and Peter Sewell and Laurence Tratt and Muralidaran Vijayaraghavan and Hugo Vincent and Konrad Witaszczyk
- **title**: It Is Time to Standardize Principles and Practices for Software Memory Safety
- **journal**: Communications of the ACM
- **volume**: 68
- **number**: 2
- **pages**: 40--45
- **publisher**: ACM
- **month**: feb
- **year**: 2025
- **doi**: 10.1145/3708553
- **url**: https://dl.acm.org/doi/10.1145/3708553
- **status**: published
- **observed**: 2026-09-30
- **licence**: "© 2025 Copyright held by the owner/author(s)", no licence statement (the typeset copy in MIT DSpace)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonBaldwinChisnallEtAl-25.pdf, docs/bib/WatsonBaldwinChisnallEtAl-25.md
- **pinned**: doi:10.1145/3708553
- **why**: Policy background: the memory-safety case AIVHAI's claims sit within, useful for red-team and funder framing rather than as a technical dependency (#53, #122).

### WatsonChisnallClarkeEtAl-24

- **type**: article
- **author**: Robert N. M. Watson and David Chisnall and Jessica Clarke and Brooks Davis and Nathaniel Wesley Filardo and Ben Laurie and Simon W. Moore and Peter G. Neumann and Alexander Richardson and Peter Sewell and Konrad Witaszczyk and Jonathan Woodruff
- **title**: CHERI: Hardware-Enabled C/C++ Memory Protection at Scale
- **journal**: IEEE Security & Privacy
- **volume**: 22
- **number**: 4
- **pages**: 50--61
- **publisher**: IEEE Computer Society
- **month**: jul
- **year**: 2024
- **doi**: 10.1109/MSEC.2024.3396701
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/20240419-ieeesp-cheri-memory-safety.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "© 2024 IEEE" (first page of the author version)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonChisnallClarkeEtAl-24.pdf, docs/bib/WatsonChisnallClarkeEtAl-24.md
- **pinned**: doi:10.1109/MSEC.2024.3396701
- **why**: Background: an overview of CHERI, CHERI C/C++, Morello, and CHERIoT, for orientation (#1, #122).

### WatsonNeumannMoore-18

- **type**: incollection
- **author**: Robert N. M. Watson and Peter G. Neumann and Simon W. Moore
- **title**: Balancing Disruption and Deployability in the CHERI Instruction-Set Architecture (ISA)
- **booktitle**: New Solutions for Cybersecurity
- **editor**: Howard Shrobe and David L. Shrier and Alex Pentland
- **pages**: 163--198
- **publisher**: MIT Press
- **month**: jan
- **year**: 2018
- **doi**: 10.7551/mitpress/11636.003.0008
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2017mit-cybersecurity-cheri-web.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author's pre-publication version of 2017-05-11; MIT Press copyright on the published chapter
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonNeumannMoore-18.pdf, docs/bib/WatsonNeumannMoore-18.md
- **pinned**: doi:10.7551/mitpress/11636.003.0008; the committed PDF is the 2017 pre-publication version
- **why**: Background: the CHERI design philosophy and how the ISA evolved (#1, #122).

### WatsonNeumannWoodruffEtAl-23

- **type**: techreport
- **author**: Robert N. M. Watson and Peter G. Neumann and Jonathan Woodruff and Michael Roe and Hesham Almatary and Jonathan Anderson and John Baldwin and Graeme Barnes and David Chisnall and Jessica Clarke and Brooks Davis and Lee Eisen and Nathaniel Wesley Filardo and Franz A. Fuchs and Richard Grisenthwaite and Alexandre Joannou and Ben Laurie and A. Theodore Markettos and Simon W. Moore and Steven J. Murdoch and Kyndylan Nienhuis and Robert Norton and Alexander Richardson and Peter Rugg and Peter Sewell and Stacey Son and Hongyan Xia
- **title**: Capability Hardware Enhanced RISC Instructions: CHERI Instruction-Set Architecture (Version 9)
- **institution**: University of Cambridge, Computer Laboratory
- **number**: UCAM-CL-TR-987
- **version**: 9
- **month**: sep
- **year**: 2023
- **doi**: 10.48456/tr-987
- **url**: https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-987.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: CC-BY-4.0, University of Cambridge marks excluded (page 2); the embedded Sail pseudocode is BSD-2-Clause (page 3)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonNeumannWoodruffEtAl-23.pdf, docs/bib/WatsonNeumannWoodruffEtAl-23.md
- **pinned**: UCAM-CL-TR-987 (doi:10.48456/tr-987)
- **why**: The CHERI architecture reference from which CHERI-RISC-V, and so RVY and CVA6-CHERI, descend (#52 C2).

### WatsonNortonWoodruffEtAl-16

- **type**: article
- **author**: Robert N. M. Watson and Robert Norton and Jonathan Woodruff and Alexandre Joannou and Simon W. Moore and Peter G. Neumann and Jonathan Anderson and David Chisnall and Nirav Dave and Brooks Davis and Khilan Gudka and Ben Laurie and A. Theodore Markettos and J. Edward Maste and Steven J. Murdoch and Michael Roe and Colin Rothwell and Stacey Son and Munraj Vadera
- **title**: Fast Protection-Domain Crossing in the CHERI Capability-System Architecture
- **journal**: IEEE Micro
- **volume**: 36
- **number**: 5
- **pages**: 38--49
- **publisher**: IEEE
- **month**: sep
- **year**: 2016
- **doi**: 10.1109/MM.2016.84
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/20160728micro-journal-cheri-final.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author's final submission; IEEE copyright on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonNortonWoodruffEtAl-16.pdf, docs/bib/WatsonNortonWoodruffEtAl-16.md
- **pinned**: doi:10.1109/MM.2016.84
- **why**: Sealed capabilities, hardware-checked domain switching, and register clearing between mutually distrusting domains: the mechanisms the firmware uses to switch between AI-model compartments (#59, #1, #122).

### WatsonRichardsonClarkeEtAl-23

- **type**: misc
- **author**: Robert N. M. Watson and Alexander Richardson and Jessica Clarke and Brooks Davis and John Baldwin and David Chisnall and Nathaniel Filardo and Simon W. Moore and Edward Napierala and Peter Sewell and Peter G. Neumann
- **title**: CHERI Hybrid-Capability C/C++ Programming Guide (draft)
- **version**: draft of 2023-02-01, commit da652aaca7f803c672b31bd90a415ddd39b35aa6
- **month**: feb
- **year**: 2023
- **url**: https://github.com/CTSRD-CHERI/cheri-hybrid-c-guide/releases/tag/draft-20230201-da652aaca7f803c672b31bd90a415ddd39b35aa6
- **status**: draft
- **observed**: 2026-09-30
- **licence**: none stated: the repository has no LICENSE or COPYING file, and neither the LaTeX source nor the PDF carries a licence or copyright line
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonRichardsonClarkeEtAl-23.pdf, docs/bib/WatsonRichardsonClarkeEtAl-23.md
- **pinned**: commit da652aaca7f803c672b31bd90a415ddd39b35aa6, which is also the repository's head; unmaintained since
- **why**: The only written account of hybrid-capability C/C++, the mode boot and trap-entry code in the firmware may use; cite only, and prefer [@WatsonRichardsonDavisEtAl-26] wherever they overlap (#55).

### WatsonRichardsonDavisEtAl-20

- **type**: techreport
- **author**: Robert N. M. Watson and Alexander Richardson and Brooks Davis and John Baldwin and David Chisnall and Jessica Clarke and Nathaniel Filardo and Simon W. Moore and Edward Napierala and Peter Sewell and Peter G. Neumann
- **title**: CHERI C/C++ Programming Guide
- **institution**: University of Cambridge, Computer Laboratory
- **number**: UCAM-CL-TR-947
- **month**: jun
- **year**: 2020
- **doi**: 10.48456/tr-947
- **url**: https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: all rights reserved: a copyright notice for the eleven authors and SRI International, with no licence grant (page 2)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonRichardsonDavisEtAl-20.pdf, docs/bib/WatsonRichardsonDavisEtAl-20.md
- **pinned**: UCAM-CL-TR-947 (doi:10.48456/tr-947)
- **why**: The stable, citable edition of the CHERI C/C++ guide; cite it for settled claims, and [@WatsonRichardsonDavisEtAl-26] for current guidance (#55).

### WatsonRichardsonDavisEtAl-26

- **type**: manual
- **author**: Robert N. M. Watson and Alexander Richardson and Brooks Davis and John Baldwin and David Chisnall and Jessica Clarke and Nathaniel Filardo and Simon W. Moore and Edward Napierala and Allison Randal and Peter Sewell and Peter G. Neumann
- **title**: CHERI C/C++ Programming Guide (living web edition)
- **organization**: University of Cambridge
- **version**: CTSRD-CHERI/cheri-c-programming commit df9b68131d09afe4d694b3594a1f88b125cbcd65 (2026-09-05)
- **year**: 2026
- **url**: https://ctsrd-cheri.github.io/cheri-c-programming/
- **status**: living
- **observed**: 2026-09-30
- **licence**: BSD-2-Clause, "Copyright (c) 2022 Robert N. M. Watson" (the repository's LICENSE; GitHub reports NOASSERTION because of a non-standard preamble)
- **redistribute**: yes
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonRichardsonDavisEtAl-26.md
- **pinned**: commit df9b68131d09afe4d694b3594a1f88b125cbcd65 of CTSRD-CHERI/cheri-c-programming
- **why**: Current CHERI C/C++ guidance, which the firmware prototypes and the CHERI agent prelude (#52 B4) follow; unlike the 2020 report it may be reproduced, with its licence attached, and it has diverged materially from that report (#55).

### WatsonWoodruffNeumannEtAl-15

- **type**: inproceedings
- **author**: Robert N. M. Watson and Jonathan Woodruff and Peter G. Neumann and Simon W. Moore and Jonathan Anderson and David Chisnall and Nirav Dave and Brooks Davis and Khilan Gudka and Ben Laurie and Steven J. Murdoch and Robert Norton and Michael Roe and Stacey Son and Munraj Vadera
- **title**: CHERI: A Hybrid Capability-System Architecture for Scalable Software Compartmentalization
- **booktitle**: Proceedings of the 36th IEEE Symposium on Security and Privacy (SP 2015)
- **publisher**: IEEE
- **pages**: 20--37
- **month**: may
- **year**: 2015
- **doi**: 10.1109/SP.2015.9
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201505-oakland2015-cheri-compartmentalization.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author version; IEEE copyright on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WatsonWoodruffNeumannEtAl-15.pdf, docs/bib/WatsonWoodruffNeumannEtAl-15.md
- **pinned**: doi:10.1109/SP.2015.9
- **why**: The foundational paper on CHERI object-capability compartmentalisation, sealing, and domain crossing, the model the firmware's isolation work builds on (#59, #1, #122).

### WoodruffJoannouXiaEtAl-19

- **type**: article
- **author**: Jonathan Woodruff and Alexandre Joannou and Hongyan Xia and Anthony Fox and Robert Norton and Thomas Bauereiss and David Chisnall and Brooks Davis and Khilan Gudka and Nathaniel W. Filardo and A. Theodore Markettos and Michael Roe and Peter G. Neumann and Robert N. M. Watson and Simon W. Moore
- **title**: CHERI Concentrate: Practical Compressed Capabilities
- **journal**: IEEE Transactions on Computers
- **volume**: 68
- **number**: 10
- **pages**: 1455--1469
- **publisher**: IEEE
- **month**: oct
- **year**: 2019
- **doi**: 10.1109/TC.2019.2914037
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/2019tc-cheri-concentrate.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author copy; IEEE copyright on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WoodruffJoannouXiaEtAl-19.pdf, docs/bib/WoodruffJoannouXiaEtAl-19.md
- **pinned**: doi:10.1109/TC.2019.2914037
- **why**: Defines the compressed capability-bounds encoding, with a HOL4 machine-checked proof of decode and pointer modification, which the monotonicity proof and the Sail model must reason about when bounds are not exactly representable (#4, #3, #122).

### WoodruffWatsonChisnallEtAl-14

- **type**: inproceedings
- **author**: Jonathan Woodruff and Robert N. M. Watson and David Chisnall and Simon W. Moore and Jonathan Anderson and Brooks Davis and Ben Laurie and Peter G. Neumann and Robert Norton and Michael Roe
- **title**: The CHERI Capability Model: Revisiting RISC in an Age of Risk
- **booktitle**: Proceedings of the 41st ACM/IEEE International Symposium on Computer Architecture (ISCA 2014)
- **publisher**: IEEE
- **pages**: 457--468
- **month**: jun
- **year**: 2014
- **doi**: 10.1109/ISCA.2014.6853201
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201406-isca2014-cheri.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: "(c) 2014 IEEE" (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/WoodruffWatsonChisnallEtAl-14.pdf, docs/bib/WoodruffWatsonChisnallEtAl-14.md
- **pinned**: doi:10.1109/ISCA.2014.6853201
- **why**: The original CHERI capability model with tagged memory, where unforgeability is first stated as a requirement: the origin of the property the monotonicity proof formalises (#4, #122).

### XiaWoodruffAinsworthEtAl-19

- **type**: inproceedings
- **author**: Hongyan Xia and Jonathan Woodruff and Sam Ainsworth and Nathaniel W. Filardo and Michael Roe and Alexander Richardson and Peter Rugg and Peter G. Neumann and Simon W. Moore and Robert N. M. Watson and Timothy M. Jones
- **title**: CHERIvoke: Characterising Pointer Revocation using CHERI Capabilities for Temporal Memory Safety
- **booktitle**: Proceedings of the 52nd Annual IEEE/ACM International Symposium on Microarchitecture (MICRO-52)
- **pages**: 545--557
- **publisher**: ACM
- **month**: oct
- **year**: 2019
- **doi**: 10.1145/3352460.3358288
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201910micro-cheri-temporal-safety.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: copyright held by the owner/author(s), publication rights licensed to ACM (first page); personal and classroom use only
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/XiaWoodruffAinsworthEtAl-19.pdf, docs/bib/XiaWoodruffAinsworthEtAl-19.md
- **pinned**: doi:10.1145/3352460.3358288
- **why**: Capability revocation by sweeping tagged memory, which the firmware needs when it takes capabilities back from a tenant being torn down, such as NPU buffer capabilities (#1, #122).

### XiaWoodruffBarralEtAl-18

- **type**: inproceedings
- **author**: Hongyan Xia and Jonathan Woodruff and Hadrien Barral and Lawrence Esswood and Alexandre Joannou and Robert Kovacsics and David Chisnall and Michael Roe and Brooks Davis and Edward Napierala and John Baldwin and Khilan Gudka and Peter G. Neumann and Alex Richardson and Simon W. Moore and Robert N. M. Watson
- **title**: CheriRTOS: A Capability Model for Embedded Devices
- **booktitle**: 2018 IEEE 36th International Conference on Computer Design (ICCD)
- **pages**: 92--99
- **publisher**: IEEE
- **month**: oct
- **year**: 2018
- **doi**: 10.1109/ICCD.2018.00023
- **url**: https://www.cl.cam.ac.uk/research/security/ctsrd/pdfs/201810-iccd2018-cheri-rtos.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: no statement on the author copy; IEEE copyright on the published version
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/XiaWoodruffBarralEtAl-18.pdf, docs/bib/XiaWoodruffBarralEtAl-18.md
- **pinned**: doi:10.1109/ICCD.2018.00023
- **why**: An early CHERI embedded compartmentalisation design, a precursor to the CHERIoT isolation model AIVHAI extends to 64 bits (#59, #122).

### ZalivaMemarianAlmeidaEtAl-24

- **type**: inproceedings
- **author**: Vadim Zaliva and Kayvan Memarian and Ricardo Almeida and Jessica Clarke and Brooks Davis and Alexander Richardson and David Chisnall and Brian Campbell and Ian Stark and Robert N. M. Watson and Peter Sewell
- **title**: Formal Mechanised Semantics of CHERI C: Capabilities, Undefined Behaviour, and Provenance
- **booktitle**: Proceedings of the 29th ACM International Conference on Architectural Support for Programming Languages and Operating Systems, Volume 1 (ASPLOS '24)
- **pages**: 181--196
- **publisher**: ACM
- **month**: apr
- **year**: 2024
- **doi**: 10.1145/3617232.3624859
- **url**: http://www.cl.cam.ac.uk/users/pes20/asplos24spring-paper110.pdf
- **status**: published
- **observed**: 2026-09-30
- **licence**: ACM author-rights notice, personal and classroom use only (first page)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ZalivaMemarianAlmeidaEtAl-24.pdf, docs/bib/ZalivaMemarianAlmeidaEtAl-24.md
- **pinned**: doi:10.1145/3617232.3624859
- **why**: A mechanised Coq semantics of CHERI C, for specifying and verifying the C parts of the firmware against a capability-aware source semantics (#1, #122).

### ZarubaBenini-19

- **type**: article
- **author**: Florian Zaruba and Luca Benini
- **title**: The Cost of Application-Class Processing: Energy and Performance Analysis of a Linux-Ready 1.7-GHz 64-Bit RISC-V Core in 22-nm FDSOI Technology
- **journal**: IEEE Transactions on Very Large Scale Integration (VLSI) Systems
- **volume**: 27
- **number**: 11
- **pages**: 2629--2640
- **month**: nov
- **year**: 2019
- **doi**: 10.1109/TVLSI.2019.2926114
- **url**: https://arxiv.org/abs/1904.05442
- **status**: published
- **observed**: 2026-09-30
- **licence**: IEEE copyright; the committed PDF is the author preprint, arXiv:1904.05442v1, under arXiv's non-exclusive distribution licence ("Permission from IEEE must be obtained for all other uses", page 1)
- **redistribute**: no
- **ip-class**: background
- **access**: public
- **fulltext**: docs/bib/ZarubaBenini-19.pdf, docs/bib/ZarubaBenini-19.md
- **pinned**: doi:10.1109/TVLSI.2019.2926114
- **why**: The reference paper for CVA6 (then Ariane), the core that CVA6-CHERI extends and that proof target c verifies (#1).

<!--
Local Variables:
auto-fill-mode: nil
End:
-->
