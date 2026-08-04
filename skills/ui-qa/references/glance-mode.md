# Glance mode

The full harness exists so a finding can be *acted on as evidence*: reproduced,
dispositioned, pinned as a regression test, quoted in a readiness claim. That is
what the profile, charters, coverage matrix, calibration and gate are for.

Sometimes you just want a skilled reviewer to look at a screen and tell you
what is obviously wrong. Glance mode is that, and it exists as its own mode so
that its output can be honest about being that — instead of a charter run with
the checks quietly skipped.

```
/ui-qa glance <route|url> [--persona "one sentence"] [--lenses a,b]
                          [--viewports desktop,mobile]
```

## What it needs

Almost nothing:

| Needed | Notes |
|---|---|
| A URL the app is serving | that is the whole setup |
| The browser adapter loaded | same as any run |
| A persona sentence | optional; defaults to "a capable first-time user of this kind of product" |

**No `PROFILE.md` required.** If one exists, glance uses its origin, personas
and viewports for convenience — but it never requires approval, because it
never claims anything a profile would authorize.

## What it does

1. Opens the route in a clean browser at each requested viewport.
2. Reads the taxonomy (`ux-evaluation-taxonomy.md`) and any named lenses — the
   evaluator's expertise is unchanged, and this is the point: the judgement is
   the same senior-reviewer judgement, only the surrounding machinery is gone.
3. Runs a heuristic sweep of what is on screen, and walks whatever obvious task
   the screen offers.
4. Screenshots every claim.
5. Writes `qa-output/<run_id>/glance.md` — findings plus a two-line summary.

## What it does NOT do

- **No Pass B.** Nothing is verified against a spec, a state model, or an API.
  It cannot tell you whether a number is correct — only whether the screen
  presents it honestly.
- **No coverage matrix.** It looks at what it can reach. Anything it did not
  reach is simply not covered, and the output says so rather than implying
  breadth.
- **No reproduction.** A finding is a single observation.
- **No suppression check.** It will happily report something already on your
  known-issues list.
- **No calibration.** Nobody has measured this evaluator against your product,
  so the false-positive rate is unknown.

## The label, which is not optional

Every glance output carries this at the top, verbatim:

```
GLANCE — uncalibrated, Pass-A only. No functional or data verification, no
reproduction, no suppression check. These are an expert reviewer's opinions
about what is on screen, not evidence about the product.
```

## What a glance finding licenses

| You may | You may not |
|---|---|
| Fix something obvious it points at | Treat it as a confirmed defect |
| Use it to decide where a real charter is worth writing | Feed it to the regression-writer or RCA lanes |
| Share it as review feedback | Quote it in a readiness or release claim |
| Re-run it after a change to see if the screen reads better | Count it as coverage of anything |

If a glance finding matters enough to fix and keep fixed, promote it: write a
charter that covers that surface, and let the finding be re-found by a run that
reproduces it and pins it. Glance is where a charter comes from, not a
substitute for one.

## Finding quality still applies

Relaxing the *process* does not relax the *finding*. Every glance finding still
carries route and state, the persona affected, a screenshot, the specific
observed problem, the principle violated, the user consequence, a concrete
recommendation, a severity, and the reviewer's confidence.

Dropped in this mode, because there is nothing to hang them on: `priority`
(no triage), `suppression_check` (no suppression sources), `disposition`
(no verdict lane).

The reason is simple: "this screen feels cluttered" is useless whether or not a
harness surrounds it. The screenshot and the specific recommendation are what
make a glance worth reading.

## Rules that still bind

- **Observation-only.** Glance never runs against a surface where poking around
  can change durable data. If you are not sure, it is not a glance — write a
  charter with an isolation class.
- **No source reading.** Same rule as Pass A: judgement comes from the screen.
- **No readiness claims, ever**, regardless of how clean the screen looks.
- Runs stay in `qa-output/`, which is gitignored evidence.

## Gate

```bash
scripts/verify-run.sh qa-output/<run_id> --glance
```

Checks the small set that applies: `glance.md` exists and carries the label,
`evidence/` is present, every finding record is complete for this mode, and no
credentials leaked into the evidence. It deliberately does not check coverage,
hashes, or Pass B — those do not exist here, and pretending to check them would
be the dishonesty this mode is designed to avoid.
