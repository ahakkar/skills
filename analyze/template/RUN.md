# Run log: <title>

Fill this in during the run, step by step. `prose/method.md` is written from it.

- Target: <path or URL> at <commit or document versions>
- Adapters: <files>  Lens: <file>

## Plan (step 0)
- The approved proposal: question, reader, language and format, lanes and models, what
  will not be checked.
- The scoping questions and their answers.

## Environment (step 1)
- Tools and their versions. Missing tools and what they cost.

## Material (step 2)
- Code: the commit, and whether the commit or the working tree was analysed. A paper's
  artifact: the study-time commit and how it was chosen.
- Documents: per file its key, `sha256sum`, the conversion output and the reading tier.
  Pages with no text.

## Pipeline test (step 4)
- What was tested and what it caught.

## Lanes (step 5)
- Checker results per lane, rerun by the orchestrator (OK / LOC / MISSING).
- Missing tools that agents reported, after checking them.

## Merge (step 6)
- Each change: duplicates removed, IDs renamed or removed, severities changed, prose
  edited.
- Checker results after the merge.

## Claim check (step 7)
- Items checked; holds / weakened / wrong; what changed as a result.
- Facts from outside the target: the official source, or unchecked. Runtime claims: the
  command and output in `sources/`, or unmeasured.

## Absence checks
- Each thing found missing, and the second search that confirmed it (file names,
  contents, history).

## Not checked
- What was left out, and why.
