# Lens: profile

Checked facts for presenting a project: a portfolio card, a CV line, a README
introduction. Untested: no run has used this lens yet. Update it after the first run.

## Judgement
- Agents collect facts, not opinions. "Well architected" is not a fact; "rendering is
  split into 64×64 chunks, each one MultiMesh (`src/render.gd:30`)" is.
- Agents may say why a fact matters to a reader (`why`), but not inflate it.
- Every fact says where it comes from: `code`, `history`, `measured` or `estimate`.
  Estimates say how they were made.
- Existing presentation text (the current card, README) is a list of claims to check.

## Typical lanes
For a small repo one agent does both, or the orchestrator does it alone.
- **A, architecture:** data layout, main modules and their boundaries, how it scales,
  persistence, notable techniques. IDs `A-01`…
- **B, features and claims:** each claim in the current presentation text gets a status;
  features in the code that the text doesn't mention become facts. IDs `B-01`…
- The orchestrator adds `history` facts from `sources/repo_stats.txt` and any
  measurements. Lane key `x`, IDs `X-01`…, in `data/facts-x.yaml`

Budget: at most 15 facts per lane, ranked by how much they would tell a reader.

## Schemas (all files are a top-level list; `[]` if empty)

`data/facts-<lane>.yaml`
```yaml
- id: A-01
  fact: "Map state is stored as structs of arrays, one PackedInt32Array per field"
  why: "Keeps per-tile updates cache-friendly at 4096×4096 (16.7M tiles)"
  source: code            # code | history | measured | estimate
  confidence: verified    # verified | suspected
  location:               # string or list; path:line or path:start-end
    - src/world/map_data.gd:12-40
  quote: "var height: PackedInt32Array"
```
A `measured` fact has `location: sources/<file>.txt` and the command in `fact` or `why`.
An `estimate` fact has `basis:` instead of `quote`.

`data/claims.yaml` (lane B)
```yaml
- claim: "Works well up to 4096×4096"
  in: index.html:108
  status: holds           # holds | weakened | wrong | unmeasured | unverifiable
  reality: "No benchmark in the repo. The map size limit is set at src/config.gd:5."
  location: src/config.gd:5
```

## Merge
- Pick the 3–7 facts that carry the story into `data/selected.yaml`: a list of
  `{id, rank, reason}`. Prefer facts a technical reader can check, and numbers.
- History numbers are only selected if they help (a steady timeline, not three huge commits).
- Write `prose/draft.md`: the presentation text in the format the user asked for,
  following the target's own style rules if it has any (for example the portfolio spec).
  Each sentence ends with its fact IDs in brackets, e.g. `[A-01, X-02]`, for the claim
  check; the user removes them when publishing.
- Write `prose/summary.md` (150–300 words: what the project is, what the facts show,
  what could not be checked) and `prose/method.md` (lanes, checks and limits, from `RUN.md`).
- Fill `data/meta.yaml`: `title, target, commit, date, agents, scope, lang` and `lanes`, a
  list of `{key, name}` with one entry per facts file.

## Claim check marks
Every selected fact, every `wrong` or `weakened` claim, every published number.
Results go in `data/claim-check.yaml`: a list of `{id, verdict, note}`, where `verdict` is
`holds | weakened | wrong`.

## Output
`REPORT.pdf`, built from `template/report-profile.typ` copied to `report.typ` in the run
directory. It shows the summary, the selected facts with their check verdicts, the draft,
the current text's claims, every fact with its evidence, and the method and limits.
Every file the template reads must exist: create empty stubs (`[]`, empty `.md`) at setup,
including `prose/<key>.md` for each lane.
