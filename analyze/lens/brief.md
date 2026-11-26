# Lens: brief

What do the documents say about the question? Facts only, each with its quote and
location, set out by the parts of the question so the reader can act on them without
reading the documents. Ported from one tender briefing; its chapters and tables followed
that run's question, so here they are examples, not fixed sections. Read by the
orchestrator; copy what lanes need into `BRIEF.md`.

## Fields added to findings
- `chapter`: a key from `chapters` in `data/meta.yaml`. Required, except on a table row.
- `kind`: optional, default `fact`.
  - `fact`: what the documents state.
  - `open`: what the documents themselves leave open: a range, a placeholder, "to be
    agreed", "specified in the final version".
  - `conflict`: two places say different things. `claim` holds one statement;
    `location` and `quote` hold the other.
  - `gap`: what the question needs and no document says. Written by the merge (see
    Merge); `location` and `quote` are the saved search that found nothing.
- `table` and `cells`: the finding is a row of that table (a key from `tables` in meta),
  with one value per column. A row is shown in its table only, not again as an entry.

      - id: B-07
        table: timeline
        cells: {date: "2027-03-15", event: "Last day for questions"}
        finding: "Questions must reach the buyer by 15 March 2027."
        severity: medium
        confidence: verified
        location: sources/call/p04.txt:22
        quote: "Questions shall be submitted in writing no later than 15 March 2027."

      - id: A-12
        kind: conflict
        chapter: contract
        finding: "The call gives the term as four years, the draft contract as three."
        severity: high
        confidence: verified
        location: sources/contract/p02.txt:8
        quote: "This agreement shall remain in force for three (3) years"
        claim:
          location: sources/call/p01.txt:30
          quote: "The contract will be concluded for four years."
          status: unverifiable

## Judgement: facts only
- Lanes and the merge state what the documents say. No evaluation, recommendation or
  inference: not "the support terms are vague" but "the support terms give no response
  time". Saying what a document doesn't define is a fact.
- `finding`: one short statement in the report's language. `quote` stays verbatim, in
  the document's language.
- Severity is how much the fact matters to the answer, not whether it is good or bad:
  - `high`: the reader can't answer a part of the question, or act, without it.
  - `medium`: shapes an answer.
  - `low`: background.
- Numbers as the documents state them, with their unit. A sum, a count, or the time
  between two dates is computed by script, with the command and output in `sources/`.
- `claim.status` on a `conflict` says whether the documents settle it: `wrong` when they
  say which statement prevails (an order of precedence, a later version that replaces
  the earlier; cite that in `location` too), `unverifiable` when they don't. Lanes don't
  pick a side. Only conflicts have `claim` in this lens.
- Templates, blank forms and standard terms: say so in the lane's document notes. A
  blank form tells what it asks for, not the answers. A standard clause gets at most one
  finding, unless the documents deviate from it.
- One fact, one finding, under the chapter it serves best.
- Lane prose is printed in the report, so it is in the report's language, headings
  included. Translate the BRIEF's "Notes for other agents" heading too.

## Chapters and tables
`data/meta.yaml` lists both, so a run changes `meta.yaml`, not the template. A layout the
template can't produce is fixed in the skill's `template/`.

- `chapters: [{key, title, tables}]`, in report order. Each chapter prints
  `prose/chapter-<key>.md`, then its tables, then its other findings. Typical:
  - first, a reading guide: what the brief is and isn't, how to read a citation (see
    Report), the kinds, and the document map;
  - one chapter per part of the question;
  - last, what the documents leave open: the `open`, `conflict` and `gap` findings, so
    the reader finds what to ask in one place. The source run did this.
- `tables: [{key, title, columns, sort, file}]`. The question decides which. Without
  `file`, the rows are the findings with `table: <key>`, and the template adds an ID
  column and a location column. With `file`, each entry in that file is a row.
  `columns: [{key, name, width, values}]`: `width` is `auto` or a weight (default 1);
  `values` maps a stored value to the text shown. `sort` names the column that orders
  the rows (default: by ID, or file order). Each table sits in exactly one chapter.
- Examples from the tender briefing: key facts (`fact`, `value`), timeline (`date`,
  `event`, sorted by date, dates as `YYYY-MM-DD`), award criteria (`criterion`,
  `weight`, `assessed_from`).
- The document map and the list of sources: `data/documents.yaml`, one entry per
  document in the order the list prints them, written at step 2 from each document's
  own title page or first lines. The reading tiers go here instead of `RUN.md`, and
  `RUN.md` points to it. The merge updates `why` from the lanes' document notes.
  - `key`: the document's folder under `sources/`. Not `absence`, which holds searches.
  - `short`: the label citations print. Unique, and readable at a glance among similar
    names: `ITT A2` for annex 2 of the invitation to tender, not `Annex`.
  - `title`, and `author` (who issued it), `date` and `note` (case number, version) when
    the document gives them. `file`: the file name as given.
  - `tier` and `why`.

      # data/documents.yaml
      - key: a2
        short: "ITT A2"
        title: "Invitation to tender, annex 2: Description of the procurement"
        author: "City of Example"
        date: "2027-02-01"
        note: "Case 123/2026, preliminary version"
        file: "Preliminary ITT - Annex 2 Description of the procurement.pdf"
        tier: core
        why: "Scope, the systems to replace and the integrations."

      # data/meta.yaml
      tables:
        - key: documents
          title: "Documents"
          file: data/documents.yaml
          columns:
            - {key: short, name: "Label", width: auto}
            - {key: title, name: "Document", width: 2}
            - {key: tier, name: "Read", width: auto,
               values: {core: "closely", mine: "for points", stats: "by script", skip: "not read"}}
            - {key: why, name: "Why", width: 3}

