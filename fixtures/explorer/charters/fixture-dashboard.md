---
status: approved
approved_by: harness maintainer
approved_on: 2026-08-03
calibration: none          # no calibration has been run yet — see docs/known-limitations.md
---

# Charter — Reconciliation dashboard (fixture)

## 1. Mission & persona

Someone new to the operations desk opens the reconciliation console for the
first time and needs to work out which positions still need attention, and
whether what the screen tells them can be trusted.

- **Persona (Pass A embodies):** `ops-newcomer`

## 2. North-star question

From the dashboard alone, can the persona say how many positions still need
review and what to do about the first one?

## 3. Entry state & test data

- **Entry route(s):** `/broken-app/index.html`
- **Test data:** fixed and inline; reload restores it.

## 4. Isolation class

`observation-only` — the app has no durable state. Row deletions are DOM-only.

## 5. Primary journeys

1. Read the summary and decide whether anything needs attention today.
2. Narrow the table to the positions that still need review.
3. Open one position's detail and try to correct its quantity.
4. Export the reconciliation and confirm it happened.
5. Find your way to anything else the console offers.

## 6. Pass-A brief

- **Focus dimensions:** comprehensibility, data presentation, trustworthiness,
  information hierarchy.
- **lenses:** [accessibility-dynamic]

## 7. Pass-B oracles

**Functional (≤4)**
1. Applying a status filter changes which rows the table shows.
2. Saving a position detail applies the entered quantity somewhere visible.

**Data correctness (≤4)** — judged against PROFILE §6
1. Every percentage carries its denominator; every amount names its currency.
2. No unavailable value renders as `0`; missing values use the profile's
   convention.
3. No internal token or raw identifier appears where a human label belongs.

**Recovery / error states**
1. The failed telemetry request on load: does the screen acknowledge anything, and
   should it?

## 8. Accessibility & responsive checks

- **Keyboard traversal targets:** journeys 2 and 3 completed by keyboard alone,
  including opening and closing the detail dialog and returning focus.
- **Viewports:** desktop, laptop, mobile.

## 9. Screenshot & evidence requirements

- Milestones: dashboard on load; table after applying a filter; detail dialog
  open; post-export state.
- Failure states: the console after load; the detail dialog after saving.
- Empty states: none exist on this page — record that as `na` with the reason.

## 10. Known issues & exclusions

- **Suppression pointers:** none; the fixtures have no known-open debt.
- **Out of scope:** `/broken-app/queue.html` (covered by `fixture-queue`) and the
  clean app (exemplar, run separately).

## 11. Exit criteria & verdict scope

- **Done means:** all five journeys attempted at desktop, the money screen also
  seen at laptop and mobile, and the north-star question answered in the exit
  interview.
- **Readiness scope:** none. This charter measures the harness. Every run is
  labeled *harness calibration*, mode `fixture`.
