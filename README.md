# Lorebase

Your AI-maintained memory.

Lorebase is a local AI-maintained memory system built around GBrain and Codex. It lets Codex Automations ingest private sources on your machine, synthesize durable markdown memory, and use GBrain to make that memory searchable, queryable, and semantically retrievable.

- a blank `Brain` markdown memory template
- a one-command installer for Codex-driven setup
- portable source-to-brain helper scripts
- paused Codex automation templates for Gmail, Google Calendar, Slack, Notion meetings, and Telegram

The goal is to get someone from zero to "my sources are becoming useful memory pages" quickly.

## Architecture

```text
External sources
  Gmail, Google Calendar, Slack, Notion, Telegram
        |
        v
Codex Automations
  local connector reads, reasoning, source recipes
        |
        v
Source-state repo: ~/gbrain
  GBrain tooling, recipes, sync state, digests
        |
        v
Brain repo: ~/Brain
  durable markdown pages, one primary home per thing
        |
        v
GBrain index
  search, query, import, sync, embeddings
```

## Codex-First Quickstart

1. Create a new empty folder with whatever name you want.
2. Open a new Codex thread from that folder.
3. Paste this prompt:

```text
Install Lorebase locally in this folder from <paste this repo URL>.

Clone the repo contents into this folder, then run ./scripts/install.sh --install-bun.

Keep source automations paused and do not ingest private source data yet. After install, guide me through setup in this thread: OpenAI key for embeddings, app connectors, and enabling one automation at a time. Report the Brain path, GBrain path, GBrain doctor status, installed automations, and whether embeddings are configured.
```

That prompt gives Codex enough context to clone the repo into the folder, run the installer, install GBrain dependencies, create the local Brain, install the Lorebase Codex skill, render and install paused automations, initialize GBrain, import the blank Brain, and start guided setup.

## Setup Choices

- **Timezone** is used later for source windows and daily Google Calendar pages. The installer auto-detects it; use `--timezone` only if you want to override it.
- **Operator label** helps chat-source recipes recognize the user's own messages in sources like Slack or Telegram. The installer uses `You` by default; use `--operator` only if you want a specific display name in config examples.
- **Tests** are for contributors and release checks. New users can skip `make test`; the installer already runs `gbrain doctor --json`.
- **Embeddings** can be configured after install. If `OPENAI_API_KEY` is already set, the installer runs `gbrain embed --stale`; otherwise Codex can help add the key and run embeddings next.

## Manual Quickstart

```bash
git clone <repo-url> lorebase
cd lorebase
./scripts/install.sh --install-bun
```

By default the installer:

- creates `~/Brain` from `brain-template/` without overwriting existing files
- clones `https://github.com/garrytan/gbrain.git` to `~/gbrain` if it is missing
- installs a local Codex skill at `~/.codex/skills/source-to-brain-automation/SKILL.md`
- renders paused automation TOML files into `generated/codex-automations/`
- installs paused automation TOML files into `~/.codex/automations/`
- copies sanitized config examples into the relevant `~/gbrain/*-sync/` folders
- auto-detects timezone and writes a neutral operator label to source config examples
- runs `bun install`, `bun link`, `gbrain init`, `gbrain doctor --json`, and `gbrain import ~/Brain --no-embed`
- runs `gbrain embed --stale` when `OPENAI_API_KEY` is available

Use custom paths when needed:

```bash
./scripts/install.sh --brain "$HOME/MyBrain" --gbrain "$HOME/src/gbrain"
```

## How Lorebase Uses Each Part

- **Codex** is the local agent and scheduler. It reads connected sources, follows source-specific recipes, reasons over what matters, and writes staged memory updates.
- **GBrain** is the memory tooling and retrieval layer. It owns the CLI, source-state repo, imports, syncs, search, query, and embeddings.
- **`~/Brain`** is the durable source of truth. It is plain markdown organized by people, companies, meetings, projects, ideas, concepts, and other resolver-selected homes.
- **Lorebase** is the glue. It installs the local workspace, gives Codex a repeatable source-to-brain skill, keeps automations paused by default, and provides tests so the setup stays shareable.

## Brain Folder Architecture

The generated `~/Brain` repo is organized around primary homes. Codex should update the existing primary page for a person, company, project, or topic instead of scattering the same truth across source-specific files.

- `people/` - humans, relationships, communication context, aliases, and current threads.
- `companies/` - organizations, vendors, protocols, funds, communities, institutions, and relationship history.
- `projects/` - active work with owners, goals, decisions, risks, repos, roadmaps, or recurring execution.
- `deals/` - commercial, financial, hiring, partnership, or negotiation transactions with terms and decision paths.
- `meetings/` - dated event records, notes, summaries, transcripts, and attendee context.
- `daily/calendar/` - Google Calendar-derived daily pages and event records.
- `ideas/` - raw possibilities that are not yet active projects.
- `concepts/` - reusable models, theses, frameworks, and teachable ideas.
- `writing/` - prose artifacts, drafts, memos, essays, and narrative work.
- `media/` - production, distribution, audience, press, and narrative operations.
- `programs/` - long-running workstreams, institution-level operating systems, or major areas of life/work.
- `org/` - team design, internal strategy, operating cadence, and organization-specific context.
- `personal/` - private personal reflection, health, identity, relationships, or finances.
- `household/` - logistics, properties, vendors, purchases, and family operations.
- `hiring/` - candidate evaluation, hiring pipelines, interview notes, and recruiting process.
- `prompts/` - reusable prompts, agent instructions, and workflow patterns.
- `sources/` - raw imports, archived source snapshots, and bulky source material that should not be treated as synthesized truth.
- `inbox/` - captures that do not yet have a clear resolver-selected home.
- `archive/` - retired pages kept for history.

The resolver rules live in `RESOLVER.md`, and the page shape lives in `schema.md`. Durable synthesis belongs above the final `---` separator on a page; dated evidence and source-backed timeline entries belong below it.

## Embeddings

Configure `OPENAI_API_KEY` before installation if you want semantic retrieval ready immediately. The installer imports text first, then runs `gbrain embed --stale` when the key is available.

Embeddings are what make semantic retrieval work. Plain text search still works without them, and the automation helper is intentionally non-blocking by default: it publishes markdown first, then tries `gbrain embed --stale`. Set `SOURCE_TO_BRAIN_EMBED_MODE=off` to skip embeddings or `SOURCE_TO_BRAIN_REQUIRE_EMBEDDINGS=1` to make automation runs fail when embedding fails.

## After Install

Connect the Codex apps you want to use:

- Gmail for email-to-brain
- Google Calendar for calendar-to-brain
- Slack for slack-to-brain
- Notion for notion-meetings-to-brain
- Telegram uses Telethon credentials instead of a Codex connector

Review the generated automation files in `generated/codex-automations/`. They are paused by default. Enable one source at a time after its connector works.

## Tests

Run the local smoke suite before sharing changes:

```bash
make test
```

The test copies the repo into a fresh temporary checkout, bootstraps an isolated `HOME`, verifies the blank Brain, renders paused automations, validates config JSON, and exercises the manifest publish plus embedding path with a stub `gbrain` binary.

Optional network check:

```bash
make test-network
```

That also verifies a shallow clone of the upstream `gbrain` repo.

## Design Principles

- The brain is a human-readable markdown repo.
- Every durable thing has one primary page and one primary directory.
- Source data stays inspectable and idempotent.
- Automations are source-specific, but the publish path is shared.
- Everything starts paused until the user verifies credentials and scope.
