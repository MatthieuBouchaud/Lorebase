# Lorebase Source Recipes

Recipes are the source-specific runbooks used by the paused Codex automations.

During install, Lorebase copies these files into:

```text
~/gbrain/recipes/
```

The rendered automation TOML points at those installed recipe files. The generic `source-to-brain-automation` Codex skill handles the shared preflight, staging, manifest publish, GBrain import, embeddings, commits, and heartbeat flow. Each recipe explains the source-specific connector, scope, output folders, and durable Brain updates.

The files are copied without overwriting existing recipes, so users can customize their local versions after install.
