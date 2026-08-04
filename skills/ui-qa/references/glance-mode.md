# Glance mode

The full harness exists so a finding can be *acted on as evidence*: reproduced,
dispositioned, pinned as a regression test, quoted in a readiness claim. That is
what the profile, charters, coverage matrix, calibration and gate are for.

Sometimes you just want a skilled reviewer to use the product and tell you what
is wrong. Glance mode is that, and it exists as its own mode so its output can be
honest about what it did — instead of a charter run with checks quietly skipped.

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

**No `PROFILE.md` required.** If one exists, glance borrows from it — but it
never requires approval, because it never claims anything a profile would
authorize. What it borrows, in increasing order of teeth:

- **§1, §5, §10 — origin, personas, viewports**: pure convenience.
- **§6 — vocabulary and format conventions**: these are *product-level rules*,
  not per-value oracles ("money shows the currency and two decimals", "a
  missing value is never rendered as 0", "say basket, not cart"), and glance
  may judge against them. A screen violating the product's own stated
  convention is a direct finding, cited as such — not a `needs_oracle`
  question. This is the honest middle ground: broad rules about *how* things
  should appear, without any authority over *which* value is right.
- **§7 — the oracle map, and everything per-feature**: never loaded. The moment
  a specific value needs verifying against a spec or an API, that is a
  charter's job.

Findings judged against §6 say so (`principle: PROFILE §6 — date format`), so a
reader can tell industry judgement from your own house rules.

## It really does use the product

This is not a screenshot review. Glance drives the app the way a tester would:

- **Walks journeys end to end.** Whatever the screen offers — search, filter,
  submit, open a detail, complete a flow — it does it, and reports where it got
  stuck.
- **Exercises functionality.** Does the button do what it says? Does the filter
  change the list? Does the form accept and then reflect input? A dead control is
  a glance finding.
- **Tests navigation properly.** Browser Back and Forward, refresh, deep links,
  escape hatches, dead ends, whether state survives.
- **Checks the data on screen, hard** — see the next section for exactly how far
  that goes.
- **Watches console and network** while acting. An unexpected console error
  during a journey is a finding even when the screen looks fine.
- **Provokes the unhappy paths** it can reach: empty results, bad input,
  cancelling, a slow or failed request.
- **Repeats the important screens at each requested viewport**, and in both
  themes if the product ships more than one.

Reload-and-check counts as UI evidence: if you save something, come back, and it
is gone, that is a finding glance can make on its own.

## What it can and cannot say about data

This is the distinction that matters, and it is not "no data checking".

**It can judge, from the UI alone:**

- **Internal consistency.** Does a total equal the rows it sits above? Do two
  screens showing the same fact agree? Does a chart's axis match its caption's
  claimed time window? Does a count match the number of items listed?
- **Self-consistency against the page's own payload.** The adapter can show the
  response the page itself received. If the API returned a value and the screen
  renders a different one — or drops a field entirely — that is an inconsistency
  finding needing no spec.
- **Presentation honesty.** A percentage with no denominator. A missing value
  rendered as `0`. Precision beyond what the visible basis supports. An
  all-numeric ambiguous date. A currency with no symbol. An aggregate over one
  sample shown as a trend. These are judgeable on sight and are among the most
  valuable findings the harness produces.
- **Plausibility.** A negative quantity, a date in 1970, a percentage above 100,
  a name where an ID belongs, a value that contradicts what the user just
  entered.
- **Persistence, by observation.** Do it, reload, look again.

**It cannot say a value is correct.** "Is the match rate really 73%?" needs an
authority — a spec, a database, a calculation you trust. Glance has none, by
definition. So when correctness is the question, glance reports it as an
**open question**, not a defect:

```
- id: g-07
  class: observation
  observed: dashboard shows "73.4% matched"; nothing on screen shows the
            population it is computed over
  needs_oracle: yes — cannot verify the figure without the batch record
  recommendation: show "11 of 15" beside it; separately, confirm the figure
                  against the batch data
```

`needs_oracle: yes` is a legitimate and useful output. It tells you precisely
where a real charter with real oracles would earn its keep.

## What it does not do

- **No oracles.** Nothing is checked against a spec, state model, or trusted
  data source. Correctness verdicts are out of reach; consistency and honesty
  are not.
- **No coverage matrix.** It covers what it can reach and says what it did not
  reach. No breadth is implied.
- **No reproduction.** Each finding is a single observation. It may be a fluke.
- **No suppression check.** It will report things already on your known-issues
  list.
- **No calibration.** Nobody has measured this evaluator against your product,
  so its false-positive rate is unknown.

## Uncalibrated does not mean unusable

Calibration measures the *harness* — how often it finds real problems and how
often it cries wolf. Without it you do not have a trustworthy aggregate, but you
still have individual findings, each with a screenshot, the specific thing
observed, and a recommendation.

**You are the calibration in glance mode.** A finding you can see in its
screenshot and judge in five seconds does not need a rediscovery score to be
worth fixing. What you cannot do is add up glance findings and conclude anything
about the product's overall state, or treat the absence of findings as good news.

## The label, which is not optional

Every glance output carries this at the top, verbatim:

```
GLANCE — uncalibrated, no oracles. Functionality, navigation, and data honesty
were exercised through the UI. Nothing was checked against a spec, API contract,
or database, so no value here is verified as correct. Findings are not
reproduced, not suppression-checked, and are not coverage. Judge each one on its
screenshot.
```

## What a glance finding licenses

| You may | You may not |
|---|---|
| Fix something it points at | Treat it as a confirmed defect |
| Decide where a real charter is worth writing | Feed it to the regression-writer or RCA lanes |
| Share it as review feedback | Quote it in a readiness or release claim |
| Act on a `needs_oracle` question by going and checking | Count it as coverage of anything |
| Re-run it after a change | Read "no findings" as "the screen is fine" |

If a finding matters enough to fix and keep fixed, promote it: write a charter
covering that surface, and let it be re-found by a run that reproduces it and
pins it as a test. Glance is where a charter comes from, not a substitute for one.

## Finding quality still applies

Relaxing the *process* does not relax the *finding*. Every glance finding carries
route and state, the persona affected, a screenshot, the specific observed
problem, the principle violated, the user consequence, a concrete recommendation,
a severity, and the reviewer's confidence.

Dropped in this mode, because there is nothing to hang them on: `priority` (no
triage), `suppression_check` (no suppression sources), `disposition` (no verdict
lane). Added: `needs_oracle` where correctness is the open question.

## Rules that still bind

- **Observation-only by default.** Glance may exercise functionality freely on a
  throwaway or local environment. Against anything holding real data, it does not
  create, edit or delete — and if you are unsure which you have, that is not a
  glance, it is a charter with an isolation class.
- **No source reading.** Same rule as Pass A: judgement comes from the running
  product, not the code.
- **No readiness claims, ever**, however clean the screens look.
- Runs stay in `qa-output/`, which is gitignored evidence.

## Gate

```bash
scripts/verify-run.sh qa-output/<run_id> --glance
```

Checks what applies: `glance.md` exists and carries the label, `evidence/` is
present, every finding record is complete for this mode, and no credentials
leaked. It deliberately does not check coverage, hashes, or a Pass-B report —
those do not exist here, and pretending to check them would be the dishonesty
this mode is designed to avoid.
