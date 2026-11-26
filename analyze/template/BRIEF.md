# Brief: <title>

You are one agent in a small, read-only analysis. You start with no prior context:
everything you need is in this file and in the target. Your output is data (YAML) and
prose (Markdown) in this run directory.

Goal: <one sentence: the question and who reads the answer>.

## 1. Context
- What the target is, its stack and size (from `sources/repo_stats.txt`), at commit `<sha>`.
- Known quirks: framework versions, generated code, odd layout.
- Claims to verify, not truth: <README, CLAUDE.md, current presentation text, paper>.

## 2. Hard rules
<from the adapter: read-only, own files only, no live services, no .env values,
allowed commands>

## 3. Lanes
### Agent A: <role>
Owns: `data/findings-a.yaml`, `prose/a.md`. IDs `A-01`…
- <checklist for this lane, specific to the question and the target>

### Agent B: <role>
...

Stay in your lane. Something for another lane goes in one line under
"# Notes for other agents" at the end of your prose file.

## 4. Evidence
- Location format: <from the adapter>.
- Every item has a location you actually looked at and a verbatim quote of at most
  40 words. Not confirmed: `confidence: suspected`.
- Budget: at most <N> items per agent, ranked by importance.

## 5. Formats
<the findings schema and rules from the skill>
- YAML: every file is a top-level list, `[]` if empty. Use `|` for multi-line text.
  Quote any string containing `:` `#` `{` `[` `*` `&` `!` `|` `>` `'` `"` `%` `@` or a
  leading `-`.
- Prose: Markdown, `#` per section, no tables, no raw HTML. No quotes: quotes live in the
  YAML, where they are checked. Refer to findings by ID, e.g. `[A-01]`.

## 6. Finish
- Run `uv run --no-project tool/check_citations.py --root <repo> data/*.yaml` from this
  run directory. Fix your own items until every quote is OK.
- Run `typst compile report.typ REPORT.pdf` from this run directory. Other agents' files
  may still be empty stubs. If it fails on your file, fix your YAML or Markdown, never
  `report.typ`.
- Reply in at most 5 lines: item counts and what you couldn't check.
