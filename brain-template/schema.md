# Brain Schema

Use frontmatter for structured metadata. Use prose for judgment.

## Universal Page Shape

```markdown
---
type: person
title: Jane Doe
aliases: []
tags: []
updated: 2026-01-01
---

One paragraph of compiled truth: who/what this is, why it matters, and current state.

## State

- Role:
- Relationship:
- Current thread:
- Open questions:

## See Also

- [[related-page]]

---

## Timeline

- **2026-01-01** | Source: What changed. [Source: link or source name]
```

## Person

```yaml
type: person
title: Jane Doe
aliases: ["Jane A. Doe", "jane@example.com"]
company:
role:
relationship:
```

Focus on relationship context, current role, active threads, communication style, and evidence.

## Company

```yaml
type: company
title: Example Co
aliases: ["Example"]
website:
stage:
relationship:
```

Focus on what the organization does, why it matters, relationship history, and active threads.

## Meeting

```yaml
type: meeting
title: Weekly Sync
date: 2026-01-01
attendees: []
source_type:
source_url:
```

Keep source-backed sections clear. Propagate durable knowledge to people, companies, projects, ideas, and concepts.

## Project

```yaml
type: project
title: Project Name
status: active
owner:
```

Track goals, decisions, next actions, risks, and links to meetings or source docs.

## Idea

```yaml
type: idea
title: Idea Name
status: raw
```

Capture the possibility, why now, what would make it real, and what would falsify it.

## Concept

```yaml
type: concept
title: Concept Name
```

Keep it teachable. Distill the reusable model and link examples elsewhere.
