# Persona Cohorts (`--cohort` mode)

One persona's fresh eyes find one persona's problems. A cohort runs the same
charter's Pass A once per persona, in independent fresh contexts, and then
asks a question a single run cannot: **which findings are universal, and
which are persona-specific?**

This mode is the borrowed idea from LLM-agent usability-simulation research
(see `docs/persona-simulation.md` in the harness repo), scaled down to what
this harness can actually stand behind: a handful of *profile-approved*
personas, not a generated population.

## When to use it

Worth the cost when:

- the surface serves genuinely different users (a first-timer and an expert
  read the same dashboard differently), and
- the charter's north-star question is about comprehension rather than
  mechanics, and
- the charter is already calibrated for at least one persona.

Not worth it for: mechanical journeys, single-audience internal tooling, or
any charter that has never passed calibration. A cohort multiplies an
uncalibrated judgment; it does not improve it.

## Procedure

1. **Persona set.** Named on the command line or in the charter, drawn ONLY
   from `PROFILE.md` §Personas. The runner refuses a persona the profile does
   not define — inventing personas at the command line is how a cohort turns
   into fan fiction.
2. **Independent Pass A per persona.** Each gets its own fresh context, fresh
   browser profile, and a packet identical except for the `persona` field. No
   explorer sees another's report; running them serially is fine (and is the
   default under a single-browser adapter) as long as no context carries over.
   Same lens selection for all — varying lenses per persona confounds the
   comparison. Full dispatch procedure: `references/pass-a-dispatch.md`.

   **Reset browser and console state between personas** — the adapter's
   teardown call (for Playwright MCP, `browser_close`; a fresh *profile* does
   not clear the console buffer). Skip this and a console error emitted during
   persona 1 is still in the buffer for persona 2, so a single stale
   same-origin error gets reported by every persona and aggregates into a
   falsely **universal** finding. That is the most misleading artifact a cohort
   run can produce: the cluster the reader trusts most, manufactured by a
   teardown someone forgot. Filter console evidence by origin as well, and
   record the reset in each persona's report.
3. **Per-persona artifacts.** `qa-output/<run_id>/personas/<persona>/` holds
   that explorer's Pass-A report, exit interview, and evidence. Each is
   hashed independently.
4. **Aggregate** into `cohort-summary.md` (below) — the only step that sees
   all reports.
5. **One Pass B for the run**, not one per persona. Objective correctness does
   not vary by who is looking; the oracles are the same. Pass B receives the
   aggregated finding list.

## Aggregation rules

Match findings across personas on **route + observed problem**, never on
wording. Then classify each cluster:

| Cluster | Meaning | Weight |
|---|---|---|
| **Universal** | every persona hit it | highest — fix first, and the strongest candidate for a pinned regression |
| **Majority** | most personas hit it | strong; note who did not and why |
| **Persona-specific** | one persona hit it | a real finding about that audience, NOT a false positive — record whose problem it is |
| **Contradictory** | one persona's improvement is another's regression | escalate as a product decision, not a defect; the harness's job is to state the tension precisely |

Two disciplines that keep this honest:

- **Never average the personas.** A cohort is not a sample of a population;
  it is a small set of deliberately chosen viewpoints. "3 of 4 personas were
  confused" is a description of your four personas and nothing more. No
  percentages, no scores, no extrapolation to "75% of users".
- **Never let agreement create authority.** Four LLM explorers sharing a
  model share its blind spots, so unanimity is correlated, not independent.
  A universal finding is a strong *prioritization* signal; it is not
  evidence, and it does not substitute for reproduction or for the verdict
  lane's disposition.

## `cohort-summary.md`

```markdown
---
run_id: <run_id>
charter: <charter>
personas: [<persona>, ...]
mode: cohort
---
## North-star answers        (one row per persona, verbatim from exit interviews)
## Difficulty ratings        (journey × persona matrix, self-reported 1–7)
## Universal findings
## Majority findings         (with the dissenting persona named)
## Persona-specific findings (grouped by persona)
## Contradictions            (stated as product decisions, with both sides)
## What the cohort added     (honest: which findings would a single-persona run have missed?)
```

That last section is the mode's own accountability. If a cohort of four
personas produced nothing a single run would have missed, say so — and run
single-persona next time.
