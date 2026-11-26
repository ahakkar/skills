---
name: collect-analysis-facts
description: Collect evidence-based facts about an agent-assisted analysis into a markdown file.
argument-hint: "[analysis-dir]"
arguments: [analysis-dir]
disable-model-invocation: true
---

- Collect facts about the analysis project at $analysis-dir.
- Answer only from evidence you can see: 
  - The project's chat history
  - Files in this directory
  - Git log, outputs.
- No results? Write "unknown".
- Mark any estimate as an estimate.

# Output
- A markdown file in this directory, with notes and the project folder's name in the filename.
- Write in English, brief bullet points under these headings:

1. Goal: what was analysed, for whom (role only, no names), and what question the analysis had to answer.

2. Input: what material was analysed and how much of it (files, lines of code, documents, pages, or whatever unit fits).

3. Agent setup: which agents or subagents there were, what each one did, and how the work was split and coordinated. Include any prompts, AGENTS.MD / CLAUDE.md files, skills or specs that steered the agents.

4. Tools and state: which tools the agents called (CLI tools, MCP servers, scripts) and where intermediate results were stored.

5. Verification: how the agents' output was checked (human review, cross-checks between agents, tests, spot checks against the source). Say what errors or hallucinations were caught and how.

6. Results: what the analysis produced and what was done with it. Give numbers where they exist (findings, issues raised, documents covered, time taken, time compared with doing it by hand).

7. User's role: what the user (the human) did, as opposed to the agents.

8. Lessons: what worked, what didn't, and what you would change.

