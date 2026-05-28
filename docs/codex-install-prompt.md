# Codex Install Prompt

Use this when someone finds the Lorebase GitHub repo and wants Codex to set everything up locally. They can create a new empty folder, open a Codex thread from that folder, and paste:

```text
Install Lorebase locally in this folder from <paste this repo URL>.

If this folder is empty, clone the repo contents into this folder. If the repo is already here, use the current files. Then:
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
