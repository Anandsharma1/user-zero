# Charter Schema

One charter = one functionality's testing mission. Charters are small
(~50–100 lines); their power comes from the profile and the method, not from
exhaustive enumeration. **Oracle overload is the primary failure mode**: a
charter stuffed with checks converts exploration into linear checking and
kills discovery. Maximum 3–4 oracles per oracle section; the explorer is
explicitly licensed to deviate — "if something unusual catches your eye,
follow the trail even if it isn't in the scenarios."

## Required sections

1. **Mission & persona** — one-paragraph mission; which profile persona
   Pass A embodies. For a cohort run, the persona list
   (`references/persona-cohorts.md`).
2. **North-star question** — the single user-comprehension question Pass A
   must answer from the rendered screens alone.
3. **Entry state & test data** — route(s) to start from; which profile test
   data / snapshot the run uses.
4. **Isolation class** — `observation-only` | `state-mutating` |
   `external-provider`, with the allowed mutations stated when mutating.
5. **Primary journeys** — 3–6 user journeys, each one line, in user language
   (not selector language).
6. **Pass-A brief** — persona, north-star question, journeys, which
   experiential rubric dimensions (below) deserve extra attention for this
   surface, and the **lens selection** (below). NOTHING ELSE goes to Pass A —
   see the packet definition below for the exact contamination boundary.
7. **Pass-B oracles** — split into:
   - *Functional oracles* (≤4) — behavior that must hold.
   - *Data-correctness oracles* (≤4) — values/aggregates whose truth needs
     UI + cross-layer evidence.
   - *Recovery/error states* — the failure surfaces worth provoking and what
     honest handling looks like.
8. **Accessibility & responsive checks** — keyboard traversal targets and
   the profile viewports this charter declares.
9. **Screenshot & evidence requirements** — the journey milestones, failure
   states, and empty states that must be captured. The required coverage rows
   are *derived* from journeys × viewports × states by
   `references/coverage-contract.md`, not enumerated here — a charter may add
   rows but may not delete a required one (it can only be marked `na` with a
   reason, which is reviewable).
10. **Known issues & exclusions** — suppression pointers specific to this
    surface; sibling surfaces deliberately out of scope.
11. **Exit criteria & verdict scope** — what "done" means for one run, and
    the exact scope any readiness statement is limited to (mode-qualified
    per the profile).

## Lens selection

The evaluator always carries the spine
(`references/ux-evaluation-taxonomy.md`). A charter may additionally name
lens packs from `../lenses/` when the surface has a concern the spine does
not cover:

```markdown
## Pass-A brief
lenses: [ai-product-ux, motion-and-timing]
```

Rules:

- **Name only what the surface actually has.** Lenses cost context, and an
  irrelevant lens produces irrelevant findings that score against the
  harness's generic-commentary metric. A static reporting table needs no
  motion lens.
- **Two or three lenses is a lot.** If a charter wants five, the charter is
  probably too broad — split it.
- `lenses/MANIFEST.md` lists every available pack and the one-line trigger
  that tells you whether it applies.
- An unnamed lens is not forbidden knowledge: the evaluator's standing
  exploration licence still applies. Lenses sharpen attention; they do not
  fence it.

## The Pass-A packet

The runner assembles Pass A's ENTIRE input as a machine-readable packet.
Contamination boundary: if it is not in this list, Pass A does not get it.

| Field | Content | Source |
|---|---|---|
| `origin` | the exact frontend origin URL to drive | profile |
| `entry_route` | starting route | charter §3 |
| `mission` | one paragraph | charter §1 |
| `persona` | name + its one-sentence description | profile §Personas |
| `north_star` | the comprehension question | charter §2 |
| `journeys` | the user-language journey list | charter §5 |
| `rubric` | this charter's focus dimensions (the evaluator already carries the full rubric + `ux-evaluation-taxonomy.md` as its own expertise) | charter §6 |
| `lenses` | lens pack names to load from `../lenses/` | charter §6 |
| `viewports` | name + pixel dimensions for each declared viewport | profile §Adapter & viewports |
| `coverage_rows` | the required coverage matrix rows, derived by the runner — the explorer fills them in, it does not choose its own denominator | `references/coverage-contract.md` |
| `evidence_dir` | where to write the report and screenshots | runner |
| `adapter` | the browser adapter's tool instructions | adapter file |
| `conduct` | destructive-git prohibition; browser + evidence-writing tools only | skill |

Explicitly EXCLUDED from Pass A: project instruction files (CLAUDE.md,
AGENTS.md and kin), specs, state models, feature registers, suppression
lists, source code, API schemas, and the expectations dossier. Pass A judges
what a first-time user can see; everything else waits for Pass B. The Pass-A
report — including its exit interview — is finalized (and hashed, see
evidence schema) before Pass B opens any oracle.

## Experiential rubric (Pass A)

The rubric below is the SUMMARY of the evaluator's dimensions — the full
expert question catalog behind each line (Gestalt layout checks,
component-pattern appropriateness, table craft, navigation completeness,
target sizing, theme consistency, real-estate use, plus the cognitive-
walkthrough and heuristic-sweep methods) lives in
`references/ux-evaluation-taxonomy.md`, which the user-zero agent
(`agents/user-zero.md`) carries as its own expertise. Charters reference
dimensions from here; the agent brings the depth.

Pass A judges every journey against these dimensions, as the persona:

- **Functional journey** — can a real user complete the task through the UI?
- **Comprehensibility** — labels instead of IDs/enums; understandable
  terminology; useful explanations; clear dates and statuses.
- **Information hierarchy** — correct facts first; sensible grouping and
  ordering; appropriate prominence.
- **Data presentation** — formatting of currency/percentages/dates, rounding,
  missing values, denominators, sample sizes, units; no fabricated zeroes.
- **Interaction quality** — feedback after actions, loading progress,
  disabled-state explanations, retry paths, navigation continuity,
  duplicate-action prevention.
- **Visual quality** — alignment, spacing, typography, contrast, density,
  truncation, overflow, card/table consistency, awkward empty space.
- **Responsive quality** — layouts at each declared viewport; touch targets;
  horizontal overflow.
- **Trustworthiness** — the screen distinguishes fact, estimate, unavailable
  data, pending work, rejection, and system failure.
- **User friction** — confusing steps, needless clicks, loss of context,
  unclear next action, moments where a user would hesitate.

## Authoring hints

Candidate journeys and oracles are usually derivable from the profile's
oracle map (route inventory, endpoint↔surface ledger, the surface's spec
section, lifecycle/state models). The authoring judgment is **trimming**:
pick the few oracles with the highest defect value for this surface and let
exploration find the rest.
