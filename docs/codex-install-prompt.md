# Codex Install Prompt

Use this when someone finds the Lorebase GitHub repo and wants Codex to set everything up locally. They can create a new empty folder, open a Codex thread from that folder, and paste:

```text
Install Lorebase locally in this folder from <paste this repo URL>.

Clone the repo contents into this folder, then run ./scripts/install.sh --install-bun.

After install, guide me through setup in this order:
1. Confirm the Brain path, GBrain path, GBrain doctor status, and installed paused automations.
2. Help me connect each source tool: Gmail, Google Calendar, Slack, and Notion through Codex app connectors/plugins; Telegram through its Telethon user-session credentials.
3. For each connected source, review its config and enable the matching automation at the recommended frequency.
4. After each automation runs, open/check its Codex run thread, confirm it completed, and summarize the files or Brain pages it created or changed.
5. Help me configure OpenAI embeddings if they are not already configured.
```

Optional edits:

- Add `--timezone <iana-zone>` if the user wants to override auto-detection.
- Add `--operator <name>` if the user wants a specific label for their own chat messages in config examples.
- Set `OPENAI_API_KEY` before running the installer if the user wants initial embeddings during install.
- Add `--no-install-codex-automations` if the user only wants rendered TOML files, not installed paused automations.
- Add `--no-embed` if the user wants text import only during setup.
