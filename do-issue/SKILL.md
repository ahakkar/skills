---
name: do-issue
description: Do one issue
argument-hint: "[issue]"
arguments: [issue]
disable-model-invocation: true
---

If issue number is missing, stop work and ask what the issue number is.
Pick up issue #$issue from GitHub via gh, starting from a fresh pull of main, and create a new issue branch.
This is an explicit permission to work on that #$issue, commit to its branch, push the branch and open one PR for it.
Implement the issue based on the spec. 
If a question comes up, stop and ask before committing. 
