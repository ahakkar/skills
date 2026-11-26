# Run log: <title>

Fill this in during the run, not afterwards. The headings match the
`collect-analysis-facts` skill. Write "unknown" rather than guessing, and mark estimates.

- Started: <date time>  Finished: <date time>
- Target: <path or URL> at <commit or document versions>
- Adapter: <file>  Lens: <file>

## 1. Goal
- Question, reader (role only), language and format.

## 2. Input
- What was analysed and how much (files, lines, pages), from `sources/`.

## 3. Agent setup
- Lanes, models, prompt. Per agent: tokens, tool calls and duration from the task
  notification.

## 4. Tools and state
- Tools and versions used, missing tools and their cost, where results are stored.

## 5. Verification
- Pipeline test before launch: what was tested, what it caught.
- Checker results per lane and after the merge (OK / LOC / MISSING).
- Merge changes: duplicates removed, IDs renamed, severities changed.
- Claim check: items checked, holds / weakened / wrong, what changed.
- Not checked, and why.

## 6. Results
- Item counts, what was selected or delivered, where it is.

## 7. User's role
- Decisions, corrections and questions from the user.

## 8. Lessons
- What worked, what didn't, what to change in the skill.

## 9. Confidentiality
- People, organisations, security issues and non-public material in the results.
