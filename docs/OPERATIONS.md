# Operations Guide

Everything needed to install this harness into a product, get its first
trustworthy run, and keep it honest. This document is the mechanics.

If the words *profile*, *charter*, *oracle* and *lens* are not yet clear, read
**[concepts.md](concepts.md)** first — it explains them with one e-commerce
example carried end to end, and this guide will make much more sense afterwards.
The [README](../README.md) covers the principles.

Throughout, `<skill>` means wherever the skill was installed (default
`skills/ui-qa`), and `<explorer>` means the product's explorer directory
(default `qa/product-explorer`).

---

## 0. Prerequisites

| Need | Why |
|---|---|
| Claude Code and/or Codex | dispatches the evaluator and its subagent passes |
| Node + `npx` | the Playwright MCP adapter runs `@playwright/mcp` |
| `python3` (3.9+) | the run gate (`verify_run.py`) and the fixture server |
| A **runnable** stack with a health check | the harness drives the real app; there is no mock mode |
| A way to isolate durable state | required before any state-mutating charter |
| A human who can approve things | a profile, exemplars, and value tiers all need an owner |

That last row is not a formality. A profile nobody approved authorizes
nothing, and an empty approved-exemplar set makes calibration fail preflight
by design.

---

## 1. Install

```bash
git clone https://github.com/Anandsharma1/user-zero.git
cd user-zero
./scripts/install.sh /path/to/your-product-repo
```

Options: `--dest <path>` (where the skill lands, default `skills/ui-qa`),
`--platforms "claude codex"`, `--explorer-dir <path>`.

What it overwrites and what it never touches:

| Path | On install / upgrade |
|---|---|
| `<skill>/` | **replaced** — harness code, upstream-owned |
| `.claude/`, `.codex/` stubs | **regenerated** — never hand-edit these |
| `<explorer>/PROFILE.md`, `charters/`, `calibration/` | **never overwritten** — yours |

Then the four manual steps the installer prints:

**a. Ignore the evidence directory.**

```gitignore
qa-output/
```

**b. Register the browser MCP server.** Details and the pinned version:
`<skill>/adapters/playwright-mcp.md`.

Claude Code — project `.mcp.json`:

```json
{ "mcpServers": { "playwright": {
  "command": "npx", "args": ["-y", "@playwright/mcp@0.0.78", "--isolated"] } } }
```

Codex — `.mcp.json` is **not** read; register under `CODEX_HOME` (confirm which
home before writing, or you get a server that silently never loads):

```bash
echo "${CODEX_HOME:-$HOME/.codex}"
codex mcp add playwright -- npx -y @playwright/mcp@0.0.78 --isolated
codex mcp list
```

Restart the agent session, then **verify the tools are actually present**. A
config file is not evidence that the tools loaded.

**c. Fill in the profile** — §2 below.

**d. Tell your agents the harness exists**, in your own `AGENTS.md` /
`CLAUDE.md` (the installer will not write your instruction files):

```markdown
UI QA: read `skills/ui-qa/SKILL.md` before any UI QA, charter run, or /ui-qa request.
```

---

## 2. Onboard a product (once)

`PROFILE.md` is the only artifact you rewrite per product. Schema and
procedure: `<skill>/references/profile-schema.md`.

Run the **two-role onboarding**, in parallel if your environment allows:

- **Product/domain explorer** — reads product docs and the UI surface.
  Produces: product summary, personas, vocabulary and format conventions, the
  product half of the oracle map, suppression sources.
- **Runtime/coverage explorer** — reads run mechanics and test infrastructure.
  Produces: bring-up and health gate, isolation mechanism, modes, downstream
  integrations, adapter and viewports, test data — plus **coverage notes
  telling charters what NOT to duplicate**.

Merge into `<explorer>/PROFILE.md` with `status: draft`, then get a human to
approve it and record who/when at the top.

The three sections people get wrong:

- **§3 Isolation** — a snapshot is not enough. You need the *runtime proof*
  that the running process carries every redirect, and a marker check showing
  one UI-created row landed in the snapshot and **not** in real data. Without
  those, do not run a state-mutating charter at all.
