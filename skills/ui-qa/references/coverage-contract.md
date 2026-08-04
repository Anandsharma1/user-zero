# Coverage Contract

A report can read as thorough while a journey, viewport, or state was never
opened. Nothing in a narrative distinguishes "I checked the error state and it
was fine" from "I never provoked the error state" — which makes an
unenforced coverage claim the harness's most plausible silent failure.

So coverage is **declared as a matrix, filled in as the run proceeds, and
gated mechanically** by `scripts/verify-run.sh`. A run that does not pass the
gate is not coverage; it is an incomplete run and must be reported as one.

## Two files, and why

| File | Written by | When |
|---|---|---|
| `coverage-required.tsv` | the **runner**, from the charter and profile | **before Pass A starts** |
| `coverage.tsv` | the **explorer**, as it works | during the run |

The split is the point. If the explorer both defines and fills its own matrix,
any non-empty matrix passes and the gate measures nothing — a thin run declares
three cells, covers them, and reads as complete. The denominator must exist
before the explorer does, and the gate compares the two files: every required
row must be accounted for in `coverage.tsv` with a status and, where relevant, a
reason. A run with no `coverage-required.tsv` **fails**, because its coverage
claim is unverifiable rather than merely unproven.

`coverage-required.tsv` uses the same columns, with `required` in the status
column and the last column empty.

## The matrix

`qa-output/<run_id>/coverage.tsv` — tab-separated, one row per cell:

```
journey	viewport	state	status	evidence_or_reason
list-recent-items	desktop	happy	covered	evidence/03-list-desktop.png
list-recent-items	desktop	empty	covered	evidence/04-list-empty.png
list-recent-items	desktop	error	blocked	could not provoke; no fault-injection affordance in this mode
list-recent-items	mobile	happy	covered	evidence/09-list-mobile.png
open-item-detail	desktop	loading	na	response was instant at every attempt; no loading state exists to observe
```

`status` is exactly one of:

| Status | Means | Requires |
|---|---|---|
| `covered` | reached, observed, evidenced | a non-empty evidence file |
| `blocked` | should exist, could not be reached | a reason — this is a finding about testability, and often about the product |
| `na` | does not exist on this surface | a reason stating how you established that |

`blocked` and `na` both need a reason precisely because they are the two ways a
gap becomes invisible. "Silence is not coverage" is the whole rule.

## Required rows

The runner derives the required row set before Pass A starts, from the charter
and profile — the explorer does not choose its own denominator:

1. **journey × viewport** — every charter journey at every declared viewport.
2. **State axis per journey**, the six states that must never collapse
   (`ux-evaluation-taxonomy.md` §9): `happy`, `loading`, `empty`, `error`,
   `unavailable`, `pending`. Rows for states the surface genuinely lacks are
   still required — as `na` with a reason.
3. **Navigation integrity per journey**: `back`, `refresh`, `deep-link`.
   Browser Back safety and refresh reproducibility are claims the harness
   makes; they need cells.
4. **Input modality**: `keyboard` for every journey; `touch` additionally when
   a small viewport is declared or the `touch-and-mobile` lens is selected.
5. **Theme**: each shipped theme for the charter's money screens.
6. **Interruption**, when the charter is `state-mutating`: `cancel-midway` and
   `concurrent-update` — the states where durable damage hides.

A charter may add rows. It may not delete a required one; it can only mark it
`na` with a reason, which is reviewable.

## What the gate checks, and what it cannot

`scripts/verify-run.sh <run_dir>` checks, mechanically:

- required artifacts exist and are non-empty — including `pass-b-report.md`,
  unless `--pass-a-only` is passed explicitly, which prints its own warning and
  requires the output to be labeled *Pass-A only — no functional verification*;
- each Pass-A artifact still hashes to the value recorded **against its own
  path** in `debrief.md` (Pass-B rewriting is detected, not trusted);
- every Pass-A report contains its `## Read declaration` section, without which
  the contamination audit does not exist;
- every **required** row is accounted for, and every declared row is `covered`
  with a non-empty evidence file **resolving inside the run directory**, or
  `blocked`/`na` with a reason;
- every finding record **individually** carries all mandatory fields (counted
  per record, so a duplicated field in one cannot cover a gap in another), and
  opportunity tiers are not filed under defect severities;
- no unredacted credentials anywhere in the text artifacts — reported as
  file:line only, never echoing the matched secret into a terminal or CI log;
- the run directory is not doubling as a stack directory.

**What it cannot check**: whether the screenshot in a `covered` cell actually
shows that state, whether an `na` reason is honest, or whether a credential is
visible *inside* an image. A determined explorer can satisfy the gate with
mislabeled evidence. The gate removes the *accidental* silent gap — the one a
tired run produces — and leaves the deliberate one to calibration and review.
Claiming more than that would be the same overclaiming the harness rejects
everywhere else.

## Coverage is not a score

Do not compute a percentage. `18 covered / 3 blocked / 4 na` is a description
of a run; "86% coverage" invites comparison across charters whose denominators
were chosen differently. Report the three counts and read the `blocked` list
first — it is usually the most product-relevant output of the whole matrix.
