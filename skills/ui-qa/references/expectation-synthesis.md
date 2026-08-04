# Expectation Synthesis (`explore` mode)

How the skill answers "what SHOULD this surface show, mean, and do?" when
the user names a functionality, module, or route that has no charter yet.
Output: an **expectations dossier** + a **draft charter**, then (on approval
or when invoked with `--run`) a normal charter run.

## Step 1 — Scope discovery

Map the named target to concrete surfaces using the profile's oracle map:
the route inventory (which pages), the endpoint↔surface ledger (which APIs
feed them), and the feature register (which rows claim this functionality).
Output: routes, components, endpoints, and the user-facing name of the
functionality. If the target maps to nothing, say so — do not invent a
surface.

## Step 2 — Build the expectations dossier

For the scoped surfaces, derive expectations from sources in strict
precedence order, recording **source + citation + tier** on every entry:

| Tier | Source | May support |
|---|---|---|
| `specified` | product spec's assertable blocks; lifecycle/state models; feature register ✅ rows | correctness verdicts — the UI is WRONG if it deviates |
| `derived` | API schema field types/docstrings, domain docs, profile vocabulary & format conventions | correctness verdicts for format/semantics ("this field is a currency", "missing must render unavailable") |
| `inferred` | component/source code behavior; generic honesty rules; the platform's own conventions observed on sibling surfaces | consistency and wiring findings only — flagged `inferred` in any report |

**The anti-circularity rule:** code is never its own oracle. "The component
renders X, therefore X is correct" is circular — code-derived expectations
may support findings of *inconsistency* (the UI contradicts its own data
source, sibling surfaces disagree, a field arrives from the API but never
renders) but never a verdict that a displayed value is *right*. Where no
`specified`/`derived` source exists, the honest statement is "no recorded
expectation — judged by persona common sense", and the finding carries that
lower confidence explicitly.

The dossier has three parts:

1. **Behavioral expectations** — what actions exist, what each does, async
   lifecycle (loading/empty/error/retry/terminal), guards and disabled
   states, per source tier.
2. **Field significance table** — every user-visible field/element: what it
   means (schema docstring / domain doc), expected format (profile
   conventions), missing-value behavior, and its tier. This is where "what
   is the significance of this data" gets answered BEFORE exploration, so
   Pass B checks meaning, not just presence.
3. **Unknowns** — surfaces/fields with no `specified` or `derived` source.
   These are themselves a deliverable: a documentation gap list the product
   owner should triage (undocumented behavior is a product risk even when
   the code works).

## Step 3 — Emit the dossier and draft charter

**Dossier** → `qa/product-explorer/dossiers/<target>.md`, structured as:

```markdown
---
target: <target>
synthesized: <date>
status: draft            # draft → approved (with approved_by + date)
sources: [<cited documents>]
---
## Behavioral expectations   (one line each: expectation — tier — citation)
## Field significance        (table: field — meaning — format — missing-value rule — tier — citation)
## Unknowns                  (no specified/derived source; documentation-gap list for owner triage)
```

**Draft charter** → `qa/product-explorer/charters/<target>.md` per the
charter schema, with frontmatter:

```markdown
---
status: draft-synthesized   # → approved (approved_by + date) after human review
dossier: ../dossiers/<target>.md
---
```

- journeys drawn from the spec's user journeys or, absent those, the
  surface's visible affordances;
- Pass-B oracles selected from the dossier's `specified`/`derived` tiers
  (still capped at 3–4 per section — the dossier is the reference, the
  charter is the trimmed mission);
- suppression pointers pre-filled from the profile's suppression sources.

Never overwrite an existing charter or dossier for the target — if one
exists, diff against it and propose amendments instead.

## Step 4 — Run

- Default: stop for human review of the draft charter + dossier before the
  first run claims any authority.
- With `--run`: proceed immediately, but the run is labeled
  **synthesized-charter run (uncalibrated)** and findings against `inferred`
  expectations are reported in their own clearly-marked section.

## Refresh (`refresh <charter>`) — the drift audit

`explore` creates; `refresh` reconciles. Run it when a feature has been
enhanced, or on suspicion that the charter and the product have drifted apart.
It requires an existing charter (and uses its dossier where one exists).

Procedure: re-run Step 2 from scratch — derive a **fresh** expectations dossier
from today's spec, schemas and code — then three-way compare: *stored dossier*
vs *fresh dossier* vs *the charter's oracles and journeys*. Nothing is applied;
every delta becomes a proposed amendment for human review, classified first by
**direction**, because direction is what decides whether the oracle or the
product is wrong:

| What moved | What it means | Proposal |
|---|---|---|
| **Source of truth changed** (spec amended, schema field added), code follows | the oracle is stale | amend the oracle/dossier entry, citing the new spec section |
| **Only the code/UI changed**, sources unchanged | NOT an oracle problem — the oracle now has teeth | **no oracle edit.** Run the charter: the mismatch is a candidate defect. If the verdict lane rules it *deliberate*, the spec is now the thing that is wrong — file the documentation gap, update the spec, then refresh again |
| **Both changed, consistently** | a deliberate, documented change | amend, citing both |
| **Both changed, inconsistently** | the genuinely interesting case | surface both citations side by side; a human decides which is authoritative |
| **Surface or journey gone** | removed or renamed feature | propose removing the journey, or retiring the charter |

The anti-circularity rule binds refresh exactly as it binds explore: **code is
never the source that rewrites an oracle.** A refresh that "fixed" oracles to
match drifted code would silently bless every regression and make Pass B
vacuous — the second row of the table is the whole reason oracles exist.

**The deliberate-drift lifecycle**, end to end: the run flags the mismatch →
the verdict lane dispositions it *intended* → the suppression source records it
as known-open, "spec update pending" → the spec is updated → `refresh`
regenerates the oracle from the updated spec → the suppression entry closes.
At no point did the oracle learn from the code; it learned from the spec, one
human decision later. That one-step delay is the feature, not the friction: it
is the only moment where "we changed it on purpose" and "it broke and nobody
noticed" are forced to declare themselves as different things.

A refreshed charter that gained or changed oracles is a changed judge: per the
calibration protocol, treat its next run as calibration, not authority.

## What this mode does NOT change

Pass A never sees the dossier. Fresh-eyes comprehension judgment is only
meaningful when the explorer knows as little as a real first-time user —
expectation synthesis feeds Pass B and the charter's structure, nothing
else.
