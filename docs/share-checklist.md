# Share Checklist

Before sharing Lorebase or a fork:

- Keep the repo itself separate from any real `Brain` repo.
- Do not commit `generated/` if it contains local absolute paths.
- Do not commit `~/.gbrain`, Telegram session files, connector exports, or sync data.
- Do not commit `email-sync/data`, `slack-sync/data`, `telegram-sync/data`, `notion-meetings-sync/data`, or Google Calendar `.raw` files.
- Review automation prompts for absolute paths and personal names.
- Keep automations paused by default.
- Ask new users to enable one source at a time.

Good public content:

- templates
- bootstrap scripts
- config examples
- source recipe patterns
- empty brain schema

Private content:

- real brain pages
- raw source payloads
- digests
- connector IDs that identify private workspaces
- API keys, OAuth tokens, sessions, and local database files
