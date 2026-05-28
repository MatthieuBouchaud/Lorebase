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

1. Open this GitHub repo in Codex, or copy the repo URL into a new Codex thread.
2. Paste this prompt:

```text
Install Lorebase locally from this GitHub repo: <paste repo URL>.

Clone it to ~/lorebase if it is not already open. Then:
1. Run make test.
2. Run ./scripts/install.sh --install-bun --timezone "Etc/UTC" --operator "Your Name".
3. Keep all source automations paused.
4. Do not ingest private source data until I explicitly choose a connector.

When finished, tell me the Brain path, GBrain path, whether GBrain doctor passed, whether embeddings ran, and what connector I should enable first.
```

That prompt gives Codex enough context to clone the repo, verify it, run the installer, install GBrain dependencies, create the local Brain, install the Lorebase Codex skill, render and install paused automations, initialize GBrain, import the blank Brain, and run embeddings when `OPENAI_API_KEY` is available.

## Manual Quickstart

```bash
git clone <this-repo-url> lorebase
cd lorebase
make test
./scripts/install.sh --install-bun
```

By default the installer:

- creates `~/Brain` from `brain-template/` without overwriting existing files
- clones `https://github.com/garrytan/gbrain.git` to `~/gbrain` if it is missing
- installs a local Codex skill at `~/.codex/skills/source-to-brain-automation/SKILL.md`
- renders paused automation TOML files into `generated/codex-automations/`
- installs paused automation TOML files into `~/.codex/automations/`
- copies sanitized config examples into the relevant `~/gbrain/*-sync/` folders
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

## What To Share

This repo is safe to share. A person's generated `~/Brain`, `~/gbrain/*-sync/data`, `~/.gbrain`, connector sessions, and automation run outputs are not safe to share by default.

See [docs/share-checklist.md](docs/share-checklist.md) before publishing a fork or sending this to someone.

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
