# Accepted exemplars — fixture positive controls

High-severity findings raised against these and then rejected are the harness
crying wolf. An empty exemplar set makes calibration fail preflight, so these
two records are the minimum the protocol requires.

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
