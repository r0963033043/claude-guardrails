---
name: File-edit flow — propose in prose, wait for explicit go, then use Write/Edit
description: When proposing a file edit, describe it briefly in prose (no big inline code blocks), stop, and wait for an explicit user command before invoking Write or Edit. The IDE diff view shows the actual change.
type: feedback
---

When about to edit a file (any file — project source, memory, global config, hooks, docs), do not invoke `Write` or `Edit` immediately after finishing thinking. Instead:

1. Describe the proposed change in short prose — what file, what change, why. Do not paste full file contents or full code blocks as a "review here" stand-in; the IDE's diff view is what shows the actual content.
2. Stop and wait for an explicit user command ("go", "apply", "yes", etc.) before invoking the tool.
3. Only then call `Write` / `Edit` so the IDE permission popup appears at a moment the user is expecting it.

**Why:** Tool invocations surface a permission popup in the IDE the moment they fire. If "think → tool call" chains with no pause, the popup can land while the user is typing in another window or field, and a stray Enter accepts the change before they have read it. Also, full-file inline dumps are redundant with the IDE diff and clutter the conversation.

**How to apply:** Applies to every `Write` / `Edit` / `MultiEdit` call regardless of scope (project, memory, global, settings, hooks, docs). Exceptions: short single-line tweaks the user has already directly dictated ("change X to Y", "rename foo to bar") may be applied directly. When in doubt, propose first. Once the user has authorized a multi-step plan with one "go", subsequent tool calls in that plan can fire sequentially without re-asking — the user already chose the moment.
