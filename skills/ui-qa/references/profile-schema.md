# Profile Schema

`PROFILE.md` is the product binding — the only artifact regenerated when this
skill moves to a new project (or a new deployment of the same product). It
lives in the project's explorer directory (default `qa/product-explorer/`),
never inside the skill.

## Required sections

1. **Product summary** — what the application is, in one paragraph, plus the
   frontend origin the explorer drives (exact URL) and any origins it must
   never drive directly.
2. **Bring-up & health gate** — exact commands to start every stack layer,
   the health check that must pass before any charter starts, and how to
   discover (not assume) the current owner of each port. Include required
   environment variables per feature (e.g. which features are dead without
   which variable) so charters can preflight their own dependencies.
3. **Isolation mechanism** — how durable state is snapshotted for
   state-mutating charters, how the application is pointed at the snapshot,
   and the runtime check proving it actually is. Include cleanup.
4. **Modes** — the environment modes the product supports (e.g. auth-off
   legacy data vs auth-on production-representative), what each is valid
   evidence FOR, and which mode readiness claims require.
5. **Personas** — the user personas charters draw from, each with a sentence
   on what they know and what they want.
6. **Domain vocabulary & format conventions** — terminology, units,
   currency/date/number formatting rules the UI is expected to follow.
7. **Oracle map** — a table of authoritative documents: path, what it is
   authoritative for, and its **traps** (usage rules that prevent false
   findings — e.g. which sections are assertable, superseding amendments,
   naming quirks).
8. **Suppression sources** — where known-open issues, declared-partial
   features, and planned work are recorded, and the matching rule (e.g. key
   on titles not numbers).
9. **Downstream integrations** — the verdict lane for defect packets, the
   regression-writer skill, the RCA/learning skill, and any dispatch rules
   the project imposes on subagents.
10. **Browser adapter & viewports** — which adapter file binds the driver
    contract, and the named viewports charters may declare.
11. **Test data** — safe fixtures, offline-safe entities, data that must not
    be mutated, and where synthetic inputs live.

## Onboarding procedure (new project or major revision)

Draft the profile from two exploration ROLES (parallel where the environment
supports it, sequential otherwise — roles, not a fixed agent count):

- **Product/domain explorer** — reads product docs and UI code surface:
  personas, journeys, vocabulary, design intent, information requirements,
  known UX problems. Produces sections 1, 5, 6, 7 (product half), 8.
- **Runtime/coverage explorer** — reads run mechanics and test
  infrastructure: routes, stack startup, data dependencies, isolation
  options, existing automated coverage and its gaps, downstream skills.
  Produces sections 2, 3, 4, 9, 10, 11 and the coverage notes that tell
  charters what NOT to duplicate.

Merge into a draft `PROFILE.md` marked `status: draft`. **A human approves
the draft before any charter run claims authority.** Record the approval
(who/when) at the top of the profile.
