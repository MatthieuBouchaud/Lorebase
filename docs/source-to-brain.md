# Source-to-Brain Contract

A source-to-brain automation has three jobs:

1. Read a source in a bounded, idempotent way.
2. Write inspectable source-state files in the source repo.
3. Publish durable knowledge updates into the Brain repo using a manifest.

## Repos

Use two local repos:

- source repo: usually `~/gbrain`
- brain repo: usually `~/Brain`

The source repo owns recipes, collectors, sync state, digests, and temporary staged writes. The brain repo owns durable markdown pages.

## Manifest Publish Flow

Stage candidate brain files under:

```text
~/gbrain/tmp/source-to-brain/<source-id>/<run-id>/
```

Write a manifest next to them:

```json
{
  "operations": [
    {
      "type": "write",
      "target": "people/jane-doe.md",
      "source": "people/jane-doe.md"
    },
    {
      "type": "delete",
      "target": "companies/old-company.md"
    }
  ]
}
```

Then publish:

```bash
./scripts/source-to-brain-automation.sh publish-manifest ~/Brain ~/gbrain/tmp/source-to-brain/<source-id>/<run-id>/manifest.json
```

The helper applies writes, skips no-op manifests, imports written pages when possible, and falls back to a repo sync when deletes occur. After a successful import or sync, it runs `gbrain embed --stale` so semantic retrieval catches up to the newly published markdown.

Embedding is non-blocking by default. If `gbrain embed --stale` fails because a user has not configured `OPENAI_API_KEY` yet, the markdown publish still succeeds and the user can run embeddings later. Use these environment variables to tune that behavior:

```bash
SOURCE_TO_BRAIN_EMBED_MODE=stale          # default
SOURCE_TO_BRAIN_EMBED_MODE=off            # publish text only
SOURCE_TO_BRAIN_REQUIRE_EMBEDDINGS=1      # fail the run when embedding fails
GBRAIN_EMBED_CONCURRENCY=4
```

## Write Sets

`config/source-write-sets.json` lists which paths each source is allowed to commit.

Example:

```json
{
  "sources": {
    "email-to-brain": {
      "code_repo_paths": ["email-sync/data/"],
      "brain_repo_paths": ["people/", "companies/", "projects/", "ideas/", "concepts/"]
    }
  }
}
```

Keep write sets narrow. They are there to make automation commits understandable and to avoid swallowing unrelated local work.

## Automation Rule

Connector reads happen in the agent layer. File publishing happens through the shared helper. This keeps source-specific logic flexible while keeping brain writes predictable.
