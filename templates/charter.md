---
status: draft            # draft | draft-synthesized | approved
approved_by:
approved_on:
calibration: none        # none | in-progress | passed (see calibration-protocol.md)
---

# Charter — <functionality name>

Keep this file under ~100 lines. **Oracle overload is the primary failure
mode**: a charter stuffed with checks turns exploration into linear checking
and kills discovery. Max 3–4 oracles per oracle section.

## 1. Mission & persona

<One paragraph: what this run is trying to find out.>

- **Persona (Pass A embodies):** <from PROFILE.md §5>

## 2. North-star question

<The single user-comprehension question Pass A must answer from the rendered
screens alone. One sentence, answerable, not a checklist.>

## 3. Entry state & test data

- **Entry route(s):** `/`
- **Test data / snapshot:** <from PROFILE.md §11>

## 4. Isolation class

`observation-only` | `state-mutating` | `external-provider`

- **Allowed mutations (if mutating):** <exactly what this charter may change>

## 5. Primary journeys

1. <one line, user language, no selectors>
2.
3.

## 6. Pass-A brief

- **Focus dimensions:** <2–4 rubric dimensions that matter most here>
- **lenses:** []  <!-- e.g. [ai-product-ux] — see lenses/MANIFEST.md; name only
     what this surface actually has. Two or three is a lot. -->

Nothing else reaches Pass A. The packet's exact contents are fixed by
`references/charter-schema.md` §Pass-A packet — no specs, no state models, no
expected values, no source.

## 7. Pass-B oracles

**Functional (≤4)**
1.

**Data correctness (≤4)** — values whose truth needs UI + cross-layer evidence
1.

**Recovery / error states** — worth provoking, and what honest handling is
1.

## 8. Accessibility & responsive checks

- **Keyboard traversal targets:** <the journeys that must be completable by
  keyboard alone>
- **Viewports:** <names from PROFILE.md §10>

## 9. Screenshot & evidence requirements

- Journey milestones: <which>
- Failure states: <which>
- Empty states: <which>

## 10. Known issues & exclusions

- **Suppression pointers for this surface:** <cite, do not re-report>
- **Deliberately out of scope:** <sibling surfaces>

## 11. Exit criteria & verdict scope

- **Done for one run means:** <concrete>
- **Any readiness statement is limited to:** <surface + mode, per PROFILE §4>
