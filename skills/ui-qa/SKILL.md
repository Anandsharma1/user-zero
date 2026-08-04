---
name: ui-qa
description: Human-style product QA explorer. Drives the real application UI in a browser like a skilled human QA — judging usability, comprehension, information hierarchy, visual quality, and data honesty — and turns objective correctness findings into reproducible evidence for the project's authoritative review lane. Use when asked to QA a functionality end to end through the UI, run a QA charter, or calibrate the QA harness.
---

# ui-qa — Human-Style Product QA Explorer

This skill is the **portable core**: pure method, no project content. Every
path below is relative to this skill's own root directory, wherever it is
installed.

Everything project-specific lives outside the skill in the project's explorer
directory (default `qa/product-explorer/`), which contains:

- `PROFILE.md` — the product binding: bring-up, isolation mechanism, personas,
  oracle map, suppression sources, downstream integrations, viewports.
  Schema: `references/profile-schema.md`.
- `charters/<name>.md` — one testing mission per functionality.
  Schema: `references/charter-schema.md`.
- `calibration/` — project-approved known defects and accepted exemplars.
  Protocol: `references/calibration-protocol.md`.

This skill is **not** a scripted-test executor and not a substitute for the
project's regression suites. It is a product explorer: its experiential and
visual observations become value-ranked product input, and its objective
correctness findings become reproducible evidence for the project's
authoritative review lane.

## Invocation

`/ui-qa glance <route|url> [--persona "..."] [--lenses a,b] [--viewports a,b]`
`/ui-qa <charter-name> [<charter-name> ...] [--calibrate]`
`/ui-qa <charter-name> --cohort <persona>[,<persona>...]`
`/ui-qa explore <route|module|functionality> [--run]`

- With `glance <route|url>`: **the lightweight mode.** One expert look at one
  screen — no profile required, no charter, no Pass B, no coverage matrix, no
  calibration. Output is labeled as opinions, not evidence, and licenses
  nothing. Use it to find the obvious problems and to decide where a real
  charter is worth writing. Procedure and limits:
  `references/glance-mode.md`. Everything below this line describes the full
  mode.

- With one or more charter names: run those charters (scheduling rules below).
- With `--calibrate`: run the calibration protocol for the named charters and
  label ALL output "harness calibration", never product readiness.
- With `--cohort`: run Pass A once per named persona, each in its own fresh
  context, then aggregate. Procedure and what a cohort does and does not
  license you to claim: `references/persona-cohorts.md`.
- With `explore <target>`: no charter exists yet — synthesize one. The skill
  discovers the target's surfaces, derives what the UI should show and how it
  should behave (an **expectations dossier**: behavioral expectations, field
  significance, and explicit unknowns, each with source + confidence tier),
  and drafts a charter for human review; `--run` executes it immediately as a
  clearly-labeled uncalibrated run. Procedure and the anti-circularity rule
  (code is never its own correctness oracle):
  `references/expectation-synthesis.md`.
- With no arguments: list available charters from the explorer directory and
  their isolation classes; do not run anything.

If `PROFILE.md` is missing, do not improvise a profile — run the onboarding
procedure in `references/profile-schema.md` to draft one, and stop for human
approval before any charter claims authority. **`glance` is the exception**: it
needs no profile because it claims nothing. Offer it when someone wants a quick
read and does not want to set the harness up.

## Browser tooling

All browser interaction goes through the abstract capability contract in
`references/browser-driver-contract.md`. The concrete tool binding is an
adapter chosen by `PROFILE.md` (adapters live in `adapters/`). Never write
driver-specific commands into charters or the profile's oracle sections —
only the adapter file knows the tool.

Sensing rules (all adapters):

- Accessibility tree is the primary navigation sense; act on role+name, not
  pixel coordinates.
- Screenshots are **mandatory evidence for every visual or experiential
  claim**, and are captured at journey milestones, failure states, and empty
  states, across every viewport the charter declares.
- Console and network activity are first-class evidence; an unexpected
  console error during a journey is a finding even when the screen looks fine.
- Snapshot/inspect before acting; after any blocked interaction, re-snapshot
  and re-orient rather than retrying blind.

