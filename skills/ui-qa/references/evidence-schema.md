# Evidence Schema

## Run output layout

Every run gets a unique `run_id`: `<YYYY-MM-DD>-<charter>-<HHMMSS>`.
Same-day repeat runs (required by consistency calibration) therefore never
collide; a directory that already exists is an error, never overwritten.

```
qa-output/<run_id>/
    pass-a-report.md          # immutable once finalized (hash below); ends with the read declaration
    exit-interview.md         # the persona's own words, written before Pass B
    pass-b-report.md          # required — a run with no oracle pass is not a run
    findings.md               # classified, deduped, value-ranked
    coverage-required.tsv     # the REQUIRED matrix, written by the runner BEFORE Pass A
    coverage.tsv              # what was actually reached — gated against the required set
    evidence/                 # screenshots, console/network excerpts, recordings
        <NN>-<slug>.png
    packets/                  # one per reproduced product defect
        <defect-slug>.md
    debrief.md                # PROOF (below) + pass-a sha256
```

**A run is not complete until it passes the gate.** Run
`scripts/verify-run.sh qa-output/<run_id>` (add `--cohort` for cohort runs).
It checks artifacts, Pass-A hash integrity, coverage-matrix completeness,
finding-record completeness, credential leakage, and stack/evidence directory
separation. A run that fails the gate is reported as an incomplete run — never
as coverage with caveats.

Cohort runs add one level: `qa-output/<run_id>/personas/<persona>/` holds
each persona's Pass-A report, exit interview, and evidence, with the shared
`findings.md` and `cohort-summary.md` at the run root
(`references/persona-cohorts.md`).

**Pass-A immutability is verified, not promised.** When Pass A finalizes,
record one hash line per artifact in `debrief.md`, **bound to its path**:

```
sha256(pass-a-report.md) = <64 hex>
sha256(exit-interview.md) = <64 hex>
sha256(personas/novice/pass-a-report.md) = <64 hex>     # cohort runs
```

The path binding is not cosmetic. A bare list of hashes lets one artifact's
hash vouch for another — a rewritten Pass-A report passes as long as *some*
recorded hash still matches something — so the gate requires the
`sha256(<path>) =` form and matches per artifact. A mismatch, or a missing
entry, invalidates the run.

`qa-output/` is ephemeral, gitignored evidence. Never commit it; never treat
it as the durable record — durable outcomes live in the verdict lane's
disposition, the regression tests, and the RCA ledger.

**Evidence dir ≠ stack dir.** The profile's stack runner keeps its runtime
state (snapshots, redirects, logs) in a separate directory that teardown
recursively DELETES. Never point the stack runner at `qa-output/` — the
completed report must survive teardown. A compliant runner refuses a stack
dir inside `qa-output/`.

## Finding record (every finding, all three classes)

| Field | Content |
|---|---|
| `id` | `<run_id>-<NN>` (globally unique across repeated runs) |
| `class` | `product-defect` \| `experience-opportunity` \| `observation` |
| `route_state` | route + UI state where observed |
| `persona` | affected persona |
| `screenshot` | evidence file reference (mandatory for visual/experiential claims) |
| `observed` | the specific problem, concretely stated |
| `principle` | the usability / visual / correctness principle violated — cite the taxonomy section or lens that names it |
| `consequence` | what it does to the user |
| `recommendation` | specific improvement, not "make it better" |
| `severity` | defects: critical/high/medium/low — **how bad the failure is, independent of reach or frequency** (`ux-evaluation-taxonomy.md` §Severity and priority). Opportunities: highly-valuable/valuable/good-to-have. The two vocabularies are **not interchangeable** — an `experience-opportunity` labeled "Medium" is an unclassified finding, not a tiered one, and it is invisible to the tier-agreement metric (see calibration protocol) |
| `priority` | defects only: severity + reach + frequency + persistence + remediation cost, with the reasoning in one clause. A rare corruption stays `critical` severity at low priority; a cosmetic flaw on the busiest screen stays `low` severity at high priority. Never fold one into the other |
| `confidence` | explorer's own certainty, stated plainly |
| `suppression_check` | which suppression sources were checked; match citation if known-open |
| `disposition` | defects only, set by the verdict lane: confirmed/invalid/known-open/deferred/out-of-scope |

Calibration example of the bar: not "the scorecard looks untrustworthy" but
"the scorecard leads with an aggregate percentage before showing it is based
on one recommendation, creating false confidence."

