#!/usr/bin/env bash
# aivhai-cd-smoke --- the CD image renders what it claims to render.
#
# Status:  Living script
# Version: 0.3.1
# Date:    2026-10-09
# Project: AIVHAI
# Issue:   https://github.com/Sigil-Logic/AIVHAI-Sigil/issues/156
#
# Installed in the image as /usr/local/bin/aivhai-cd-smoke.  Run at build
# time, and again by containers.yml with --network none, because CD runs
# offline once the image is pulled and a renderer that quietly reaches for the
# network would fail there and nowhere else.
#
# SCOPE.  Representative renders of each tool the image carries, checked for
# CONTENT: a document through both TeX engines, a Mermaid and a PlantUML
# diagram, and each diagram inside a PDF.  It is the image's test, not the CD
# service's; what the service renders, and its own checks, are #153's.
#
# CONTENT, NOT EXISTENCE.  Every output is checked for text the fixture put in
# it, read back out of the SVG or the PDF.  Cycle 1 of PR #233's review found
# that an existence check passed a PDF whose embedded Mermaid diagram had lost
# every label (HOARDE Codex): Mermaid's default HTML labels are invisible to
# rsvg-convert.  The labels below are distinct words so a check cannot pass on
# text from elsewhere in the document.
#
# NO `set -e`, AND NO `cmd | grep -q`.  A failure is recorded and the checks
# continue, so one run reports every defect.  And under pipefail `grep -q`
# exiting at its first match kills its producer with SIGPIPE, so a pipeline
# reports failure for text that IS there; that false failure stopped two
# builds on PR #233.  Every producer's output is captured, its status checked,
# and then searched.
#
# NEGATIVE CONTROL.  A document with an undefined LaTeX command must fail to
# render, and for that reason: XeLaTeX must report `Undefined control
# sequence`.  A failure for any other reason proves nothing about the checks.

set -uo pipefail

work=$(mktemp -d) || { echo "aivhai-cd-smoke: cannot create a work directory" >&2; exit 1; }
trap 'rm -rf "$work"' EXIT
cd "$work" || exit 1