- **§4 Modes** — if the product has an auth-off or legacy-data mode, say
  explicitly what it is valid evidence *for*. Readiness claims require the
  production-representative mode; the harness enforces this only if you write
  it down.
- **§7 Oracle map traps** — for each authoritative document, the usage rules
  that prevent false findings: which sections are assertable, which amendments
  supersede, which naming quirks are intentional. Traps prevent more wasted
  triage than any other section.

---

## 3. Author a charter

Copy `templates/charter.md` to `<explorer>/charters/<name>.md`. Or let the
harness draft one:

```
/ui-qa explore <route|module|functionality>
```

That runs expectation synthesis (`<skill>/references/expectation-synthesis.md`):
it maps the target to concrete surfaces, derives an **expectations dossier**
(behavioral expectations, a field-significance table, and explicit unknowns —
each tagged `specified` / `derived` / `inferred` with a citation), and drafts a
charter. Add `--run` to execute immediately as a clearly-labeled uncalibrated
run.

The rule that makes the dossier trustworthy: **code is never its own oracle.**
A code-derived expectation can support a finding of *inconsistency* (the UI
contradicts its data source; sibling surfaces disagree; a field arrives from
the API and never renders) but never a verdict that a displayed value is
*right*. The dossier's `Unknowns` section is a deliverable in itself — a
documentation-gap list worth triaging.

Authoring discipline, in one line: **the hard part is trimming.** Cap oracles
at 3–4 per section and let exploration find the rest. A charter stuffed with
checks converts an explorer into a checklist runner, and discovery goes to
zero.

**Lens selection** goes in §6 of the charter:

```markdown
## 6. Pass-A brief
lenses: [ai-product-ux]
```

Name only what the surface actually has. An irrelevant lens produces
irrelevant findings and scores against the generic-commentary metric — a
motion lens on a static table will find motion problems on a screen that
correctly has none. See `<skill>/lenses/MANIFEST.md`.

---

## 3b. The shortcut: `glance`

Steps 2 and 3 exist so a finding can become evidence. If you only want an expert
opinion on a screen, skip them:

```
/ui-qa glance <route|url> [--persona "..."] [--lenses a,b] [--viewports a,b]
<skill>/scripts/verify-run.sh qa-output/<run_id> --glance
```

No profile, no charter, no coverage matrix, no calibration. The evaluator's
expertise is identical — taxonomy plus any lenses you name — and it genuinely
uses the app: journeys end to end, functionality, navigation, console and network,
unhappy paths, each requested viewport.

On data it goes as far as the UI allows: internal consistency (totals vs rows,
screen vs screen), the rendered value vs the payload the page received, honest
missing values, plausibility, and persistence by reload. It cannot pronounce a
value **correct** — that needs an oracle — so those become `needs_oracle:`
questions, which is the most useful thing a glance can hand you: a shortlist of
what a real charter should verify.

Its output is labeled accordingly and the gate refuses a run whose label is
missing, or one that claims a value is wrong without a `needs_oracle` marker.

Use it to triage a screen, to decide which surfaces deserve a real charter, or to
demo the harness before committing to setup. Do not use it for a readiness call,
do not feed it to the regression or RCA lanes, and do not count it as coverage.
Full rules: `<skill>/references/glance-mode.md`.

## 4. Run

```
/ui-qa                                    list charters + isolation classes
/ui-qa <charter> [<charter> ...]          run
/ui-qa <charter> --cohort novice,expert   one Pass A per persona, then aggregate
/ui-qa <charter> --calibrate              calibration run (never readiness)
/ui-qa explore <target> [--run]           synthesize a charter
/ui-qa refresh <charter>                  drift audit after a feature change
```

### Scheduling and isolation

| Class | Parallel? | Requires |
|---|---|---|
| `observation-only` | only if each explorer has its **own** browser server instance | — |
| `state-mutating` | never | fresh snapshot + fresh browser profile per run, verified live |
| `external-provider` | never | the explicit authorization recorded in the profile |

Under the default single Playwright MCP connection there is **one** browser
context, and subagents of a session share it — two explorers interleave and
corrupt each other. So browser exploration is **serialized by default**, even
for observation-only charters. Cohort runs multiply the class by the persona
count: four personas on a state-mutating charter is four serial runs from four
fresh snapshots.

