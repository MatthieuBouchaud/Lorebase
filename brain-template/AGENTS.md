# Agent Instructions For This Brain

This repo is the user's durable, human-readable knowledge base. Treat the markdown files here as the source of truth for people, companies, meetings, projects, deals, strategy, writing, and personal context.

## Start Here

Before creating or updating Brain pages:

1. Read `RESOLVER.md`.
2. Read `schema.md`.
3. Search existing pages for the entity, alias, company, project, or topic.
4. Update the existing primary page when one exists; create a new page only after checking for duplicates.

## Brain-First Lookup

Before answering questions about the user's context, people, companies, projects, meetings, deals, strategy, writing, or prior thinking, search this repo first.

Preferred lookup order:

1. Use `gbrain search`, `gbrain query`, or `gbrain get` when available.
2. Use `rg` in this repo when GBrain is unavailable or an exact text search is better.
3. Read the relevant markdown pages before synthesizing.

Do not rely on model memory for facts that should live in this repo.

## Repo Boundaries

- Work in this Brain repo for durable knowledge content.
- Use the GBrain/source-state repo only for tooling, recipes, collectors, automations, sync state, and GBrain CLI behavior.
- Do not write to the GBrain/source-state repo unless the user asks for automation or tooling changes.
- The Brain markdown is the durable source of truth; the GBrain index is the retrieval layer.

## Writing And Updating Pages

- Preserve the compiled-truth plus timeline structure from `schema.md`.
- Put current synthesis above the final `---` separator.
- Put dated, sourced evidence below the final `---` separator.
- File by primary subject, not by source channel.
- Propagate durable signal from meetings, email, Slack, Google Calendar, Notion, Telegram, or other sources into the resolver-selected page.
- Keep raw or bulky imports in `sources/` or source-state repos; keep durable synthesis in the relevant Brain page.

## Source Data

- Never commit secrets, OAuth tokens, connector sessions, or local database files.
- Raw source payloads belong in source-state repos or `.raw/` folders that are ignored unless the user explicitly chooses otherwise.
- Durable insight from sources belongs in resolver-selected pages.

## Safety

- Do not revert unrelated local changes.
- If a capture does not clearly fit the resolver, place it in `inbox/` and note why.
- User corrections are high-value data; update the relevant Brain page promptly.
