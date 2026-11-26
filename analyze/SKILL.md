---
name: analyze
description: Plan and run an evidence-based agentic analysis of a code repository, paper or document set. Every claim cites a location a script can check.
argument-hint: "[target] [question...]"
arguments: [target]
disable-model-invocation: true
---

Target: $target. Full arguments: $ARGUMENTS (the target, then the question).

Skill folder: `~/.claude/skills/analyze/`. It holds `adapter/` (how to read one kind of
material), `lens/` (what counts as a result), `template/` and `tool/`.

# 0. Answer before acting
- If the target or the question is missing, ask and stop.
- A quick look is allowed: size, languages, history, docs, tests. No cloning, converting,
  writing or agents before the user approves a proposal.
- Proposal, in at most 15 lines:
  - Adapter and lens, by file name. Available now: `adapter/code.md`, `lens/profile.md`.
    If none fits, say so; don't stretch one.
  - Who reads the result, its language and format.
  - Lanes: how many agents, what each reads, which model. A small target needs one agent
    or none; that is a normal path, not a fallback.
  - What will not be checked.
  - Confidentiality: may results be published? For a security issue in someone else's
    live system, how does it reach the owner? Never print secrets, only their location.
- At most 3 scoping questions, each an actual question.
- After approval, read the chosen adapter and lens in full before step 1.

# 1. Environment check
- Check every tool the plan needs (the adapter lists them). If one is missing, tell the
  user what that costs ("build checks will be skipped") and ask. Don't install anything
  without asking.

# 2. Workspace and inventory
- Results go in the target project, never only in the scratchpad:
  `doc/analysis/<YYYY-MM-DD>-<lens>/`. For a document set with no repo, ask where.

      BRIEF.md     lane instructions (from template/BRIEF.md)
      RUN.md       run log, filled in during the run (from template/RUN.md)
      sources/     inventories, command output, dumps: the evidence
      data/*.yaml  every table (items, facts, claims, scores)
      prose/*.md   narrative per lane, no tables
      tool/        checkers copied from this skill
      report.typ   the lens's template, copied from template/; never edited
      REPORT.pdf   the human-readable result

- Take the inventory by script, as the adapter says, and save it in `sources/`.
- Record the target's commit (or document versions) in `RUN.md`. All citations refer to it.
- Ask once whether to commit the workspace.

# 3. Brief
`BRIEF.md` must stand alone: lane agents start with no context and never see this skill.
Copy into it everything they need from the adapter (location format, allowed commands)
and the lens (item schema, judgement rules, checklists).
- README, CLAUDE.md, papers and existing presentation text are claims, not truth.
- Don't put errors you've already found into the brief as examples; they steer agents.

# 4. Test the pipeline before launch
- Write 2–3 sample items into `data/`, including YAML traps (`:` and `#` in strings,
  multi-line text, a list of locations). Run the checkers and `typst compile report.typ
  REPORT.pdf`, render one page to PNG and look at it.
- A template bug found here is fixed in the skill's `template/` too, not only in the copy.
  Agents never fix the template: a failed build means bad data.
- `tool/check_citations.py` must fail on a made-up quote and on a wrong line.
- Reset the data files to `[]`.

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
  remove IDs everywhere they appear, prose included. Record each change in `RUN.md`.
- Then do what the lens's merge section says.

# 7. Claim check
Correct quotes don't make correct claims.
- A separate clean-context agent re-reads the cited sources for every item the lens marks
  for checking, every synthesis or contradiction across sources, and every number that
  will be published. Verdict per item: `holds`, `weakened` or `wrong`, with its own
  evidence. Fix or remove `wrong`; downgrade `weakened`.
- Facts from outside the target (standards, rules, APIs) are checked against an official
  source or marked unchecked. Never from model memory.
- Runtime claims are measured with the command and output saved in `sources/`, or
  labelled unmeasured.

# 8. Finish
- Rerun the checkers, build `REPORT.pdf`, render the first, a middle and the last page to
  PNG and look at them.
- `RUN.md` is complete: its headings match the `collect-analysis-facts` skill.
- Final reply in at most 10 lines: the result, its limits, where the files are. Don't
  paste the output. Answer follow-ups shortest-first.
- Later corrections go back into `data/` and the outputs, not only into the chat.