### Gate the run before you read it

```bash
<skill>/scripts/verify-run.sh qa-output/<run_id>          # --cohort for cohort runs
<skill>/scripts/verify-run.sh qa-output/<run_id> --pass-a-only   # documented degraded mode
```

Checks, mechanically: required artifacts (**including `pass-b-report.md`** —
a run with no oracle pass is not a run, and `--pass-a-only` is the explicit,
self-labeling exception); each Pass-A artifact still hashing to the value
recorded **against its own path** in `debrief.md`; the `## Read declaration`
present in every Pass-A report; every **required** coverage row accounted for,
with covered rows' evidence existing **inside** the run directory; finding
records complete **per record**; no unredacted credentials, reported as
file:line without echoing the secret; no stack state in the run directory.

Two prerequisites the runner owns, not the explorer:

- `coverage-required.tsv` must be written **before Pass A** from the charter and
  profile. Without it the gate fails, because an explorer that defines its own
  denominator can satisfy any matrix.
- `debrief.md` hash lines must be `sha256(<path>) = <hex>`. A bare hash list
  lets one artifact's hash vouch for another.

**A run that fails the gate is an incomplete run**, reported as such — not
coverage with caveats. What the gate cannot check: whether a `covered`
screenshot really shows that state, whether an `na` reason is honest, or whether
a credential is visible inside an image. It removes the accidental silent gap;
the deliberate one is calibration's problem.

### Reading the output

`qa-output/<run_id>/` where `run_id = <date>-<charter>-<HHMMSS>`:

| File | Read it for |
|---|---|
| `debrief.md` | **start here** — PROOF, and the explorer's own confidence under *Feelings* |
| `coverage.tsv` | what was and was not reached — read the `blocked` rows first; they are often the most product-relevant output of the whole run |
| `exit-interview.md` | the persona's naive verdict, written before any oracle |
| `findings.md` | classified, deduped, value-ranked findings |
| `pass-a-report.md` | fresh-eyes narrative (hash-protected) |
| `pass-b-report.md` | oracle verification |
| `evidence/` | the screenshots every visual claim depends on |
| `packets/` | one per reproduced defect, ready for the verdict lane |

Two signals worth acting on immediately:

- **Low self-rated confidence in *Feelings*** — triage the run before triaging
  the findings. Something degraded it.
- **Exit interview contradicting the findings** — "all journeys completed,
  difficulty 6" means the product works and hurts. That is the finding class
  scripted suites structurally cannot produce; do not reconcile it away.

`qa-output/` is ephemeral and gitignored. Durable outcomes live in the verdict
lane's dispositions, the pinned regression tests, and the RCA ledger.

---

## 5. Calibrate before you believe anything

Protocol: `<skill>/references/calibration-protocol.md`.

### Fastest path: the shipped fixtures

The harness repo ships its own corpus, so a first calibration needs no product:

```bash
fixtures/serve.sh &                  # note the printed origin
fixtures/probe.sh                    # all 28 controls must report ARMED
# in a session that has NOT read fixtures/controls.tsv:
/ui-qa fixture-dashboard --calibrate
/ui-qa fixture-dashboard --calibrate # second run, for consistency
```

Use `fixtures/explorer/` as the explorer directory: it holds an approved
`PROFILE.md`, two charters, and both calibration files with suggested in-scope
sets. `probe.sh` enforces the control floor and fails if a seeded defect has been
edited away — calibrating against a stale denominator is worse than not
calibrating.

Two limits to state in any result: fixtures are static files, so nothing about
persistence, async finality, concurrency, or isolation is exercised; and a charter
calibrated only here must carry `calibrated against fixtures only` in its
authority line. See `fixtures/README.md`.

### Against a real product

1. **Arm negative controls.** Executable seeds checked in under
   `<explorer>/calibration/seeds/<ID>.*`, or an exactly recorded pre-fix
   baseline revision — each with a live probe and a digest-verified
   restoration. Prose descriptions are `registered` and count for nothing.
2. **Curate positive controls.** A human marks screens as acceptable in
   `accepted-exemplars.md`, and records the imperfections they are knowingly
   accepting. Shipped ≠ accepted. An empty set fails preflight.
