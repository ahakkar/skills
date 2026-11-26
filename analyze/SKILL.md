---
name: analyze
description: Plan and run an evidence-based agentic analysis of a code repository, paper or document set that answers a question in a Typst PDF report. Every finding cites a location a script can check.
argument-hint: "[target] [question...]"
arguments: [target]
disable-model-invocation: true
---

Target: $target. Full arguments: $ARGUMENTS (the target, then the question).

Skill folder: `~/.claude/skills/analyze/`. It holds `adapter/` (how to read one kind of
material), `lens/` (what the analysis produces: added fields, judgement rules, lanes,
merge, report), `template/` and `tool/`.

# 0. Answer before acting
- If the target or the question is missing, ask and stop.
- A quick look is allowed: size, languages, history, docs, tests. No cloning, converting,
  writing or agents before the user approves a proposal.
- Proposal, in at most 15 lines:
  - Adapters, by file name. Available now: `adapter/code.md`, `adapter/documents.md`
    (PDF, Word, Excel, PowerPoint). A paper with code uses both. If none fits, say so; don't stretch one.
  - Lens, by file name. Available now: `lens/review.md` (quality by area: scores, ranked
    actions, tooling, documentation claims), `lens/appraise.md` (how far a paper's or a
    system's claims hold: claim–evidence matrix, artifact check, options with effort).
    If none fits, say so and ask; don't stretch one.
  - Who reads the result, its language and format.
  - Lanes: how many agents, what each reads, which model. A small target needs one agent
    or none; that is a normal path, not a fallback.
  - What will not be checked.
- At most 3 scoping questions, each an actual question.
- After approval, read the chosen adapters and lens in full before step 1.

# 1. Environment check
- Always `typst`, which builds the report. Its first build downloads the `cmarker`
  package, so it needs network once.
- Check every tool the plan needs (the adapter lists them). If one is missing, tell the
  user what that costs ("build checks will be skipped") and ask. Don't install anything
  without asking.
- Record the tools, their versions and what is missing in `RUN.md`.

# 2. Workspace and inventory
- Results go in the target project, never only in the scratchpad:
  `doc/analysis/<YYYY-MM-DD>-<topic>/`. For a document set with no repo, ask where.

      BRIEF.md     lane instructions (from template/BRIEF.md)
      RUN.md       run log, filled in during the run (from template/RUN.md)
      sources/     inventories, command output, dumps: the evidence
      data/*.yaml  meta, findings per lane, claim check, the lens's own files
      prose/*.md   summary, method and one file per lane; no tables
      tool/        checkers copied from this skill
      report.typ   copied from template/report-<lens>.typ; never edited
      REPORT.pdf   the human-readable result

- Take the inventory by script, as the adapter says, and save it in `sources/`.
- Create every file `report.typ` reads, as `[]` or an empty `.md`, and fill
  `data/meta.yaml`. Both are listed at the top of `report.typ`.
- Record in `RUN.md` the approved plan, the answers to the scoping questions and the
  target's commit (or document versions). All citations refer to that commit.
- Ask once whether to commit the workspace.

# 3. Brief
`BRIEF.md` must stand alone: lane agents start with no context and never see this skill.
Copy into it everything they need from the adapter (location format, allowed commands),
from the lens (its fields, judgement rules and lane checklists, made specific to the
question and the target) and from Findings below.
- The target's own statements (README, CLAUDE.md, other docs, a paper) are claims to
  check, not truth.
- Don't put errors you've already found into the brief as examples; they steer agents.

# 4. Test the pipeline before launch
- Write 2–3 sample items into `data/`, including YAML traps (`:` and `#` in strings,
  multi-line text, a list of locations). Run the checkers and `typst compile report.typ
  REPORT.pdf`, render one page to PNG and look at it.
- A template bug found here is fixed in the skill's `template/` too, not only in the copy.
  Agents never fix the template: a failed build means bad data.
- `tool/check_citations.py` must fail on a made-up quote and on a wrong line.
- Reset the data files to `[]`. Record what the test caught in `RUN.md`.

# 5. Lanes
- Launch all lanes at once as `general-purpose` subagents (clean context, not forks).
  Prompt: "Root: <path>. Read <run dir>/BRIEF.md in full and follow it. You are Agent A."
- Sonnet for mechanical extraction and quoting; the default model for judgement lanes
  and the merge.
- While lanes run, do work that doesn't depend on them and keep `RUN.md` current.
- An agent's "all verified" is not evidence. Rerun the checkers yourself.
- If an agent reports a missing tool, check it yourself, then record it in `RUN.md`.

# 6. Merge
- Remove duplicates (keep the better write-up) and calibrate across lanes. Rename or
  remove IDs everywhere they appear, lane prose included. Record each change in `RUN.md`.
- Then do the lens's merge.
- Write `prose/summary.md`: the answer to the question, then what could not be checked.
  Each sentence ends with the finding IDs it rests on, e.g. `[A-01, B-03]`.
- Write `prose/method.md` from `RUN.md`: lanes, checks and limits.

# 7. Claim check
Correct quotes don't make correct claims.
- A separate clean-context agent re-reads the cited sources for every `high` finding,
  every finding the summary cites, every item the lens marks, every synthesis or
  contradiction across sources, and every number that will be published. Verdicts go in
  `data/claim-check.yaml` as `{id, verdict, note}`: `holds`, `weakened` or `wrong`, with
  its own evidence. Fix or remove `wrong`; downgrade `weakened`.
- Facts from outside the target (standards, rules, APIs) are checked against an official
  source or marked unchecked. Never from model memory.
- Runtime claims are measured with the command and output saved in `sources/`, or
  labelled unmeasured.

# 8. Finish
- Rerun the checkers, build `REPORT.pdf`, render the first, a middle and the last page to
  PNG and look at them.
- Every section of `RUN.md` is filled in or says why it is empty, and `prose/method.md`
  agrees with it.
- Final reply in at most 10 lines: the result, its limits, where the files are. Don't
  paste the output. Answer follow-ups shortest-first.
- Later corrections go back into `data/` and the outputs, not only into the chat.

# Findings
Lane `a` writes `data/findings-a.yaml` with IDs `A-01`…, and so on per lane. Each file is
a top-level list, `[]` if empty:

    - id: B-03
      finding: "Accuracy is computed on the training split, not the held-out set"
      severity: high         # high | medium | low: how much it matters to the answer
      confidence: verified   # verified | suspected
      location: src/eval.py:40-52   # string or list; path:line or path:start-end
      quote: "acc = correct / len(train_set)"
      claim:                 # optional: the target's own statement this finding checks
        location: paper/main.tex:212
        quote: "94 % accuracy on the held-out set"
        status: wrong        # holds | weakened | wrong | unverifiable

A lens adds fields to this schema and sections to its report. It doesn't change these
fields or their values.

- A finding is a fact a reader can check, not an opinion. "Messy error handling" is not
  a finding; "12 bare `except:` clauses in `src/`" is.
- A secret (key, password, token) is cited by its location. Its value never goes in a
  quote or in prose.
- Judgements that answer the question ("most of the paper's claims hold") go in the
  summary and rest on cited findings.
