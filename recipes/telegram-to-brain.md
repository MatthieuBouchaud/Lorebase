# Telegram To Brain Recipe

## Purpose

Turn high-signal Telegram conversations into durable Brain context while keeping raw chat-derived data and attachments in the source-state repo.

## Connector

Telegram uses a Telethon user session, not a bot workflow and not a Codex app connector. If the Telethon session or credentials are missing, stop the run, write a blocked heartbeat, and ask the user to configure Telegram before enabling this automation.

## Source Config

Read `telegram-sync/config.example.json` in the source-state repo. The user must provide the required Telethon environment variables and complete the first interactive login before scheduled runs can work.

Default output paths in the source-state repo:

- `telegram-sync/data/messages/`
- `telegram-sync/data/digests/`
- `telegram-sync/data/files/`
- `telegram-sync/data/state.json`
- `telegram-sync/data/INDEX.md`
- `telegram-sync/data/runs/`

## Run Flow

1. Use the automation prompt's Brain repo and source-state repo paths. Do not hardcode local paths.
2. Read the Brain `RESOLVER.md` and `schema.md` before writing Brain pages.
3. Search existing Brain pages before creating a new person, company, project, idea, or concept page.
4. Verify the configured Telethon session is available and authenticated.
5. Read account-visible private chats, groups, supergroups, and channels within the configured scope.
6. Save source snapshots, attachment metadata, digests, run logs, and state in the Telegram output paths above.
7. Skip command noise, routine bot messages, and low-context forwarding unless the forwarded content has durable value.
8. Extract durable signal: people, projects, commitments, relationship context, decisions, risks, and repeated themes.
9. Stage Brain writes under `tmp/source-to-brain/telegram-to-brain/<run-id>/` in the source-state repo.
10. Build a `manifest.json` that writes only resolver-selected Brain files.
11. Publish with `source-to-brain-automation.sh publish-manifest <brain-repo> <manifest-path>`.

## Brain Rules

Do not mirror chat logs into Brain pages. Keep raw or bulky message records and attachments in source-state files. Use the configured operator display name to distinguish the user's messages from other speakers when that matters for interpretation.

## Completion

Write or update an inbox run summary with:

- chats reviewed
- source-state files updated
- Brain pages created or changed
- missing credentials, login, or permission blockers
- next source configuration suggestion

Write a heartbeat with status `ok`, `partial`, or `blocked`.
