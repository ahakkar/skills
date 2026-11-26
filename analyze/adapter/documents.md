# Adapter: documents (PDF, Word, Excel, PowerPoint)

Read by the orchestrator. Copy the parts lanes need into `BRIEF.md`.

## Material
- The files as given. Record each file's name and `sha256sum` in `RUN.md`.
- A paper with code or data: add the code adapter, and use the commit from when the
  study ran.
- Convert each file by script into the run directory, with a short key per file:
  `uv run --no-project ~/.claude/skills/analyze/tool/convert.py <file> sources/<key>/`
  Record each key, its file and the script's output in `RUN.md`.
- Too much to read closely: give each file a reading tier next to its key in `RUN.md`,
  and say in `BRIEF.md` how each lane reads its files. `core`: read closely. `mine`: pull
  out specific points. `stats`: summarise by script, plus samples. `skip`: one line why.
- `.txt`, `.md` and `.csv` need no conversion: copy them into `sources/`.
- PDF pages are physical pages, not the printed page numbers. Say so in `prose/method.md`.
- A PDF page with no text is an image. List it in `RUN.md`; read it as an image or mark
  it unchecked.

## Location format
`path:line` or `path:start-end` in the converted files. The file name says where:
- PDF `sources/<key>/p07.txt:12`: page 7.
- PowerPoint `sources/<key>/s03.txt:4`: slide 3.
- Excel `sources/<key>/sheet02-Name.txt:36`: sheet 2, row 36. Line number = row number.
- Word `sources/<key>/doc.txt:120`: Word has no fixed pages.

`quote`: verbatim from those lines, at most 40 words, within one file. Figure and table
text in a PDF can land out of order; quote running text where possible.

## Environment check
- `uv`, and `pdftotext` (poppler-utils) for PDFs.

## What can be checked by running something
- `uv run --no-project tool/check_citations.py --root <repo or .> data/*.yaml`
- Counts over a large sheet (rows per category, keyword matches): by script, with the
  command and its output saved in `sources/`.

## Hard rules for lanes
- Read the converted files, not the originals: quotes must match the text the checker
  reads.
- Read-only. Write only the lane's own files in the run directory.
- Allowed commands: `grep`, `find`, `wc`, `sed -n`.
