# Codex Install Prompt

Use this when someone finds the Lorebase GitHub repo and wants Codex to set everything up locally. They can create a new empty folder, open a Codex thread from that folder, and paste:

```text
Install Lorebase locally in this folder from <paste this repo URL>.

If this folder is empty, clone the repo contents into this folder. If the repo is already here, use the current files.

Run ./scripts/install.sh --install-bun.

Keep source automations paused and do not ingest private source data yet. After install, guide me through setup in this thread: OpenAI key for embeddings, app connectors, and enabling one automation at a time. Report the Brain path, GBrain path, GBrain doctor status, installed automations, and whether embeddings are configured.
```

Optional edits:

- Add `--timezone <iana-zone>` if the user wants to override auto-detection.
- Add `--operator <name>` if the user wants a specific label for their own chat messages in config examples.
- Set `OPENAI_API_KEY` before running the installer if the user wants initial embeddings during install.
- Add `--no-install-codex-automations` if the user only wants rendered TOML files, not installed paused automations.
- Add `--no-embed` if the user wants text import only during setup.
