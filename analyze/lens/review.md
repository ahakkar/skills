# Lens: review

How good is the target, area by area, and what should be done first? Scores per area,
ranked actions, tooling results and a check of the documentation against the code.
Ported from one code repository review. Read by the orchestrator; copy what lanes need
into `BRIEF.md`.

## Fields added to findings
- `area`: a key from `areas` in `data/meta.yaml`. Required.
- `kind`: `issue` (the default) or `strength`. A strength is a finding when a score or
  the summary rests on it.

      - id: A-04
        area: quality
        kind: strength
        finding: "All 9 HTTP handlers validate their input through one schema module"
        severity: medium
        confidence: verified
        location: [src/api/schema.ts:1-30, src/api/orders.ts:18]
        quote: "const body = OrderInput.parse(await req.json())"

## Areas
`data/meta.yaml` lists them as `areas: [{key, name}]`, in report order. Typical for a code
repository: `architecture`, `correctness`, `security`, `data`, `quality`, `docs`, `ops`.
Drop the ones the question doesn't cover. Every area listed gets a score.

## Judgement
- Lanes set severity. For an issue:
  - `high`: a real bug, a security hole or a risk of data loss.
  - `medium`: likely to cause problems, or a significant maintenance cost.
  - `low`: a minor issue or a cleanup.

  For a strength: how much its area's score rests on it.
- Lanes don't score areas, rank actions or recommend fixes. The merge does, from findings.
- Before calling a framework or library pattern wrong, read the docs of the installed
  version (in the target or its dependency folder), not memory. APIs change between
  versions.
- A security issue: its location and how it works. No exploit steps, no secret values.

## Typical lanes
Up to three; a small repo needs one. Budget: at most 15 findings per lane, plus the
documentation claims.

**A, architecture and code quality** (`architecture`, `quality`). Also owns
`data/tooling.yaml`.
- Build, type check, lint and tests, as approved. Record each in `tooling.yaml`.
- Layering: is the core logic free of I/O? Do pages, handlers and components each keep
  to their role? Business logic inside UI components?
- Duplication and drift: the same logic written twice, the same task done in different
  ways (clients, config, error types).
- Type safety: casts, escape hatches, suppressed checks; generated or hand-written types.
- Error handling: ignored error results, and what the user sees when something fails.
- Size: the largest files and functions, from `sources/repo_stats.txt`.
- Dependencies: pinned or loose, unused ones.
- Testability: what it would take to unit test the core logic.

**B, logic, security and data** (`correctness`, `security`, `data`).
- Core rules against their spec: work 2–3 cases by hand, edge cases included.
- Rules enforced where the client can't bypass them, in every write path, not only in
  the UI. Time zones.
- Access control: can a client reach data the code means to hide? Compare the database's
  access policies with what the code assumes.
- Privileged paths: where elevated credentials are used and whether they can reach the
  client; the admin check on every admin route; guards on scheduled jobs and webhooks.
- Input validation on every handler: types, ranges, rows that belong to another user.
- Data layer: constraints, indexes for the main queries, migrations against the schema,
  seed data.

**C, documentation and operations** (`docs`, `ops`).
- Documentation claims: 15–25 concrete, checkable statements from the README and other
  docs (routes, paths, environment variables, numbers, schedules, function names). See
  below. Include those that hold, so the report shows how reliable the docs are.
- Onboarding: the steps from clone to a running app that the README leaves out.
- Gaps: architecture, deployment, how to run the checks; comments on the core functions.
- Operations: scheduled jobs against their guards, idempotency, timeouts, rate limits
  and retries for external APIs, caching, logging, hard-coded dates.
- Hygiene: `.gitignore`, committed build output, key-like strings (location only),
  licence.

## Documentation claims
A claim is a finding with `claim` (the core schema). `claim.location` and `claim.quote`
are the documentation's statement; `location` and `quote` are where the truth is;
`finding` says what is true.

    - id: C-02
      area: docs
      finding: "The default port is 8080, set in the config loader"
      severity: low
      confidence: verified
      location: src/config.py:12
      quote: "port: int = 8080"
      claim:
        location: README.md:40
        quote: "The server listens on port 3000 by default."
        status: wrong

- Documentation that matched the code once but no longer does is `wrong`. Say
  "outdated" in `finding`, and cite the commit that changed it if that helps.
- Something the docs leave out is a finding without `claim`.
- A claim that holds is listed only in the report's claims table. Give it `low`.

## Tooling
`data/tooling.yaml`, one entry per check. A code review lists build, type check, lint and
tests, also those skipped:

    - check: Tests
      command: "npm test"
      result: fail          # pass | fail | warn | skipped
      summary: "3 of 120 tests fail, all in the date parser."   # Markdown; for skipped, why
      output: sources/tooling/tests.txt   # optional: the saved output

A failed check that matters is also a finding, citing its output file.

## Merge
After the core merge (duplicates, calibration, IDs everywhere):
- Score every area in `data/scores.yaml`, 1 to 5: 5 exemplary, 4 solid with minor
  issues, 3 acceptable with clear gaps, 2 significant problems, 1 broken or absent.

      - area: architecture
        score: 3
        rationale: "Core logic has no I/O, but each page loads its data in its own way."
        findings: [A-02, A-05]

- Rank 5–10 actions in `data/actions.yaml`, most valuable first. Effort is a relative
  judgement.

      - rank: 1
        action: "Add a test suite for the date parser before changing it."
        effort: M           # S | M | L
        findings: [A-07, B-03]

- `prose/summary.md`, 250–400 words: what the target is, the overall verdict, the top 3
  strengths, the top 3 risks, and whether it is fit for its purpose.
- The merge may edit every file in `data/` and `prose/`, lane prose included, to remove
  duplicates, rename or remove IDs and change severities. Record each edit in `RUN.md`.
  The report build stops on an ID that no finding has.

## Claim check
Beyond the core list: every finding the top 3 actions cite, every finding behind a
score of 1 or 5, and every claim marked `wrong`.

## Report
`template/report-review.typ`. Besides the core files it reads `data/scores.yaml`,
`data/actions.yaml` and `data/tooling.yaml` (stubs `[]`), and `areas` in `meta.yaml`.
Sections: summary, scores, findings by area, actions; issues and strengths; lane notes;
findings by area in full; tooling results and documentation claims; method and limits.
