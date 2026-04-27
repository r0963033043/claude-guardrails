---
name: Documentation voice — no second-person
description: User dislikes second-person ("you") in documentation files; prefers neutral, descriptive documentary voice, not instructional/tutorial voice
type: feedback
---

When writing documentation files (README.md, design docs, etc.), do not use "you" or other second-person address. The user's framing: "it is just a document" — reference material, not a tutorial teaching someone how to do things.

**Why:** the user's intent for docs is to describe what something *is* and how it *behaves*, not to walk a reader through steps as if onboarding them.

**How to apply:**
- Replace "you can do X" → "X is possible" / declarative statement of the fact.
- Replace "if you want Y" → "for Y" / "when Y is needed".
- Replace imperative headings like "Run this:" / "Verify:" with noun-phrase labels like "Verification:" or just let the code block speak.
- Neutral voice: passive where it fits, declarative otherwise. State facts and effects, not instructions.
- This applies to **files** (READMEs, design docs, CLAUDE.md additions). Chat replies can still use "you" freely — the rule is about written artifacts.
