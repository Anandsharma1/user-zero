# Known defects — fixture negative controls

**Do not read this file, or `fixtures/controls.tsv`, in a session that will run
an explorer.** Blindness applies to fixtures exactly as it applies to a real
product: whoever knows the registry performs neither pass.

## Where the controls live

The registry is `fixtures/controls.tsv` — 28 controls across 11 defect classes,
each with a page, a probe string, and the observable signature a run that found
it must report.

**All 28 are `armed`, not merely `registered`**, and that is machine-checked
rather than asserted:

```bash
fixtures/probe.sh              # every control must report ARMED
fixtures/probe.sh --class forms # or one class at a time
```

`probe.sh` greps the fixture **source files**, so no answer marker is ever served
into the DOM. It also enforces the protocol's control floor (≥5 armed controls,
≥3 classes) and fails if any declared control has been edited away — which would
otherwise score rediscovery against a denominator that no longer exists.

The seed mechanism is the fixture app itself, checked into this repo. There is
nothing to restore afterwards, because nothing is mutated: the "restoration
proof" for a fixture control is `git status --short fixtures/` being clean.

## In-scope sets (predeclare BEFORE each run)

Fix the in-scope set first, then run. Choosing controls after seeing results is
scoring your own exam.

| Date | Charter | Control IDs in scope | Rediscovery | Notes |
|---|---|---|---|---|
| | | | | |

Suggested first in-scope set for `fixture-dashboard` (9 controls, 7 classes —
comfortably above the floor, small enough to review by hand):

`KD-F01 KD-D01 KD-D03 KD-L01 KD-C01 KD-A01 KD-A02 KD-V01 KD-P03`

And for `fixture-queue` (6 controls, 4 classes):

`KD-S02 KD-N01 KD-E01 KD-R01 KD-R02 KD-R03`

## What a fixture calibration does and does not establish

**Does:** that the evaluator finds present, visible defects in functional
behaviour, data honesty, labelling, console evidence, accessibility, visual
craft, component choice, navigation and forms — and that it stays quiet on a
curated clean screen.

**Does not:** anything about persistence, aggregates needing cross-layer proof,
async finality, concurrency, session expiry, or isolation and teardown. The
fixtures are static files. A charter calibrated only here must say
`calibrated against fixtures only` in its authority line.
