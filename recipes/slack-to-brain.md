# Slack To Brain Recipe

## Purpose

Turn high-signal Slack conversations into durable Brain context while keeping raw workspace-derived data in the source-state repo.

## Connector

Use the Codex Slack app connector/plugin. If Slack is not connected, stop the run, write a blocked heartbeat, and ask the user to connect Slack before enabling this automation.

## Source Config

Read `slack-sync/config.example.json` in the source-state repo. Start with DMs, mentions, and explicitly configured channels. Do not broaden channel scope unless the user has chosen that scope.

Default output paths in the source-state repo:

- `slack-sync/data/messages/`
- `slack-sync/data/digests/`
- `slack-sync/data/state.json`
- `slack-sync/data/INDEX.md`

## Run Flow

1. Use the automation prompt's Brain repo and source-state repo paths. Do not hardcode local paths.
2. Read the Brain `RESOLVER.md` and `schema.md` before writing Brain pages.
3. Search existing Brain pages before creating a new person, company, project, idea, or concept page.
4. Read Slack DMs, mentions, user-involved threads, and configured channels for the rolling window.
5. Skip system noise, routine bot messages, and low-value notifications.
6. Save source snapshots, thread summaries, and state in the Slack output paths above.
7. Extract durable signal: decisions, requests, blockers, relationship context, operating cadence, project updates, and repeated themes.
8. Stage Brain writes under `tmp/source-to-brain/slack-to-brain/<run-id>/` in the source-state repo.
9. Build a `manifest.json` that writes only resolver-selected Brain files.
10. Publish with `source-to-brain-automation.sh publish-manifest <brain-repo> <manifest-path>`.

## Brain Rules

Do not mirror chat logs into Brain pages. Summarize only durable signal and keep raw or bulky message records in source-state files.

Use the configured operator display name to distinguish the user's messages from other speakers when that matters for interpretation.

## Completion

Write or update an inbox run summary with:

- conversations or channels reviewed
- source-state files updated
- Brain pages created or changed
- skipped or blocked scopes
- next source configuration suggestion

Write a heartbeat with status `ok`, `partial`, or `blocked`.
