---
name: do-issue
description: Do one issue
argument-hint: "[issue]"
arguments: [issue]
disable-model-invocation: true
---

- If issue number is missing, stop work and ask what the issue number is.
- Pick up issue #$issue from GitHub via gh, starting from a fresh pull of main, and create a new issue branch.
- needs-refinement label: Issue may be stale, old or in need of refinemet. Check for staleness and if the issue looks like it needs refinement, stop and consult the user.
- too-big label: Issue looks like to be too big. More than 1 verb in title, looks potentially likely to be implementing multiple solutions' worth of issues in one issue. Could be in need of splitting to smaller issues before starting work. Stop and inform the user.
- Issue scope might be too large. Consider how many added lines of any origin it could produce, and if the scope looks too large,s top and consult the user.
- This is an explicit permission to work on that #$issue, commit to its branch, push the branch and open one PR for it.
- Implement the issue based on the spec. 
- If during implementation it looks like the added lines of any origin except migrations go over 500 lines, work should be stopped and issue divided into smaller sub-issues.
- If a question comes up, stop and ask before committing. 
