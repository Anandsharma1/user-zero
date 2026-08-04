---
status: approved
approved_by: harness maintainer
approved_on: 2026-08-03
calibration: none
---

# Charter — Operations queue and escalation form (fixture)

## 1. Mission & persona

An experienced reviewer has been told to escalate a position, lands on the
operations queue, and tries to submit an escalation.

- **Persona (Pass A embodies):** `desk-reviewer`

## 2. North-star question

Can the persona escalate a position and know afterwards whether it worked?

## 3. Entry state & test data

- **Entry route(s):** `/broken-app/queue.html` (note how you got here — the
  route is part of journey 1)
- **Test data:** none stored; the form accepts free text.

## 4. Isolation class

`observation-only`.

## 5. Primary journeys

1. Reach the operations queue from the dashboard, then return to the dashboard.
2. Read the queue and decide whether anything is waiting.
3. Fill in the escalation form and submit it.
4. Recover from whatever the submission does.

## 6. Pass-A brief

- **Focus dimensions:** user friction, interaction quality, trustworthiness,
  comprehensibility.
- **lenses:** [forms-and-validation]

## 7. Pass-B oracles

**Functional (≤4)**
1. The queue is reachable from the dashboard by navigation, not only by URL.
2. Submitting the form produces a stated outcome.

**Data correctness (≤4)**
1. The empty state distinguishes "nothing here yet" from "we could not load".

**Recovery / error states**
1. A rejected submission: is the persona's input preserved, and does the error
   say what to fix and where?
2. The in-flight state: can the persona tell working from stuck?

## 8. Accessibility & responsive checks

- **Keyboard traversal targets:** journey 3 completed by keyboard alone,
  including reaching the error text after a failed submit.
- **Viewports:** desktop, mobile.

## 9. Screenshot & evidence requirements

- Milestones: queue on arrival; form filled; mid-submit; post-failure.
- Failure states: the form after a rejected submit.
- Empty states: the queue's empty panel.

## 10. Known issues & exclusions

- **Out of scope:** the dashboard (covered by `fixture-dashboard`).

## 11. Exit criteria & verdict scope

- **Done means:** all four journeys attempted at both viewports, with the
  post-failure form state evidenced.
- **Readiness scope:** none. *Harness calibration*, mode `fixture`.