## The evaluator and its expertise

Pass A is performed by the **user-zero agent** (`agents/user-zero.md`) — a
senior UX evaluator who experiences the product as the charter's persona but
diagnoses with an expert's vocabulary. Its expertise is two layers:

- `references/ux-evaluation-taxonomy.md` — the **spine**: the always-loaded
  question catalog (Gestalt layout, information hierarchy and density,
  component-pattern appropriateness, component behavior, table craft,
  navigation completeness, sizing and real estate, typography and theme,
  feedback and state honesty, microcopy, cognitive load, accessibility) plus
  the two methods that structure a pass.
- `lenses/*.md` — **optional lens packs** for concerns the spine does not
  carry, selected per charter (`lenses/MANIFEST.md` is the registry).

Both are **method, not product knowledge**, so both are allowed in Pass A —
a human expert does not forget their craft when handed a fresh product. The
product's specs, state models, and expected values remain Pass-B only.

Lenses are read *by* the evaluator; they are never dispatched as separate
reviewers. One evaluator, one finding stream, one severity model — lenses
widen what it looks for, they do not multiply the reports.

## Execution shape (per charter)

1. **Preflight.** Bring up or validate the stack per `PROFILE.md` (health
   gate mandatory — never test against a half-up stack). Discover runtime
   facts (port owners, process identity) fresh each run; never reuse recorded
   PIDs or assume a prior run's state. For state-mutating charters, take the
   profile-defined durable-state snapshot and verify the application is
   actually running against the isolated copy before any interaction.
2. **Pass A — fresh eyes.** Dispatch the **user-zero agent** per
   `references/pass-a-dispatch.md` — which defines the platform-specific
   dispatch, the isolation requirements, the mandatory read declaration, and
   the contamination checks the runner performs before accepting the report.
   **If a fresh context cannot be guaranteed, do not run Pass A**: run Pass B
   only and label the output *Pass-B only — no fresh-eyes evidence*.
   The explorer gets ONLY the **Pass-A packet**
   (`references/charter-schema.md` §Pass-A packet): origin, entry route,
   mission, persona, north-star question, journeys, viewports, selected
   lenses, required coverage rows, evidence directory, adapter instructions,
   and conduct rules. The
   agent brings its own expertise (spine + selected lenses). No project
   instruction files, no specs, no state models, no expected values, no
   source access. Pass A closes with an **exit interview**
   (`references/evidence-schema.md`) — the persona's own answers before any
   oracle can reframe them. **Pass A's report is finalized and hashed before
   Pass B starts.**
3. **Pass B — informed.** With the charter's oracles, the profile's oracle
   map, and console/network evidence loaded, verify functional behavior,
   data correctness, and recovery/error states. Where the UI alone cannot
   establish correctness (aggregates, persistence, async finality,
   ownership, fabricated-zero suspicion), inspect the relevant API response,
   durable record, or job state directly. Pass B may *explain* a Pass-A
   confusion; it must never erase it — "spec-compliant but incomprehensible
   to the persona" remains a valid finding.
4. **Classify** every candidate finding by nature, not by which pass found it:
   - **Product defect** — broken behavior, dishonest state, incorrect data,
     accessibility failure, or explicit contract violation.
   - **Experience opportunity** — comprehension, hierarchy, friction,
     aesthetic, density, or presentation improvement with no objective
     contract violation. Ranked `highly-valuable` / `valuable` / `good-to-have`.
   - **Observation** — noticeable but insufficiently consequential or
     confident; recorded, no action.
   Before classification, dedupe against the profile's suppression sources
   (known-open debt, declared-partial features, planned near-term work).
   A finding that restates a planned item is roadmap confirmation, not a defect.
5. **Reproduce** each product defect from a fresh context (fresh browser
   state; fresh snapshot if state-mutating). A defect that does not reproduce
   is downgraded to an observation with the non-repro noted.
6. **Assemble evidence packets** for reproduced defects per
   `references/evidence-schema.md`.
7. **Disposition.** Hand defect packets to the profile's verdict lane for the
   authoritative call: `confirmed` / `invalid` / `known-open` / `deferred` /
   `out-of-scope`. The verdict lane may check whether an experience finding
   contradicts known product intent, but it must not invalidate demonstrated
   user confusion merely because the screen follows the specification.
   Experience opportunities bypass the defect gate and go directly into the
   value-ranked list.
