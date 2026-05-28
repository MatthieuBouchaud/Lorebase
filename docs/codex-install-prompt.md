# Codex Install Prompt

Use this when someone finds the Lorebase GitHub repo and wants Codex to set everything up locally.

```text
Install Lorebase locally from this GitHub repo: <paste repo URL>.

Clone it to ~/lorebase if it is not already open. Then:
1. Run make test.
2. Run ./scripts/install.sh --install-bun --timezone "Etc/UTC" --operator "Your Name".
3. Keep all source automations paused.
4. Do not ingest private source data until I explicitly choose a connector.

When finished, tell me the Brain path, GBrain path, whether GBrain doctor passed, whether embeddings ran, and what connector I should enable first.
```

Optional edits:

- Change `Etc/UTC` to the user's timezone.
- Change `Your Name` to the user's display name.
- Set `OPENAI_API_KEY` before running the installer if the user wants initial embeddings.
- Add `--no-install-codex-automations` if the user only wants rendered TOML files, not installed paused automations.
- Add `--no-embed` if the user wants text import only during setup.