## Labels
The template prints no text of its own: every fixed heading and label comes from
`labels` in `data/meta.yaml`, in the report's language. The build stops on a missing one.
Copy this block and translate the values:

    labels:
      target: "Target"             # title page
      version: "Version"
      date: "Date"
      agents: "Agents"
      contents: "Contents"
      summary: "Summary"
      facts: "Facts and sources"   # heading over a chapter's findings
      id: "ID"                     # table column
      source: "Source"             # table column and entry
      conflicts-with: "Conflicts with"
      searched: "Searched"         # a gap's search
      check: "Claim check"
      none: "None recorded."
      lanes: "Lane notes"
      method: "Method and limits"
      open: "open"                 # kinds
      conflict: "conflict"
      gap: "gap"
      suspected: "suspected"
      holds: "holds"               # claim check verdicts
      weakened: "weakened"
      wrong: "wrong"               # also: a conflict the documents settle against it
      unverifiable: "not settled"  # a conflict the documents don't settle
      sources: "Sources"           # the list of sources, last in the report
      page: "p. {}"                # where a citation points: [ITT A2, p. 7]
      slide: "slide {}"            # {} is the number, the sheet's name or the lines
      sheet: "sheet {}"
      row: "row {}"
      line: "line {}"              # a .txt, .md or .csv source

## Typical lanes
One lane per group of related documents, not per chapter: a contract stays with its
annexes, a call with its answers to questions. Each lane covers every chapter for its
own documents. The source run used four lanes for a few dozen documents; more would
have split related documents and made the merge harder. Extraction is mechanical, so
lanes run on Sonnet. Budget: at most 40 findings per lane, table rows included; the plan
may raise it for a large group.

Each lane reads its own documents at their tier in `data/documents.yaml`. It may grep
other documents only to follow a cross-reference. Its checklist, made specific to the
question:
- For each chapter: the facts its part of the question needs.
- Numbers: every date, duration, option, weight, point scale, count, amount, service
  level and penalty, as a table row where a table takes it.
- What the documents leave open (`open`), and conflicts within the lane's documents.
- Prose, with headings in the report's language: documents, one line each (what it is:
  substantive, template, standard terms or duplicate; how much it holds for the
  question); and not found: what the question needs that the lane's documents don't say.

A `stats` document, such as a large requirements sheet, is summarised by a script
written for the run: counts per category, keyword matches with their rows. The command
and output go in `sources/`; lanes read the output and the matched rows. The skill ships
no such script, since what to count depends on the sheet.

## Merge
In the main session, with the default model. After the core merge (duplicates,
calibration, IDs everywhere):
- Conflicts across lanes: turn one of the two findings into a `conflict` with the
  other's location and quote as its `claim`, and remove the other.
- Gaps: for each "not found" line, search every document (file names, contents,
  synonyms). Save the commands and their output in `sources/absence/<topic>.txt`. A
  confirmed gap is a `gap` finding in the merge's own lane, `{key: m, name: ...}` in
  `lanes`: `location` is the file's first line, `quote` the command on it. `prose/m.md`
  lists what was searched; `RUN.md` records it under absence checks.
- `prose/chapter-<key>.md` for every chapter: the facts in the order the reader needs
  them, each sentence ending with its IDs. No quotes, no tables, no evaluation. The
  reading guide also says what was not read and why.
- `prose/summary.md`, 200–400 words: the facts that answer each part of the question,
  most decisive first, then what the documents leave open. Facts only, like the chapters.
- Read every prose file for judgement: a word that evaluates ("sufficient", "risky",
  "unclear", "should") is removed or replaced by the fact behind it.
- The merge may edit every file in `data/` and `prose/`. Record each edit in `RUN.md`.
  The build stops on an ID that no finding has.

## Claim check
Beyond the core list: every table row; every `open` finding (still open in the latest
version of the documents); every `conflict` (both statements, and the precedence it
cites); every `gap` (was the search wide enough?); and each chapter's prose against the
findings it cites. A sentence that says more than its findings, or judges, is listed in
`RUN.md` and rewritten.

## Report
`template/report-brief.typ`. Besides the core files it reads `data/documents.yaml`,
`prose/chapter-<key>.md` for every chapter, each table's `file`, and `chapters`,
`tables` and `labels` in `meta.yaml`. Sections: summary; the chapters in order, each
with its prose, tables and findings; lane notes; method and limits; the list of sources.

Citations: findings keep `path:line`, and `tool/check_citations.py` checks them as in
the core. The report prints a location in `sources/<key>/` as the document's `short`
label and where in the document it points, linked to the list of sources:
- PDF `sources/a2/p07.txt:12`: `[ITT A2, p. 7]`, the physical page.
- PowerPoint `s03.txt:4`: `[ITT A2, slide 3]`.
- Excel `sheet02-Prices.txt:36`: `[ITT A2, sheet Prices, row 36]`. The name comes from
  the file name, so punctuation in it shows as spaces.
- Word `doc.txt:120`: `[ITT A2]`, since Word has no fixed pages.
- A copied `.txt`, `.md` or `.csv`: `[ITT A2, line 12]`.
Any other location, such as a gap's search in `sources/absence/`, prints as `path:line`.