8. **Gate the run.** Run `scripts/verify-run.sh qa-output/<run_id>`
   (`--cohort` for cohort runs). It enforces mechanically what the method
   otherwise only asserts: required artifacts, Pass-A hash integrity, a
   complete coverage matrix (`references/coverage-contract.md`), finding-record
   completeness, credential redaction, and stack/evidence separation. **A run
   that fails the gate is an incomplete run, not coverage with caveats** — say
   which cells and which checks failed.
9. **Downstream.** Confirmed defects flow to the profile's regression-writer
   and RCA skills. The run report (schema: `references/evidence-schema.md`)
   is written to `qa-output/<run_id>/` (unique per run — see evidence
   schema) with a PROOF debrief —
   Past, Results, Obstacles, Outlook, Feelings (the explorer's self-rated
   confidence, stated plainly; triage reads it first).

## Scheduling and isolation

Every charter declares one isolation class; the runner enforces it:

- **observation-only** — the charter performs no durable mutation through the
  UI. May run in parallel with other observation-only charters ONLY when the
  adapter provides each explorer a dedicated browser instance (see the
  adapter's concurrency section); otherwise browser exploration is
  serialized by default.
- **state-mutating** — the charter changes durable application state (writes,
  jobs, imports, annotations). Runs strictly serially, each from a fresh
  durable-state snapshot, fresh backend process where the profile requires
  it, and a fresh browser profile. Mutating the *application through its UI*
  is the explorer's job; mutating the *repository* is forbidden.
- **external-provider** — the charter triggers calls to external services
  with cost, quota, or data implications. Serial, and only with the explicit
  authorization the profile records for that provider.

Cohort runs inherit their charter's isolation class and multiply it by the
persona count: a state-mutating charter run across four personas is four
serial runs from four fresh snapshots, not one run with four viewers.

Explorers are repository-read-only. They never run destructive git commands,
never edit source, and Pass-A explorers do not read source at all.

## Finding quality contract

No finding may be a vague judgment ("this looks bad"). Every finding carries:
route and UI state; affected persona; screenshot reference; the specific
observed problem; the usability, visual, or correctness principle violated;
the user consequence; a recommended improvement; severity; priority (defects);
and the explorer's confidence. Full record schema:
`references/evidence-schema.md`.

**Severity and priority are separate numbers.** Severity is how bad the failure
is, independent of reach and frequency; priority adds reach, frequency,
persistence, and remediation cost. A rare data-corruption path stays
`critical` severity on a page nobody visits; a misaligned label on the busiest
screen stays `low` severity however high its priority. See
`references/ux-evaluation-taxonomy.md` §Severity and priority.

## Coverage is declared and gated, not narrated

Every run fills in `coverage.tsv` — journey × viewport × state, plus
navigation integrity, input modality, themes, and (for state-mutating
charters) interruption. Cells are `covered` with evidence, or `blocked`/`na`
**with a reason**. Silence is not coverage, and no percentage is ever computed.
Contract: `references/coverage-contract.md`.

## Calibration before trust

Until a charter has passed the calibration thresholds in
`references/calibration-protocol.md` (rediscovery of known problems, low
high-severity false-positive rate on accepted exemplars, run consistency,
recommendation specificity and actionability), its runs are labeled
**harness calibration** and must not be presented as evidence of product
readiness. The goal is not silence — it is a small number of grounded,
useful product observations.

## Hard rules

- Never declare a functionality "ready" from a green run in a mode the
  profile marks as non-production (e.g. auth-off legacy modes); readiness
  claims require the profile's production-representative mode.
- Never let a run mutate the project's real working data: state-mutating
  charters run only against the profile's isolated snapshot, verified live.
- `qa-output/` is ephemeral evidence, kept out of version control.
- Findings the profile's suppression sources already record are cited, not
  re-reported.
- Report failures honestly: a charter that could not complete (stack down,
  blocked journey, missing data) reports exactly that — never a partial pass
  dressed as coverage.
