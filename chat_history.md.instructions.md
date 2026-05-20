# chat_history.md logging rule (user directive)

- Always maintain a `chat_history.md` file at the workspace root (or as requested).
- If it does not exist, create it at the start of the conversation.
- After every action I take (file edits, file creations, commands run, refactors, answers to substantive questions, decisions), append an entry.
- Entry format:
  - `## YYYY-MM-DD HH:MM - <short title>`
  - Bullet list: what was asked, what was done, files touched, key commands, outcome/notes.
- Keep entries concise but specific enough to recall in future chats (mention file paths, function names, decisions).
- Append, never rewrite past entries.
- Purpose: this file is treated as part of my context so the user can ask me to repeat or reference prior work from earlier chats.
