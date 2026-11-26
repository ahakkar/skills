# Lens: appraise

How far do the target's claims hold, and what would it take to build on it? Ported from
one research paper appraisal: the paper through `adapter/documents.md`, its code through
`adapter/code.md` at the study-time commit. Read by the orchestrator; copy what lanes
need into `BRIEF.md`.

## Fields added to findings
- `aspect`: a key from Aspects below. Required.
- `rests_on`: `claims` only. What the target rests the claim on, in a few words:
  "one benchmark, three runs". Optional.
- `threat`: `method` only. The validity it threatens: `construct`, `internal`,
  `external` or `conclusion`. Optional.
- `bears_on`: IDs of the `claims` findings this one supports or undermines. Optional.
  The claims matrix lists them next to each claim.

      - id: B-04
        aspect: system
        finding: "The data augmentation the paper describes is defined but never applied"
        severity: high
        confidence: verified
        location: src/train.py:88-97
        quote: "dataset = load_split(\"train\")"
        claim:
          location: sources/paper/p03.txt:18
          quote: "every training image is randomly cropped and flipped"
          status: wrong
        bears_on: [A-02]

## Aspects
Each is a section of the report, in this order. `aspects` in `data/meta.yaml` lists the
ones the question covers; the default is all five.
- `claims`: the target's main claims and how well its own evidence supports them. Each
  has `claim`.
- `consistency`: one part of the target contradicts another: text, a table, a figure, a
  count or a sum. `claim` holds one statement; `location` and `quote` the other.
- `system`: the system as described against its code; design choices that produce a
  reported result; properties claimed but never measured.
- `artifact`: what is released against what the target says is released and what a
  reproduction needs; whether released data is what it is said to be.
- `method`: study design, sampling, analysis and threats to validity.

## Judgement
- Lanes set severity:
  - `high`: undermines a main claim, the verdict or the reader's decision.
  - `medium`: weakens a claim, or adds real cost to reuse.
  - `low`: minor or cosmetic, or a claim that holds.
- In this lens `claim.status` says how well the target supports the claim. `holds`: its
  evidence supports it. `weakened`: the support is weak (few data points, self-report
  only, confounded). `wrong`: the target itself, its data or its code contradicts it.
  `unverifiable`: the target offers nothing that bears on it.
- Judge each claim at the strength the target states it. Calibrate to the article type
  (a short article is not a full paper), but judge an empirical claim as one.
- Lanes don't write the verdict, rank options or estimate effort. The merge does.
- People are named by role (first author, participant 3), never by name, even where a
  name appears in the data. The location is enough.
- An impression is not a finding. If it matters, say so in prose and label it unverified.
- Numbers from released data are recomputed by script, with the command and output in
  `sources/`.
- Novelty is judged from the target's own references unless the plan includes a
  literature search. `prose/method.md` says which.
- An appraisal criticises named people's work. Record in `RUN.md` who may see it.

## Typical lanes
Two, plus a third when the question is whether to build on the artifact. A short paper
with a small artifact needs one. Budget: at most 20 findings per lane.

**A, the paper** (`claims`, `consistency`, `method`). Owns `data/criteria.yaml`.
- Claims: 10–20 main claims: each contribution, headline result and conclusion, and
  each limitation the target explains. Include those that hold.
- Consistency: numbers that should agree across sections, tables and figures; statements
  that contradict each other.
- Method: sampling and its rationale; the authors' own role in the study and what
  controls for it; whether outcomes are measured against a reference where one exists;
  whether what is measured is what the claims need; threats the limitations leave out.
- Criteria: the design against one published checklist for its study type, named in
  `criteria_source` in meta and read from its official text. One row per criterion.

**B, the artifact** (`system`, `artifact`). Owns `data/artifacts.yaml`.
- Version: which commit was evaluated. Date the commits against the study period the
  target gives, and rule later versions in or out with evidence. Cite the study-time
  checkout (`--root`); a later commit goes in a worktree under `sources/`.
- System: each component, model, parameter and data flow the target describes. Is it in
  the code, and is it called? Follow the main path from input to output.
- Design choices that produce a reported result, such as a default value or a code path
  that differs between the conditions compared.
- Properties claimed but never measured: speed, cost, accuracy.
- Released data: is each file what it is said to be (contents, counts, duplicates by
  hash)? Recompute the numbers the target reports or could have reported.
- Artifacts: each thing the target says is available, plus what a reproduction needs.

**C, fitness for reuse** (`system`).
- What separates from the rest: entry points, dependencies, external services.
- What a builder inherits: tests, CI, history, state, logging, configuration, accuracy
  of the docs. Counts by script.
- Each gap between what the code has and what the planned work needs.
- Security and data protection as far as the planned use needs: the location and how it
  works, no exploit steps.

## Checklists
`data/artifacts.yaml` (lane B) and `data/criteria.yaml` (lane A, against the checklist
in `criteria_source`), one entry per item:

    - item: "Trained model weights"
      promised: sources/paper/p05.txt:40   # where the target says it is available; omit if not
      status: missing      # present | partial | missing
      note: "No weights file in the repository at either commit."
      findings: [B-07]

    - criterion: "Random seeds reported"
      status: partial      # met | partial | unmet | n/a
      note: "Set in the code, not stated in the paper."
      findings: [A-11]

A `missing` artifact that matters is also a finding. Absence is checked by a second
search (file names, contents, history), recorded in `RUN.md`.

## Merge
After the core merge (duplicates, calibration, IDs everywhere):
- `verdict` in `data/meta.yaml`: one sentence: what the target can be read as, or what
  to do with it.
- `prose/summary.md`, 300–500 words: the reasons for the verdict, most important first;
  the target's strengths; how much each main claim can bear.
- `data/options.yaml`: 2–4 courses of action, recommended first: build on it, reuse a
  part, start over, or what a stronger study would do. Effort is optional. Every effort
  is a judgement and needs a `basis`: how it was estimated. `assumptions` in meta says
  what all estimates assume (who does the work, how much time, the unit).

      - option: "Reuse the evaluation script, rewrite the training loop"
        recommended: true
        description: "Keeps results comparable with the paper's tables."
        effort: "3–5 weeks"
        basis: "Sum of the parts."
        parts:
          - task: "Port the data loaders to the new format"
            effort: "1 week"
            basis: "4 loader functions (sources/repo_stats.txt), about a day each."
        findings: [B-03, C-02]

- `prose/questions.md`: a numbered list of what the reader must settle before acting,
  most decisive first. Each says why it matters, who can answer it (a role) and the IDs.
- The merge may edit every file in `data/` and `prose/`. Record each edit in `RUN.md`.
  The build stops on an ID that no finding has and on an effort with no basis.

## Claim check
Beyond the core list: every `claims` finding marked `wrong` or `unverifiable`, every
`consistency` finding, every artifact marked `missing`, every number recomputed from
released data, and the basis of each effort in the recommended option.

## Report
`template/report-appraise.typ`. Besides the core files it reads `data/artifacts.yaml`,
`data/criteria.yaml` and `data/options.yaml` (stubs `[]`), `prose/questions.md`, and
`verdict`, `aspects`, `criteria_source` and `assumptions` in `meta.yaml`. Sections:
verdict and findings overview; one section per aspect, with the claims matrix, the
artifact checklist and the criteria table; options and effort; open questions; lane
notes; method and limits.
