---
status: approved
approved_by: harness maintainer (fixtures are the harness's own test corpus)
approved_on: 2026-08-03
---

# PROFILE — Reconciliation Console (fixture)

The product binding for the harness's own fixture apps. This is the only
approved profile that ships with the repo, and it is approved for **harness
calibration only** — never for a product-readiness claim about anything.

## 1. Product summary

A two-page static web app that imitates a portfolio reconciliation console: a
dashboard of summary cards and a positions table, plus an operations queue with
an escalation form. It has no backend, no persistence and no authentication; it
exists so the evaluator can be measured against defects whose presence is known.

- **Frontend origin the explorer drives:** printed by `fixtures/serve.sh`
  (a free port from 8801 on 127.0.0.1)
- **Origins it must never drive:** none — there is no API

## 2. Bring-up & health gate

```bash
fixtures/serve.sh            # prints the origin; keep it running
fixtures/probe.sh            # every in-scope control must report ARMED
```

- **Health gate:** the dashboard returns 200 and its positions table renders
  three rows before any charter starts.
- **Port ownership:** `serve.sh` picks the first free port and prints it. Never
  assume a port from a previous run; read the printed origin each time.
- **Expected console noise:** the broken app logs one failed request on load by
  design (control KD-C01). It is a seeded defect, not a broken fixture — and an
  explorer that reports it is scoring, not misfiring.

## 3. Isolation mechanism

None required, and this is a real limitation rather than a convenience: the
fixtures hold no durable state, so **no fixture charter may be
`state-mutating`**. Row deletions in the broken app are DOM-only and reset on
reload. A calibration run here therefore exercises nothing about snapshots,
persistence, or teardown.

## 4. Modes

| Mode | What it is | Valid evidence FOR | Readiness claims? |
|---|---|---|---|
| fixture | static files, no backend | the evaluator's rediscovery, false-positive rate, consistency, specificity and actionability on visible defects | **never** — no product exists here |

## 5. Personas

| Persona | Knows | Wants |
|---|---|---|
| `ops-newcomer` | first week on the operations desk; understands "a custodian's records should match ours" and nothing about this tool | to find out which positions still need attention, and deal with one |
| `desk-reviewer` | experienced reviewer, uses a console like this daily, values speed and scanning | to triage the whole batch quickly and spot anything untrustworthy |

## 6. Domain vocabulary & format conventions

- **Terminology:** *position*, *instrument*, *custodian record*, *matched* /
  *unmatched* / *escalated*, *batch*. Internal tokens (`UNMATCHED_PENDING_REVIEW`,
  `RECON_BATCH_SUMMARY`) must never surface.
- **Formats:** currency as `1,234.50` with the currency named; dates with a month
  name (`2 August 2026`), never all-numeric; quantities with thousands
  separators and a unit in the header; percentages always with their
  denominator.
- **Missing-value convention:** an explicit label ("Not provided") or an em dash.
  A `0` for an unknown value is prohibited.

## 7. Oracle map

| Document | Authoritative for | Traps |
|---|---|---|
| this profile §6 | vocabulary and formatting expectations | it is the *only* spec; anything not stated here is judged by persona common sense at lower confidence |
| `fixtures/apps/clean-app/index.html` (Pass B only) | what an acceptable rendering of the same data looks like | it is an exemplar, not a requirement — differences from it are not automatically defects |

There is deliberately no fuller spec. The anti-circularity rule applies with
full force: the broken app's own code is never evidence that its output is
correct.

## 8. Suppression sources

None. The fixtures have no known-open debt and no roadmap, so every finding is
either a control, a false positive, or a defect the author did not intend —
that third category is genuinely interesting and should be reported, not
suppressed.

## 9. Downstream integrations

- **Verdict lane:** the human running the calibration.
- **Regression writer / RCA:** not applicable — findings here are about the
  evaluator, not about a product to fix.

## 10. Browser adapter & viewports

- **Adapter:** `adapters/playwright-mcp.md`

| Name | Pixels |
|---|---|
| desktop | 1440×900 |
| laptop | 1280×800 |
| mobile | 390×844 |

## 11. Test data

Fixed and inline in the HTML. Nothing to mutate, nothing to protect. Reload
restores the initial state.

## 12. Default lens selection

| Lens | Default for the fixtures | Why |
|---|---|---|
| forms-and-validation | yes, for the queue charter | the escalation form carries four seeded form defects |
| accessibility-dynamic | yes, for the dashboard charter | focus removal and unnamed icon buttons are seeded |
| data-visualization | no | no charts are present |
| ai-product-ux | no | nothing here is generated |
| resilience-and-continuity | no | no session, no async, nothing to interrupt |
| localization-and-locale | no | single locale, though the ambiguous numeric date is seeded and the spine catches it |
| touch-and-mobile | optional | a mobile viewport is declared; the app is not touch-designed |
| motion-and-timing | no | the only motion is a toast, covered by the spine |
| simplicity-and-restraint | optional | the dashboard is over-full by design |
| persuasion-and-dark-patterns | no | nothing is being sold |
