# Codex Automations

The installer renders paused automation TOML files to:

```text
generated/codex-automations/
```

It also copies source recipes to:

```text
~/gbrain/recipes/
```

Each automation prompt follows the same pattern:

```text
Use the source-to-brain-automation skill with recipe <gbrain>/recipes/<source>.md.
The writable brain repo is <brain>.
Source-state files stay under <gbrain>.
Open an inbox item with the run result.
```

The skill handles the shared preflight and publish flow. The recipe contains the source-specific instructions: which connector to use, what scope to read, where source-state files live, and how to decide which Brain pages should be updated.

## Recommended Bring-Up Order

1. Google Calendar: lowest risk and easiest to inspect.
2. Notion meetings: high value if the database shape is known.
3. Email: enable after confirming mailbox scope.
4. Slack: enable after narrowing workspaces and channels.
5. Telegram: enable only after Telethon auth is healthy.

For each source:

1. Connect the source tool first. Gmail, Google Calendar, Slack, and Notion use Codex app connectors/plugins; Telegram uses Telethon user-session credentials.
2. Review the source config and ingestion scope before enabling the automation.
3. Enable the matching paused automation at the desired frequency.
4. After it runs, inspect the Codex run thread and review the files or Brain pages it created or changed.

## Installing The TOML Files

`scripts/install.sh` installs the rendered paused automations into `~/.codex/automations/` by default. To render files only, run it with `--no-install-codex-automations`.

The manual path is to ask Codex to create paused automations from the rendered TOML files. In this repo, say:

```text
Create paused local cron automations from the TOML files in generated/codex-automations. Keep the prompts, schedules, cwd list, model, and reasoning effort exactly as rendered.
```

For local experimentation, the lower-level bootstrap script also supports:

```bash
./scripts/bootstrap.sh --install-codex-automations
```

That copies the rendered TOML files to `~/.codex/automations/<id>/automation.toml`. They remain paused.
