---
name: create-issue
description: Create one issue
argument-hint: "[issue]"
arguments: [issue]
disable-model-invocation: true
---

- The goal is to draft a new issue to GitHub, using gh commandline tool.
- The only output of the task at hand is potentially a new issue to GitHub.
- Use pre-existing issue templates and methods so the contents follow the established issue style.
- Would this issue overlap with an existing issue, is it a duplicate? Check from GitHub before acting.
- When you need to examine the program's docs and code, switch to main branch and pull the latest changes from remote.
- Suggest the issue contents briefly to user, they must confirm that the suggestion is OK before creating the actual issue to GitHub.
- What the new issue is initially about, description is provided by user: $issue.

If something is unclear, ask clarifying questions from user before drafting the issue. 