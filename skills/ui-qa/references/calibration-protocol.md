# Calibration Protocol

A QA harness is not trusted because it ran — it is trusted because it was
measured. Until a charter passes these thresholds, every run is labeled
**harness calibration** and is never presented as product-readiness evidence.
This is the explorer analogue of "mutate the invariant and prove the guard
fails": an unmeasured judge may be judging vacuously.

**Before a product exists to calibrate against**, the harness repo ships its own
corpus: a deliberately broken app with armed controls across a dozen defect
classes, a curated clean app as positive control, and an approved profile and
charters (`fixtures/` in the harness repo, with its own README). Use it to
establish a floor — the evaluator finds present, visible defects and stays quiet
on a clean screen — before spending a real product's calibration cycle. A charter
calibrated only there records `calibrated against fixtures only`, because static
files exercise nothing about persistence, async finality, or isolation.

## Calibration inputs (per project, in `calibration/`)

- **`known-defects.md`** — negative examples the harness should rediscover:
  - historical escaped defects (from the project's escape/RCA ledger),
    sampled across classes: functional, semantic/data, raw-ID/label,
    misleading zero, console/network failure, accessibility, visual/usability;
  - seeded defects: deliberate, reverted-after-run mutations that inject a
    defect class into an isolated copy of the stack.
- **`accepted-exemplars.md`** — positive controls: screens the product owner
  has explicitly curated as acceptable. **Shipped ≠ accepted** — a screen does
  not count as an exemplar merely because it shipped; a human curates the set.

**Every control record must carry:** a stable ID; the charter(s) it applies
to; the exact seed mechanism or baseline revision that makes the defect
PRESENT in the stack under test; the observable signature (what a run that
found it must report); a verification probe proving the seed is live before
the run; a restoration proof (digest-verified revert) after; and membership
in a **predeclared denominator** — the in-scope control set is fixed before
the run, never chosen after seeing the results.

**Registered vs armed.** A control described in prose is `registered` — it
documents intent and counts for nothing. It becomes `armed` only when its
seed is executable and checked in: a patch file or deterministic seed
script under `calibration/seeds/<ID>.*` (for code seeds) or an exact
recorded baseline revision (for historical controls), plus its live probe.
**Calibration preflight fails if any in-scope control is not armed, or if
the in-scope approved-exemplar set is empty** — "zero rejected findings on
zero exemplars" is vacuous and must not pass.

## Minimum control set, and what calibration authorizes

A single armed control cleared at 70% is arithmetically a pass and evidentially
nothing. So the denominator has a floor, and passing it does not grant blanket
authority.

**Floor for a charter to be calibrated at all:**

- **≥ 5 armed negative controls** in the predeclared in-scope set;
- spanning **≥ 3 distinct defect classes** from: functional, semantic/data,
  raw-ID or label leak, misleading zero, console/network failure,
  accessibility, visual/usability;
- **≥ 2 armed approved exemplars**;
- **≥ 2 repeat runs** on the same state (for consistency).

Below any of these, the outcome is `not calibrated — insufficient controls`,
which is neither a pass nor a fail. State the shortfall.

**Authority is scoped to the classes you actually tested.** A charter
calibrated with functional, data, and raw-ID controls has demonstrated nothing
about accessibility or visual judgment. Record it explicitly:

```markdown
Calibrated for: functional, semantic/data, raw-ID leak   (5/6 rediscovered)
NOT calibrated for: accessibility, misleading zero, console/network, visual
```

Findings in a class the charter is not calibrated for are still reported — they
are simply reported as **uncalibrated findings** and cannot support a readiness
claim in that class. Adding a class to the authorization requires arming
controls for it, not arguing that the evaluator is probably fine at it.

**Empirical only:** rediscovery counts a control ONLY when the defect was
actually present in the stack under test and the run reported it.
Counterfactual judgments ("our oracle *would* have caught this") may be
recorded as commentary but never count toward the metric.

**Controls vs suppressions:** suppression sources suppress only STILL-OPEN
or explicitly-deferred issues. A historical defect that has been FIXED is
not suppressible — reproduced from its pre-fix baseline it is a legitimate
negative control. One ledger may feed both lists, but an entry appears in
exactly one role per run: open → suppression; fixed → control candidate.

## Calibration run

Run the charter normally (both passes, full classification) against a stack
state containing the seeded controls (verify each seed live first), and
separately against the accepted exemplars.

**Blindness applies to BOTH passes.** The operator who arms seeds and knows
the control registry performs neither pass. Pass A is fresh-context as
always; Pass B is ALSO run by a fresh-context explorer that receives the
charter's oracles but never the control registry, the seed implementations,
or the fact that a calibration is underway. An informed rediscovery score
produced by the seeding operator is answer leakage and void.

## Metrics

| Metric | Measure |
|---|---|
| Rediscovery | `controls reported / controls in the predeclared in-scope set`, counting only controls verified live before the run |
| False-positive burden | count of high-severity findings raised against accepted exemplars that the product owner rejects |
| Consistency | Jaccard overlap of finding sets across repeated runs — formula below |
| Tier agreement | for experience opportunities: does the value tier survive product-owner review |
| Specificity | fraction of findings meeting the finding-quality contract without edits |
| Actionability | fraction of findings whose `recommendation` an implementer can act on without asking the explorer a clarifying question |
| Generic-commentary tendency | count of findings that are aesthetic commentary with no route-specific observation |

### The consistency formula

Two runs of the same charter on the same state produce finding sets A and B.

- **Match key:** `route + UI state + observed problem`, compared semantically,
  never by wording. Two findings match when a reviewer would fix them with one
  change. Record every match decision — a metric whose matching is undocumented
  is unauditable.
- **Score for one pair:** `|A ∩ B| / |A ∪ B|` (Jaccard). Intersection counts
  matched pairs once. Union counts matched pairs once plus every unmatched
  finding from both runs.
- **More than two runs:** the mean over all `n(n−1)/2` distinct pairs. Never the
  intersection across all runs at once, which collapses toward zero as runs are
  added and would penalize thoroughness.
- **Scope:** all classes, including observations. Restricting to defects hides
  the instability the metric exists to detect — an explorer whose experience
  findings churn completely between runs is not stable, whatever its defect list
  does.
- **Empty sets:** two runs that both find nothing score `not measurable`, not
  `1.0`. Perfect agreement on silence is not consistency; it is an untested
  charter.

Report the number with its inputs: `0.64 (16 matched / 25 union, 2 runs)`.

**Specificity and actionability are different failures.** Specificity asks
whether the finding is *well-formed* — route, screenshot, principle,
consequence, all present. Actionability asks whether the fix is *decidable*
from the recommendation alone. "Move the denominator next to the percentage
on the summary card" is actionable. "Improve the trustworthiness of the
summary card" can be perfectly well-formed, cite a principle, carry a
screenshot — and still leave an implementer with nothing to do. A harness
that reports the second kind generates triage work instead of removing it,
which is the specific way UX critique tends to fail in practice. Judged by
whoever would implement the fix, not by the explorer.

**Repair-lift is the strong form of this metric.** Asking an implementer
"could you act on this?" is a judgment. Handing the finding to an implementer
who does not see the screen, letting them make the change, and re-running the
charter to see whether the finding disappears is a *measurement*. Where the
project can afford it, prefer it:

1. Take a finding's `recommendation` alone — no screenshot, no explorer,
   no conversation.
2. An implementer (human or agent) applies it in an isolated branch.
3. Re-run the charter on the changed build. The finding should be gone, and
   nothing new should appear in its place.

**Repair-lift needs a recurrence control, or it measures nothing.** A finding
that fails to reappear may have been repaired — or may simply not recur on a
second look (a timing-dependent state, an order-dependent journey, a flaky
async path). So before crediting a repair, re-run the charter **once on the
unchanged build**:

- finding recurs on the unchanged build → the disappearance after the change is
  attributable, and the repair counts;
- finding does not recur on the unchanged build → it is **non-recurring**, not
  repaired. Exclude it from the repair-lift denominator entirely and record it
  as a consistency problem instead, because that is what it is.

The unchanged-build run doubles as a consistency data point, so the extra cost
is smaller than it looks.

Outcomes: **repaired** (gone, no regressions) → the recommendation was
genuinely actionable; **misrepaired** (the implementer changed the wrong
thing) → the recommendation was ambiguous, which is an actionability failure
even though the finding was real; **unrepairable** (nothing to act on) → the
finding was commentary. Report the three counts; the ratio of repaired to
total is the strongest single number this harness can produce about its own
usefulness. It is also expensive, so run it on a sample, not every finding —
and never let a repair-lift run double as a product change: the branch exists
to measure the harness, and it is discarded either way.

## Thresholds

The profile may override per charter; defaults (every metric has a bar —
an unthresholded metric is decoration):

| Metric | Default pass bar |
|---|---|
| Rediscovery | ≥ 70% of the predeclared in-scope control set |
| False-positive burden | 0 rejected high-severity findings on approved exemplars |
| Consistency | ≥ 60% finding overlap across 2 repeated runs (matched on route+observed problem, not wording) |
| Tier agreement | ≥ 70% of experience-opportunity tiers survive owner review unchanged |
| Specificity | ≥ 80% of findings contract-clean without edits |
| Actionability | ≥ 75% of findings implementable without a clarifying question |
| Generic-commentary tendency | ≤ 1 finding per run with no route-specific observation |

Below the bar: tune the charter (usually trim oracles or sharpen the Pass-A
brief), do not tune the metric.

## A metric with no denominator is NOT a pass

Tier agreement and actionability are the metrics the harness cannot produce
alone: tier agreement needs a non-empty set of tiered experience
opportunities (explorer-side, per `evidence-schema.md`) *and* a product-owner
review of those tiers; actionability needs an implementer's judgment. Either
side missing makes the metric **not measurable**.

`not measurable` is a distinct outcome from `pass` and from `fail`, and it must
be reported as such — never omitted, never averaged into an "N of 7 passed"
headline, never silently treated as satisfied because nothing contradicted it.
A charter with any metric unmeasured is **not calibrated**, and its runs keep the
"harness calibration" label regardless of how well the others scored. Say
which metric is unmeasured and what specifically is missing, so the gap is
actionable rather than a footnote.

The goal is not silence. It is a small number of grounded, useful product
observations — a harness that returns nothing is as suspect as one that
floods.

## Lenses are calibrated too

A newly enabled lens pack is an untested change to the evaluator. When a
charter adds a lens, **its next two runs are calibration runs** (two, because
one run cannot separate a lens that found something real from a lens that got
lucky, and the consistency floor needs a pair anyway). Watch specifically for
the lens's own failure mode — a lens invites findings in its territory whether
or not the territory has problems. If a lens produces only generic-commentary
findings across both runs, remove it from that charter.
Record the outcome in `lenses/MANIFEST.md` so the next project inherits the
judgment instead of rediscovering it.