3. **Predeclare the denominator.** Fix the in-scope control set *before* the
   run.
4. **Run blind — both passes.** Whoever armed the seeds explores neither. Pass
   B is also a fresh context that never learns a calibration is underway. An
   informed rediscovery score is answer leakage and void.
5. **Repeat once** on the same state for the consistency metric.
6. **Score all seven metrics**, and report `not measurable` as its own outcome
   where the human side is missing.

| Metric | Default bar |
|---|---|
| Rediscovery | ≥ 70% of the predeclared in-scope controls |
| False-positive burden | 0 rejected high-severity findings on exemplars |
| Consistency | ≥ 60% overlap across 2 repeat runs (matched on route+problem, not wording) |
| Tier agreement | ≥ 70% of opportunity tiers survive owner review |
| Specificity | ≥ 80% contract-clean without edits |
| Actionability | ≥ 75% implementable without a clarifying question |
| Generic commentary | ≤ 1 finding per run with no route-specific observation |

**Repair-lift** is the strong form of actionability, and worth running on a
sample: hand a finding's recommendation *alone* to an implementer who has not
seen the screen, apply it in a throwaway branch, re-run the charter, and count
**repaired / misrepaired / unrepairable**. Misrepair — a real finding whose
recommendation sent the implementer at the wrong thing — is the failure mode a
judgment-based actionability score misses entirely.

Below the bar: **tune the charter, not the metric.** Usually that means
trimming oracles or sharpening the Pass-A brief.

A charter with any metric unmeasured is **not calibrated**, and its runs keep
the *harness calibration* label however well the others scored.

**A newly enabled lens is an untested change to the evaluator.** The next two
runs after adding one are calibration runs; if the lens produces only generic
commentary across both, remove it from that charter and record the outcome in
`lenses/MANIFEST.md` so the next project inherits the judgment.

---

## 6. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Explorer reports no browser tools | MCP server not loaded, or registered in the wrong `CODEX_HOME` | Verify with `codex mcp list` / check the tool list; restart the session; never trust the config file alone |
| Console errors that make no sense for this screen | `browser_console_messages` accumulates across runs; `--isolated` does **not** prevent it | End every run with `browser_close` (measured: it clears the buffer; navigation does not). Filter console evidence by origin regardless |
| `Total messages: 0` and then an error listed underneath | The header is scoped to the current page; the list is scoped to your request | Read the list, never the header |
| Findings about content that never rendered | Snapshot taken mid-load | Wait for a concrete element/state before sensing; a half-loaded screen is not evidence |
| Findings about UI the persona cannot see | The a11y snapshot includes off-screen elements | Scroll into view before asserting reachability or screenshotting |
| Long, shallow, checklist-shaped report | Oracle overload | Trim to 3–4 oracles per section; discovery is inversely proportional to enumeration |
| Findings are all true and all useless | Actionability failure | Run repair-lift on a sample; sharpen recommendations to name the element and the change |
| Run "passed" against a mode that proves nothing | Missing or ignored profile §4 | Readiness claims require the production-representative mode; qualify every claim by mode |
| Real data changed during a run | State-mutating charter without verified isolation | Stop. Verify the live redirect proof and the marker check before ever running it again |
| Same defect re-reported every run | It is in a suppression source | Cite, do not re-report — unless it was *fixed*, in which case it is a regression |
| Platform dirs disagree | Someone hand-edited a generated stub | `./scripts/sync-platform-dirs.sh`; install the pre-commit hook |
| Sync check green but the commit is stale | The check ran against the working tree, not the index | Use `--from-index` (the hook does); partial staging is exactly this hole |
| Codex does not see the skill | Wrong location: Codex reads `$REPO_ROOT/.agents/skills` | Regenerate with `--platforms codex`; §Platform layouts below |
| Every persona in a cohort reports the same console error | Console buffer carried across personas | Reset browser state between personas (`browser_close`); filter console evidence by origin |
| Gate fails on credentials you did not add | Network evidence captured whole headers from an authenticated session | Redact at capture; request the narrowest part; see `references/evidence-schema.md` §Redaction |
| Pass A states a value is *correct* | Contamination — fresh eyes have no oracle | Void and re-run per `references/pass-a-dispatch.md` §5 |
| Temporal finding with no evidence | The adapter exposes no video/trace | Report before/after stills + described sequence, marked *needs video verification*; do not overclaim a measured duration |