**Every finding carries a `class` AND a `severity` from that class's own
vocabulary.** Both are mandatory, because the run report is the only input the
tier-agreement metric has. A run that files all of its findings as
`product-defect` + critical/high/medium/low yields an empty opportunity set, and
the metric then reports "not measurable" — which is indistinguishable, after the
fact, from a run that genuinely found nothing worth ranking. So when a run
produces **zero** experience opportunities, the report must say so explicitly and
say why (nothing rose to it / the surface was purely functional / the charter's
journeys did not exercise a comprehension path). A silent absence is a gap in the
harness; a stated absence is a measurement.

This is not a licence to reclassify defects as opportunities to populate the
metric. A contract violation stays a defect at its defect severity.

## Exit interview (per Pass-A explorer)

The last thing Pass A writes, and the only artifact recorded in the
persona's own voice rather than the evaluator's. It exists because the
diagnostic report is written by an expert who has already rationalized the
experience; the exit interview preserves the naive judgment that the expert
voice smooths over. Written BEFORE any oracle is opened, hashed with the
Pass-A report.

| Field | Content |
|---|---|
| `north_star_answer` | the charter's north-star question, answered in the persona's words — or an explicit "I could not tell from these screens", which is itself the finding |
| `per_journey` | for each journey: completed yes/no; **difficulty 1–7** (1 = very easy, 7 = very hard); the single hardest moment |
| `trust` | would the persona act on what this screen told them? why or why not? |
| `friend_summary` | one or two sentences the persona would tell a friend about this product |
| `surprises` | anything that was not what the persona expected, whether good or bad |
| `abandonment` | any point at which a real user with other options would have left, and what triggered it |

Rules:

- The difficulty ratings are **self-report, not measurement.** They are
  comparable across runs of the same charter and across personas in a
  cohort; they are not a usability score, and they never appear in a
  readiness claim.
- An exit interview that contradicts the finding list is a signal, not an
  error to reconcile: "every journey completed, difficulty 6" means the
  product works and hurts, which is exactly the class of problem scripted
  suites cannot see. Report both.
- Never rewrite the exit interview after Pass B. Pass B may append a
  section explaining a persona's confusion; the original text stands.

## Evidence packet (per reproduced product defect)

- Finding record (above)
- Repro steps in user language + viewport
- Screenshots: state before, defect visible, state after
- Relevant console/network excerpts (trimmed to the defect)
- Cross-layer evidence where the claim is about data: the API response,
  durable record, or job state that proves/refutes what the UI shows
- Reproduction result: fresh-context repro outcome (mandatory before the
  packet goes to the verdict lane)

## Redaction — every artifact, not just packets

Network evidence is the leak vector: the adapter can return full request
headers and response bodies from an **authenticated** session, so cookies,
`Authorization` headers, bearer tokens, JWTs, and personal data land in
`qa-output/` by default rather than by accident.

The rule therefore covers the whole run directory — reports, findings,
packets, console excerpts, network excerpts, and recordings:

- **Redact at capture, not at review.** Replace the value, keep the shape:
  `authorization: Bearer <REDACTED>`, `set-cookie: <REDACTED>`,
  `"email": "<REDACTED>"`. Never paste a raw header block "to trim later".
- **Capture the narrowest part that proves the claim.** The adapter can return
  a single part of a request; prefer status and the one field in dispute over
  the whole body.
- **Screenshots leak too.** A visible token, session ID, real customer name, or
  account number in an image is the same failure with no grep to catch it —
  check before saving, and prefer an element screenshot to a full page.
- **The gate enforces this.** `scripts/verify-run.sh` fails a run whose
  artifacts contain credential-shaped strings unless they are marked
  `<REDACTED>`. It is a pattern scan, so it is a floor, not a proof: it cannot
  read your screenshots, and a novel token format will slip past it.
- **Personal data is not a defect detail.** Where a finding is about a real
  record, cite an identifier the team can resolve internally, not the person's
  data.

## PROOF debrief (per charter run)

- **Past** — what was explored, journeys walked, viewports covered
- **Results** — finding counts by class/severity; the headline in one line
- **Obstacles** — what blocked or degraded the run (stack, data, tooling)
- **Outlook** — what the next run of this charter should do differently
- **Feelings** — the explorer's self-rated confidence in this run's coverage
  and judgments, first thing a human triager reads