failures=0
ok()   { printf '  ok    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

# has TEXT WORD... -- every WORD occurs in TEXT.
has() {
  local text=$1 w; shift
  for w in "$@"; do
    grep -qF -- "$w" <<<"$text" || return 1
  done
}

# pdf_text FILE -- the text of FILE, or a failure if it is not a PDF or
# pdftotext cannot read it.  The caller checks the status.
pdf_text() {
  [ -s "$1" ] && [ "$(head -c 5 "$1")" = '%PDF-' ] || return 1
  pdftotext "$1" -
}

# first_line CMD... -- the first line of CMD's output, captured whole first.
first_line() {
  local out
  out=$("$@" 2>&1) || true
  printf '%s\n' "${out%%$'\n'*}"
}

echo "aivhai-cd-smoke: tools"
missing=0
for t in bash git gh jq make python3 curl pandoc xelatex lualatex java dot rsvg-convert pdftotext node npm mmdc plantuml fc-list; do
  command -v "$t" >/dev/null || { fail "$t is not on PATH"; missing=1; }
done
[ "$missing" -eq 0 ] && ok "every tool is on PATH"

shells=$(find /opt/aivhai/puppeteer -name chrome-headless-shell -type f 2>/dev/null)
if [ -n "$shells" ] && [ "$(grep -c . <<<"$shells")" -eq 1 ]; then
  ok "one browser: $(first_line "$shells" --version)"
else
  fail "expected exactly one Chrome headless shell, found: ${shells:-none}"
fi

printf '  %s\n' \
  "$(first_line pandoc --version)" \
  "$(first_line xelatex --version)" \
  "node $(first_line node --version)" \
  "mmdc $(first_line mmdc --version)" \
  "mermaid $(jq -r .version /opt/aivhai/mermaid/node_modules/mermaid/package.json 2>/dev/null)" \
  "$(first_line plantuml -version)"

echo "aivhai-cd-smoke: fonts"
if fonts=$(fc-list); then
  for f in 'DejaVu Sans Mono' 'DejaVu Sans' 'Liberation Serif' 'Latin Modern Roman'; do
    if grep -qiF -- "$f" <<<"$fonts"; then ok "$f"; else fail "$f is not installed"; fi
  done
else
  fail "fc-list failed; no font could be checked"
fi

echo "aivhai-cd-smoke: documents"
# Every header field carries a distinct value, so each one's survival into the
# PDF is checked separately.  Box drawing in a code block is the reason for
# DejaVu Sans Mono.
cat > doc.md <<'EOF'
# CD smoke document

**Status**: Smokestatus
**Version**: 9.8.7
**Project**: Smokeproject

| Engine   | Role            |
|----------|-----------------|
| XeLaTeX  | the default     |
| LuaLaTeX | the alternative |

```
┌──────────┐
│ verified │
└──────────┘
```
EOF
for engine in xelatex lualatex; do
  if ! pandoc doc.md --from markdown-smart --pdf-engine="$engine" \
       --variable 'monofont=DejaVu Sans Mono' -o "doc-$engine.pdf" 2>"doc-$engine.err"; then
    fail "pandoc could not render Markdown with $engine: $(first_line cat "doc-$engine.err")"
    continue
  fi
  if ! text=$(pdf_text "doc-$engine.pdf"); then
    fail "$engine produced no readable PDF"
  elif has "$text" 'Status: Smokestatus' 'Version: 9.8.7' 'Project: Smokeproject' 'LuaLaTeX' 'verified'; then
    ok "Markdown to PDF through $engine; every header field, the table, and the code block are in its text"
  else
    fail "$engine's PDF lost text from the document: header fields, table, or code block"
  fi
done

echo "aivhai-cd-smoke: diagrams"
# Each fixture's labels are listed once and reused for its SVG, its PDF, and
# the document that embeds it, so no check can quietly skip one (HOARDE
# Codex, PR #233 review cycle 2: the embedded check had dropped Specword).
flow_labels=(Specword Proofword Evidenceword)
class_labels=(Capabilityword Compartmentword)
printf '%s\n' 'flowchart LR' "  ${flow_labels[0]} --> ${flow_labels[1]} --> ${flow_labels[2]}" > flow.mmd
if ! mmdc -i flow.mmd -o flow.svg >/dev/null 2>mmdc.err; then
  fail "mmdc could not render a flowchart: $(first_line cat mmdc.err)"
elif ! svg=$(cat flow.svg 2>/dev/null) || ! has "$svg" '<svg' "${flow_labels[@]}"; then
  fail "the Mermaid SVG does not carry its three labels"
elif grep -qF 'foreignObject' <<<"$svg"; then
  fail "the Mermaid SVG draws labels as HTML (foreignObject), which a PDF loses"
else
  ok "Mermaid flowchart to SVG, labels as SVG text"
fi

printf '%s\n' '@startuml' "class ${class_labels[0]}" "class ${class_labels[1]}" "${class_labels[1]} --> ${class_labels[0]}" '@enduml' > class.puml
if ! plantuml -tsvg class.puml >/dev/null 2>plantuml.err; then
  fail "PlantUML could not render a class diagram: $(first_line cat plantuml.err)"
elif ! svg=$(cat class.svg 2>/dev/null) || ! has "$svg" '<svg' "${class_labels[@]}"; then
  fail "the PlantUML SVG does not carry its two class names"
else
  ok "PlantUML class diagram to SVG, through Graphviz, with both class names"
fi

if ! rsvg-convert -f pdf -o flow.pdf flow.svg 2>/dev/null; then
  fail "rsvg-convert could not convert the Mermaid SVG to PDF"
elif ! text=$(pdf_text flow.pdf) || ! has "$text" "${flow_labels[@]}"; then
  fail "the Mermaid diagram converted to PDF lost its labels"
else
  ok "Mermaid SVG to PDF through rsvg-convert, labels intact"
fi

printf '%s\n' '# Diagrams in a document' '' '![flow](flow.svg)' '' '![class](class.svg)' > fig.md
if ! pandoc fig.md --from markdown-smart --pdf-engine=xelatex -o fig.pdf 2>fig.err; then
  fail "pandoc could not embed SVG diagrams in a PDF: $(first_line cat fig.err)"
elif ! text=$(pdf_text fig.pdf) || ! has "$text" "${flow_labels[@]}" "${class_labels[@]}"; then
  fail "a document's embedded diagrams lost their labels in the PDF"
else
  ok "a document with both diagrams to PDF, every label in its text"
fi

echo "aivhai-cd-smoke: negative control"
printf '%s\n' '# Broken' '' '\aivhaiUndefinedCommand' > broken.md
if pandoc broken.md --from markdown-smart --pdf-engine=xelatex -o broken.pdf 2>broken.err; then
  fail "a document with an undefined LaTeX command rendered; the checks above prove nothing"
elif grep -qF 'Undefined control sequence' broken.err; then
  ok "a broken document fails to render, for the expected reason"
else
  fail "the broken document failed, but not with 'Undefined control sequence': $(first_line cat broken.err)"
fi

if [ "$failures" -gt 0 ]; then
  echo "aivhai-cd-smoke: $failures check(s) FAILED" >&2
  exit 1
fi
echo "aivhai-cd-smoke: all checks passed"
