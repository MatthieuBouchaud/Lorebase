# Brain Resolver

Use this decision tree before creating any new durable page.

## Decision Tree

1. Is it a human being? Put it in `people/`.
2. Is it an organization, protocol, fund, project company, vendor, community, or institution? Put it in `companies/`.
3. Is it a specific financial, commercial, hiring, partnership, or negotiation transaction with terms and a decision path? Put it in `deals/`.
4. Is it a specific dated event or transcript? Put it in `meetings/`.
5. Is it active work with an owner, repo, spec, roadmap, budget, or recurring execution? Put it in `projects/`.
6. Is it a raw possibility that nobody is building yet? Put it in `ideas/`.
7. Is it a reusable model, thesis, framework, or concept you could teach? Put it in `concepts/`.
8. Is it a prose artifact or draft? Put it in `writing/`.
9. Is it production, distribution, audience, press, or narrative operations? Put it in `media/`.
10. Is it a long-running workstream, institution-level operating system, or major area of life/work? Put it in `programs/`.
11. Is it about the user's organization, team design, internal strategy, or operations? Put it in `org/`.
12. Is it civic, policy, political, regulatory, or government landscape knowledge? Put it in `civic/`.
13. Is it private personal reflection, health, identity, relationships, or finances? Put it in `personal/`.
14. Is it household logistics, properties, vendors, purchases, or family operations a PA could execute? Put it in `household/`.
15. Is it candidate evaluation, hiring pipeline, or interview process? Put it in `hiring/`.
16. Is it bulk imported material or raw source material? Put it in `sources/`.
17. Is it a reusable prompt or agent instruction? Put it in `prompts/`.
18. If nothing fits, put it in `inbox/`.

## Tie Breakers

- Person vs company: if the subject is the human, use `people/`; if the subject is the organization, use `companies/`.
- Idea vs project: if work has started or an owner exists, use `projects/`; otherwise use `ideas/`.
- Concept vs idea: if it is something to teach, use `concepts/`; if it is something to build, use `ideas/`.
- Writing vs concept: an essay or memo draft goes in `writing/`; the distilled reusable idea goes in `concepts/`.
- Meeting vs project: the dated event goes in `meetings/`; durable project state gets propagated to `projects/`.
- Sources vs durable pages: raw imports go in `sources/`; synthesized knowledge goes to its primary home.

## Required Before Creating People Or Companies

Search first:

```bash
rg -i "name or alias" people companies
```

If a page exists, update it and add aliases rather than creating a duplicate.
