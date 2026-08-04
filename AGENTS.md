# AGENTS.md — working in this repository

This repo is the **ui-qa harness**: a portable, product-agnostic method for
browser-driven human-style UI QA. It contains no product code and no product
knowledge.

## Before you change anything

Read `skills/ui-qa/SKILL.md`. It is the canonical method; everything else in
the repo either supports it or points at it.

## The one structural rule

The skill exists **once**, at `skills/ui-qa/`. Everything under `.claude/` and
`.codex/` is **generated** by `scripts/sync-platform-dirs.sh` and will be
overwritten.

```bash
./scripts/sync-platform-dirs.sh                  # after any edit under skills/ui-qa/
./scripts/check-platform-sync.sh --from-index     # verify what git will commit
./tests/run-tests.sh                             # must stay green
```

The pre-commit hook runs the `--from-index` check plus a Layer-1 purity scan.
Checking the working tree alone passes while a partially staged commit records a
stale stub — that is why `--from-index` exists, and why the hook never omits it.

**Any change to `scripts/` or `skills/ui-qa/scripts/` needs a test in
`tests/run-tests.sh`.** Every existing test corresponds to a hole a reviewer
found by hand; that is the standard.

Never hand-edit a generated stub. If a platform needs different wording, change
the generator's heredoc so every platform stays derived from one source.

## Layer discipline

| Layer | Lives | Contains |
|---|---|---|
| 1 — method | `skills/ui-qa/` (this repo) | zero product strings |
| 2 — binding | consuming repo's `qa/product-explorer/PROFILE.md` | one product's specifics |
| 3 — missions | consuming repo's `charters/`, `calibration/` | one functionality each |

**No product strings in Layer 1, ever** — no product or company names,
hostnames, ports, absolute paths, or machine-specific config. Before
committing:

```bash
grep -rniE 'localhost:[0-9]+|/home/|/Users/|C:\\\\' skills/ templates/
```

Templates carry placeholders (`<product name>`, `<port>`), never real values.

## Adding to the evaluator's expertise

- **Spine** (`references/ux-evaluation-taxonomy.md`) — only for concerns nearly
  every product has. Its size is a hard constraint: it must fit a fresh-eyes
  context alongside the mission packet with room left to think.
- **Lens** (`lenses/<name>.md`) — for concerns only some products have. Needs a
  registry row in `lenses/MANIFEST.md` with a trigger that **excludes most
  surfaces**. If you cannot write such a trigger, it belongs in the spine — and
  the spine is full.
- Every question must be answerable **from the rendered UI alone**. If it needs
  source access, it is a Pass-B oracle, not a lens.

## Threat model

`docs/threat-model.md` states what the tooling defends against — a tired
operator, a degraded explorer, filesystem accidents, prose drifting from code —
and what it does not: an actor who can already write to the repository. Before
hardening anything, check which side of that line the concern is on. "An attacker
could forge this" is out of scope by design; "a tired operator could reach this
by accident" is in scope even when it looks like the same code path.

Blast radius still sets severity: anything that can destroy or expose data
outside the directory the harness owns is P0 regardless of how it is reached.

## Fixtures are the harness's own test corpus

`fixtures/` holds a deliberately broken app whose defects are the calibration
negative controls, plus a curated clean app as positive control.

**Never put an answer marker in the served HTML.** No `data-seeded-defect`
attributes, no comments naming a defect, no control IDs. The registry lives in
`fixtures/controls.tsv` outside the served directories, and `probe.sh` greps the
source — an explorer can read the DOM, so a marker there is an answer key handed
to the thing being measured. A test asserts this; do not work around it.

Editing a fixture page breaks its control. Run `fixtures/probe.sh` after any
change: a MISSING row means a seeded defect was edited away and the calibration
denominator is stale.

## Claims discipline

This repo makes claims about tools and about itself. Both must be earned:

- A measured tool behavior carries its version and date (see the adapter's
  console-buffer table). Version-less measurements are guesses.
- A metric without a threshold is decoration; a metric without a denominator is
  not a pass.
- Never widen what the harness claims. It does not measure users, produce
  population statistics, or replace human research — `docs/persona-simulation.md`
  says why, and that boundary is load-bearing.
