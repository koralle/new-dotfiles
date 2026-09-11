---
description: Explain a topic as a picture-heavy HTML page, tuned to the user's exact level. The reader is a mid-level frontend engineer around 30, strong in TypeScript, with ~5 years of React but rusty on recent releases and shaky on TanStack mental models, and actively growing in system design and databases. Use when the user types /eli30 <topic>. Designed for Cursor and OpenCode.
metadata:
    agents: cursor,opencode
    audience: mid-level frontend engineer (user)
    github-path: skills/eli30
    github-ref: refs/heads/main
    github-repo: https://github.com/koralle/skills
    github-tree-sha: b1a002ea133f79cb860ab4135a78f45e14e207b4
name: eli30
---
# eli30

**Explain for the user**: a mid-level frontend engineer around 30 who is strong in TypeScript and can follow real engineering reasoning, but whose knowledge is uneven in a specific, known way. Pitch every explanation to that map: skip what they know, slow down where they are weak.

## Reader profile

- **Language**: write in Japanese, and every Japanese string — headings, body prose, diagram labels — must follow the `natural-japanese` skill (https://github.com/coji/natural-japanese/tree/main/skills/natural-japanese). Load that skill before writing and apply its rules for natural, readable Japanese (no AI-ish or machine-translated tone). If the skill is not installed, read its SKILL.md from that URL and follow it anyway.

## Ground rules

- Assume general frontend and engineering literacy outside the weak spots above. Skip the basics; never skip project-specific knowledge.
- Define every project term the first time it appears: module names, internal services, domain vocabulary, acronyms.
- Start from the problem the topic solves, then present the solution.
- Explain why, not just what: constraints, trade-offs, and history matter.
- Use the project's own vocabulary consistently; follow its glossary or domain model when one exists (e.g. `CONTEXT.md`).
- Point to files or docs to go deeper when they exist.
- Leave out anything not needed to grasp the core idea.

## Output

- Big pictures, few words. Diagrams carry the explanation; keep text short.
- One idea per section, in the order the reader can absorb.
- Match the visual language: warm editorial paper magazine — cream canvas, warm near-black ink, mono path-style eyebrows (`/problem`, `/flow`), hairline borders, no shadows, pastel accents only in diagrams. Tokens and rules: `references/design.md`; starter: `assets/template.html` (paths relative to this skill's directory).
- Produce a single self-contained HTML file (inline CSS and SVG, no external assets) named `eli30-<topic-slug>.html`, then open it in the browser (`open` on macOS, `xdg-open` on Linux, `start` on Windows).
- If the user does not want to keep the file in the project, write it to a temporary directory instead.

Topic: the topic the user passed with `/eli30`, or whatever they asked to have explained.
