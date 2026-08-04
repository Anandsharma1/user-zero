# Fixtures — a deliberately broken app, and a clean one

Until now, calibrating this harness required a real product plus armed seeds,
which is why no calibration had ever been run. These fixtures remove that
excuse: a static app you can serve in one command, carrying **one seeded defect
per class**, plus a curated clean page as a positive control.

They exist to answer the only question that matters about an evaluator: *does it
find the things that are actually there, and stay quiet about the things that are
not?*

```bash
fixtures/serve.sh                  # serves both apps on a free port, prints URLs
fixtures/probe.sh                  # verifies every declared control is live (armed check)
```

## What is here

| Path | What it is |
|---|---|
| `apps/` | **the only directory served over HTTP** — the two apps and nothing else |
| `apps/broken-app/` | the negative controls — every page carries seeded defects |
| `apps/clean-app/` | the positive control — curated as acceptable, findings here are false positives |
| `controls.tsv` | the control registry: ID, class, page, probe, antiprobe, observable signature |
| `explorer/PROFILE.md` | a ready product binding for the fixtures |
| `explorer/charters/` | charters covering the fixture pages |
| `explorer/calibration/` | `known-defects.md` and `accepted-exemplars.md` pointing at the above |
| `serve.sh`, `probe.sh` | run them; prove the controls are armed |

## The blindness rule

An explorer drives a real browser and can read the DOM and fetch any URL the
server exposes. So the answer key has to be unreachable **two** ways, and the
first version of these fixtures failed both — a review found `controls.tsv`
fetchable at `/controls.tsv`, and nine comments in the broken app explaining each
seeded defect in plain English. Three rules now, all machine-enforced:

1. **Only `apps/` is served.** `serve.sh` serves `fixtures/apps` and refuses to
   start if the registry, probe, charters, or README are inside it. The registry
   deliberately lives one level up.
2. **Served files contain no comments at all** — no HTML comments, no `/* */`,
   no `//`. Not "no comments that give it away", because whether a comment is a
   hint is a judgment call and this needs to be a grep. A test enforces it.
3. **No control IDs, `data-seeded-*` attributes, or defect-naming identifiers**
   anywhere in the markup.

For the same reason: do not read `controls.tsv` into a session that will run the
explorer. The calibration protocol's blindness rule applies to fixtures exactly
as it applies to a real product — whoever knows the registry performs neither
pass.

## Armed means present AND unrepaired

Each control has a `probe` (text that must be **present**) and an `antiprobe`
(text that must be **absent**). The antiprobe exists because a positive probe
survives the repair it is meant to detect: adding `aria-label` to an unnamed icon
button fixes the control without changing the button markup, so a markup-only
probe would keep reporting ARMED against a defect that no longer exists — and
rediscovery would be scored against a control that could not be found because it
was not there.

`probe.sh` reports three states: `ARMED`, `MISSING` (defect edited away), and
`REPAIRED` (fix marker present). Any of the latter two fails the run.

## The clean app is a real control, not decoration

`apps/clean-app/` is deliberately plain and deliberately *complete*: labels, units,
denominators, focus styles, an honest empty state, a working back link, contrast
that passes. High-severity findings raised against it are false positives and
count against the harness.

It is not flawless, and it should not be — a fixture with no imperfections
teaches the evaluator that only perfection is acceptable. `accepted-exemplars.md`
records what is knowingly accepted (compact density, terse microcopy), so a
finding about those is a false positive too.

## Running a calibration against the fixtures

Preconditions per `references/calibration-protocol.md`: ≥5 armed controls across
≥3 defect classes, ≥2 approved exemplars, ≥2 repeat runs, blind operators. The
fixtures satisfy the first three by construction; the fourth and the blindness
are yours.

```bash
fixtures/serve.sh &                      # note the printed origin
fixtures/probe.sh                        # must report every in-scope control ARMED
# then, in a session that has NOT read controls.tsv:
/ui-qa fixture-dashboard --calibrate
/ui-qa fixture-dashboard --calibrate     # second run, for consistency
```

Then score the seven metrics, and **publish the numbers in
`docs/known-limitations.md` whether they are good or bad.** A calibration whose
results are only reported when favourable is not a calibration.

## What fixtures cannot tell you

They are static HTML with no backend, so they exercise comprehension, visual
judgment, component choice, table craft, navigation, accessibility, and
data-honesty rendering — but **not** persistence, async finality, aggregates that
need cross-layer proof, concurrency, or session expiry. Pass B against a fixture
has no durable record to inspect.

So a fixture calibration is a *floor*: it proves the evaluator finds present,
visible defects and does not flood a clean screen. It does not substitute for the
first real-product calibration, and a charter calibrated only against fixtures
should say so in its authority line.