## Platform layouts

Where the generated stubs go, and why:

| Platform | Locations | Provenance |
|---|---|---|
| `claude` | `.claude/skills/ui-qa/SKILL.md`, `.claude/agents/user-zero.md`, `.claude/commands/ui-qa.md` | Claude Code project skill/agent/command dirs |
| `codex` | `.agents/skills/ui-qa/SKILL.md` + `agents/openai.yaml` | Codex's documented repo-scoped location is `$REPO_ROOT/.agents/skills`, with per-skill agent metadata as `agents/openai.yaml` ([docs](https://learn.chatgpt.com/docs/build-skills)) |
| `codex` (also) | `.codex/skills/ui-qa/SKILL.md` | compatibility — some builds and wrappers scan here; harmless duplication of a pointer stub |
| `cursor`, `gemini` | `.cursor/skills/…`, `.gemini/skills/…` | opt-in via `--platforms`, not generated by default |

Only the pointer stub is duplicated, never method content, so a platform whose
convention changes costs one line in the generator.

---

## 7. Upgrade the harness in a product repo

```bash
cd /path/to/user-zero && git pull
./scripts/install.sh /path/to/your-product-repo
```

The skill and the generated stubs are replaced; your profile, charters, and
calibration inputs are untouched. Two things to check afterwards:

1. **Adapter version.** If the pinned Playwright MCP version moved, the
   measured tool caveats were re-measured for that version — re-read the
   adapter's caveats section and re-register the server.
2. **New or changed lenses.** A lens added upstream is not active until a
   charter names it, and its first two runs on your product are calibration
   runs.

---

## 7b. Uninstall

```bash
./scripts/uninstall.sh /path/to/your-product-repo --dry-run   # show the plan
./scripts/uninstall.sh /path/to/your-product-repo             # keeps your work
./scripts/uninstall.sh /path/to/your-product-repo --purge-explorer
```

Removes the skill directory, the generated pointer stubs, and
`.ui-qa-install.json`. Keeps `<explorer>/` and `qa-output/` unless
`--purge-explorer` is passed. Deletion is marker-gated exactly as on install: a
file at a generated path that this harness did not write is reported and left
alone, and a manifest naming a reserved directory is refused.

Left for you, because they are your files: the MCP registration, the line in
`AGENTS.md`/`CLAUDE.md`, and the `qa-output/` entry in `.gitignore`.

## 8. Develop the harness itself

```bash
./scripts/install-git-hooks.sh                   # pre-commit: staged-index sync + purity scan
./scripts/sync-platform-dirs.sh                  # after editing skills/ui-qa/
./scripts/check-platform-sync.sh --from-index    # what the hook runs
./tests/run-tests.sh [-v]                        # 81 tests, no dependencies
```

Rules for contributors:

- **Tooling changes need a test.** Every one of the installer-containment,
  drift-detection, and run-gate tests exists because a reviewer found the
  corresponding hole by hand. Do not fix a tooling bug without adding the test
  that would have caught it.

- **Edit only `skills/ui-qa/`** (or the generator's heredocs). Everything under
  `.claude/` and `.codex/` is generated and will be overwritten.
- **No product strings in Layer 1, ever** — no product names, hostnames, ports,
  absolute paths, or machine-specific config. If a fact is true of one product
  only, it belongs in `PROFILE.md`. Quick check before committing:

  ```bash
  grep -rniE '<your-product>|localhost:[0-9]+|/home/|/Users/' skills/
  ```

- **A new lens needs a trigger that excludes most surfaces.** If you cannot
  write one, the content belongs in the spine instead — and the spine's budget
  is finite, which is a design constraint, not an oversight.
- **Every question must be answerable from the rendered UI alone.** If it needs
  source access, it is a Pass-B oracle, not a lens.
- **Measured claims carry their measurement.** The adapter's console-buffer
  table exists because it was probed on a specific version and date. Add the
  version and date, or do not add the claim.
