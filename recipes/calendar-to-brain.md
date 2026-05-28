# Google Calendar To Brain Recipe

## Purpose

Turn Google Calendar events into daily calendar pages and durable context about meetings, people, companies, projects, and commitments.

## Connector

Use the Codex Google Calendar app connector/plugin. If Google Calendar is not connected, stop the run, write a blocked heartbeat, and ask the user to connect Google Calendar before enabling this automation.

## Source Config

Read `calendar-sync/config.example.json` in the source-state repo. Treat account labels, date windows, timezone, and output paths as the active scope unless the user has created a non-example config beside it.

Default durable output in the Brain repo:

- `daily/calendar/`

Raw or bulky event snapshots should stay in source-state output folders when needed.

## Run Flow

1. Use the automation prompt's Brain repo and source-state repo paths. Do not hardcode local paths.
2. Read the Brain `RESOLVER.md` and `schema.md` before writing Brain pages.
3. Search existing Brain pages before creating a new person, company, project, idea, or concept page.
4. Read Google Calendar events for the configured rolling window or backfill chunk.
5. Create or update daily pages under `daily/calendar/YYYY/YYYY-MM-DD.md`.
6. Preserve event times, titles, attendees, links, and useful descriptions without copying excessive private raw text.
7. Extract durable signal from recurring meetings, attendee patterns, project meetings, decisions, and follow-ups.
8. Stage Brain writes under `tmp/source-to-brain/calendar-to-brain/<run-id>/` in the source-state repo.
9. Build a `manifest.json` that writes daily pages plus any resolver-selected durable Brain pages.
10. Publish with `source-to-brain-automation.sh publish-manifest <brain-repo> <manifest-path>`.

## Brain Rules

Daily calendar pages can be date-oriented. Durable knowledge about a person, company, project, idea, or concept should be propagated to that subject's primary page.

Do not create separate pages for every routine event unless the event has durable standalone value.

## Completion

Write or update an inbox run summary with:

- date range reviewed
- daily pages created or changed
- entity pages created or changed
- skipped calendars or blocked connector scopes
- next source configuration suggestion

Write a heartbeat with status `ok`, `partial`, or `blocked`.
