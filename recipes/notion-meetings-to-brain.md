# Notion Meetings To Brain Recipe

## Purpose

Turn configured Notion meeting notes into durable meeting pages and propagate durable attendee, company, project, decision, and follow-up context.

## Connector

Use the Codex Notion app connector/plugin. If Notion is not connected, stop the run, write a blocked heartbeat, and ask the user to connect Notion before enabling this automation.

## Source Config

Read `notion-meetings-sync/config.example.json` in the source-state repo. The database or page source must be configured before ingestion. If the config still contains placeholder database or data-source values, stop and ask the user to pick the Notion meeting source.

Default output paths in the source-state repo:

- `notion-meetings-sync/data/meetings/`
- `notion-meetings-sync/data/state.json`
- `notion-meetings-sync/data/INDEX.md`

Default durable output in the Brain repo:

- `meetings/`

## Run Flow

1. Use the automation prompt's Brain repo and source-state repo paths. Do not hardcode local paths.
2. Read the Brain `RESOLVER.md` and `schema.md` before writing Brain pages.
3. Search existing Brain pages before creating a new meeting, person, company, project, idea, or concept page.
4. Read configured Notion meeting pages for the rolling window or backfill chunk.
5. Preserve meeting title, date, attendees, source link, summary, notes, transcript-derived facts, decisions, and action items.
6. Save source snapshots and state in the Notion meetings output paths above.
7. Create or update meeting pages under `meetings/`.
8. Propagate durable signal from meeting pages into resolver-selected entity pages.
9. Stage Brain writes under `tmp/source-to-brain/notion-meetings-to-brain/<run-id>/` in the source-state repo.
10. Build a `manifest.json` that writes meeting pages plus durable entity pages.
11. Publish with `source-to-brain-automation.sh publish-manifest <brain-repo> <manifest-path>`.

## Brain Rules

Meeting pages may retain more detail than entity pages. Entity pages should receive concise durable synthesis, not full transcripts.

Preserve manual sections in existing meeting pages. Append or update source-backed timeline evidence instead of replacing hand-written synthesis.

## Completion

Write or update an inbox run summary with:

- Notion pages reviewed
- meeting pages created or changed
- entity pages created or changed
- missing transcripts, attendees, or source permissions
- next source configuration suggestion

Write a heartbeat with status `ok`, `partial`, or `blocked`.
