# Accepted exemplars — fixture positive controls

High-severity findings raised against these and then rejected are the harness
crying wolf. An empty exemplar set makes calibration fail preflight, so these
first two records are the minimum the protocol requires. The presentation
candidates below do not count until a maintainer records approval.

---

### AE-F01 — clean dashboard, desktop

- **Route + state:** `/clean-app/index.html` — loaded, populated
- **Viewport(s) approved at:** desktop (1440×900), laptop (1280×800)
- **Approved by / on:** harness maintainer / 2026-08-03
- **Approved as acceptable for:** data honesty (denominators present, currency
  named, missing value labelled "Not provided"), information hierarchy, table
  craft (numeric right-alignment with units in headers, semantic column order),
  navigation orientation (active nav state), focus visibility, contrast in both
  colour schemes, and the empty state's specificity.
- **Known imperfections deliberately accepted** — a finding about any of these
  is a false positive, not a discovery:
  - density is compact; a reviewer might prefer more breathing room;
  - microcopy is terse and unfriendly in tone;
  - the two nav links both point at the same page (it is a fixture with one page);
  - the action buttons are links styled as buttons and navigate nowhere;
  - there is no search or sort control on the table.
- **Findings raised here (per run):**

| Date | Run | Finding | Severity | Owner verdict |
|---|---|---|---|---|
| | | | | accepted / rejected |

---

### AE-F02 — clean dashboard, mobile

- **Route + state:** `/clean-app/index.html` — loaded, populated
- **Viewport(s) approved at:** mobile (390×844)
- **Approved by / on:** harness maintainer / 2026-08-03
- **Approved as acceptable for:** cards reflowing to one column, the table
  scrolling horizontally **inside its own container** rather than the page,
  target sizes at or above 44px, and no content clipped or overlapped.
- **Known imperfections deliberately accepted:**
  - the table requires horizontal scrolling to read the last column;
  - the caption is long for a narrow screen.
- **Findings raised here (per run):**

| Date | Run | Finding | Severity | Owner verdict |
|---|---|---|---|---|
| | | | | accepted / rejected |

---

### AE-F03 — review workspace, laptop

- **Route + state:** `/clean-app/workspace.html` — loaded, populated; help closed,
  then expanded by the reviewer.
- **Persona:** `ops-newcomer` (also acceptable for `desk-reviewer`).
- **Viewport + theme proposed:** laptop (1280×800), light.
- **Approval status:** candidate exemplar added 2026-10-08; requires maintainer
  approval before it counts toward a calibration denominator.
- **Proposed as acceptable for:** presentation/layout and presentation/copy:
  compact table rows allow comparison; a thin frame groups the table; a stronger
  left border distinguishes task guidance. Domain terms such as custodian and
  settlement date are relevant, with an explanation available on demand.
- **Functional scope:** Review links return to the dashboard; a complete review
  workflow is outside this presentation exemplar.
- **Intentional details to preserve:** the visible comparison guidance and the
  longer expanded help. Their length serves the task; shortening them solely to
  satisfy a word count or removing all borders would be a false positive.
- **Findings raised here (per run):** record finding, class/tier, and owner verdict.

### AE-F04 — review workspace, mobile

- **Route + state:** `/clean-app/workspace.html` — loaded, populated; help closed,
  then expanded by the reviewer.
- **Persona:** `ops-newcomer` (also acceptable for `desk-reviewer`).
- **Viewport + theme proposed:** mobile (390×844), light.
- **Approval status:** candidate exemplar added 2026-10-08; requires maintainer
  approval before it counts toward a calibration denominator.
- **Proposed as acceptable for:** presentation/layout and presentation/copy:
  the table scrolls within its container, guidance remains visible, and expanded
  help increases page length because it contains relevant instructions.
- **Intentional details to preserve:** domain terminology and the guidance
  border; scrolling after requesting help is not itself wasted screen space.
- **Findings raised here (per run):** record finding, class/tier, and owner verdict.

## False-positive burden by run

| Date | Charter | High-severity findings on exemplars | Rejected by owner | Pass (0)? |
|---|---|---|---|---|
| | | | | |

## A note on why the exemplars are imperfect on purpose

A positive control with nothing wrong teaches the evaluator that only perfection
passes, and an evaluator holding that belief floods every real screen. The
accepted-imperfection lists above are the actual measurement: an evaluator that
reports compact density as a high-severity defect has failed the control, and an
evaluator that reports it as a `good-to-have` opportunity has behaved correctly.
