# Adapter: code repository

Read by the orchestrator. Copy the parts lanes need into `BRIEF.md`.

## Material
- The repo as it is, at a fixed commit. Record `git rev-parse --short HEAD` in `RUN.md`.
- A dirty working tree: ask whether to analyse the commit or the working tree, and record
  which.
- A paper's artifact: use the commit from when the study ran, not HEAD, and say so.
- A remote repo: clone it into the run's `sources/` folder or next to the project (ask
  which). Never only into the scratchpad.

## Location format
- `path:line` or `path:start-end`, relative to the repo root, e.g. `src/parser.c:142`.
- `quote`: verbatim from that line range, at most 40 words. Whitespace may differ.
- Generated, vendored and minified files are not evidence; cite the source that makes them.

## Inventory (by script, saved in `sources/`)
- `bash ~/.claude/skills/analyze/tool/repo_stats.sh <repo> > sources/repo_stats.txt`:
  commit, file counts and lines per extension, largest files, history, authors (as counts,
  no names or emails), tests and CI found.
- Lines are counted with `wc -l` per extension, not with a code counter. Label them
  "lines incl. blanks and comments" wherever they are published.

## Environment check
- Always: `git`, `uv` (to run `check_citations.py`).
- The target's own toolchain, if any step builds, tests, runs or measures it: read the
  build files (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, …) and
  check the tool versions they need. `npm ci` or similar only with permission.

## What can be checked by running something
- `uv run --no-project tool/check_citations.py --root <repo> data/*.yaml`
- Build, type check, lint and tests, with each command and its result saved in `sources/`.
- Measurements (frame time, memory, run time): the exact command, the hardware (CPU, GPU
  if relevant, RAM) and the output in `sources/`. One run is a sample, not a benchmark;
  say how many runs.

## Hard rules for lanes
- Read-only. Write only the lane's own files in the run directory. No commits.
- No live services: nothing that reaches a deployed database, API or app. Don't read or
  print `.env*` values; naming the variables the code expects is fine.
- Allowed commands: `git log`, `git show`, `git blame`, `grep`, `find`, `wc`, plus the
  build, test and measure commands the proposal approved.
