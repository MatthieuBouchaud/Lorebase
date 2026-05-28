# Email To Brain Recipe

## Purpose

Turn high-signal Gmail messages and threads into durable Brain context while keeping raw mailbox-derived data in the source-state repo.

## Connector

Use the Codex Gmail app connector/plugin. If Gmail is not connected, stop the run, write a blocked heartbeat, and ask the user to connect Gmail before enabling this automation.

## Source Config

Read `email-sync/config.example.json` in the source-state repo. Treat mailbox queries, lookback windows, and noise rules as the active scope unless the user has created a non-example config beside it.

Default output paths in the source-state repo:

- `email-sync/data/messages/`
- `email-sync/data/digests/`
- `email-sync/data/state.json`
- `email-sync/data/INDEX.md`

## Run Flow

1. Use the automation prompt's Brain repo and source-state repo paths. Do not hardcode local paths.
2. Read the Brain `RESOLVER.md` and `schema.md` before writing Brain pages.
3. Search existing Brain pages before creating a new person, company, project, idea, or concept page.
4. Read Gmail using the configured queries and rolling window.
5. Skip obvious noise, notifications, mailer system messages, and low-context one-offs.
6. Save source snapshots, thread summaries, and state in the email output paths above.
7. Extract durable signal: people, organizations, projects, decisions, commitments, risks, relationship context, and useful timelines.
8. Stage Brain writes under `tmp/source-to-brain/email-to-brain/<run-id>/` in the source-state repo.
9. Build a `manifest.json` that writes only resolver-selected Brain files.
10. Publish with `source-to-brain-automation.sh publish-manifest <brain-repo> <manifest-path>`.

## Brain Rules

Update the existing primary Brain page when one exists. Create a new page only after duplicate checks. Put current synthesis above the final `---` separator and dated source-backed evidence below it.

Do not put raw email bodies in durable Brain pages unless the user explicitly wants that level of detail. Prefer concise, source-backed synthesis.

## Completion

Write or update an inbox run summary with:

- messages or threads reviewed
- source-state files updated
- Brain pages created or changed
- skipped or blocked scopes
- next source configuration suggestion

Write a heartbeat with status `ok`, `partial`, or `blocked`.
