# Accepted exemplars — positive controls

Screens the product owner has **explicitly curated as acceptable**. They exist
to measure the harness's false-positive burden: high-severity findings raised
here and then rejected by the owner are the harness crying wolf.

**Shipped ≠ accepted.** A screen does not become an exemplar because it is in
production. A human looks at it and says "this is fine". Without that, the
false-positive metric measures nothing.

An empty exemplar set makes calibration **fail preflight** — "zero rejected
findings on zero exemplars" is vacuous.

---

## Exemplar records

### ID: AE-001
- **Route + state:** `/<route>` — <which state>
- **Viewport(s) approved at:** <names>
- **Approved by / on:** <who> / <YYYY-MM-DD>
- **Approved as acceptable for:** <the aspects the owner is vouching for —
  e.g. "hierarchy and density"; an exemplar may be good in one respect and
  openly imperfect in another>
- **Known imperfections deliberately accepted:** <so a finding about these is
  a false positive, not a discovery>
- **Findings raised here (per run):**

| Date | Run | Finding | Severity | Owner verdict |
|---|---|---|---|---|
| | | | | accepted / rejected |

---

## False-positive burden by run

| Date | Charter | High-severity findings on exemplars | Rejected by owner | Pass (0)? |
|---|---|---|---|---|
| | | | | |
