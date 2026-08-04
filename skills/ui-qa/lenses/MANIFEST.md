# Lens Registry

The spine (`../references/ux-evaluation-taxonomy.md`) is what every evaluator
always carries. A **lens** is an optional pack for a concern only some
products have. Charters select lenses by name (`charter-schema.md`
§Lens selection); the evaluator reads the selected files before its first
screen.

## Why lenses instead of one big taxonomy

Three reasons, in order of importance:

1. **Context budget.** Fresh-eyes exploration only works if the evaluator's
   expertise fits alongside the mission packet with room left to think. A
   300k-word design compendium cannot be loaded, so a compendium is not a
   usable evaluator — it is a library. The spine is deliberately condensed;
   lenses buy depth only where a specific product needs it.
2. **Precision of attention.** A lens invites findings in its territory. Load
   a motion lens onto a static reporting table and you will get motion
   findings — that is the failure mode, not a bonus. Selecting lenses per
   charter is how the harness keeps attention proportional to the surface.
3. **Reviewability.** One file per concern means a lens can be added,
   measured, and removed on its own evidence.

## Why lenses are not separate skills

Public UX-review skills each emit their own report. Invoking five of them
yields five overlapping reports, five severity vocabularies, no persona, and
no screenshot-per-claim discipline — and the merge cost lands on a human.

Here, lenses are **reference material read by one evaluator**. One finding
stream, one severity model, one evidence contract. Lenses widen what the
evaluator looks for; they never multiply the reports.

## Registry

| Lens | Load when the surface… | Adds |
|---|---|---|
| `ai-product-ux` | contains model-generated output, chat, agents, recommendations, or confidence-bearing predictions | provenance, confidence honesty, steerability, correction paths, streaming states, automation-boundary clarity |
| `simplicity-and-restraint` | has grown by accretion, or a redesign is being judged | subtractive critique: what should not be here at all |
| `persuasion-and-dark-patterns` | asks for money, consent, personal data, or a commitment | pressure tactics, asymmetric choice, consent honesty, deceptive defaults |
| `localization-and-locale` | ships in more than one language/region, or renders locale-formatted data | expansion, RTL, name/address/number/currency/timezone honesty |
| `touch-and-mobile` | is used on phones or tablets, or declares a small viewport | thumb reach, gesture discoverability, native-convention conformance, interruption tolerance |
| `motion-and-timing` | animates, transitions, streams, polls, or has perceptible latency | duration budgets, purpose of each animation, latency honesty, reduced-motion |
| `forms-and-validation` | collects input of consequence, or has a multi-step flow | validation timing, error summaries and focus movement, preservation of work, partial-success honesty |
| `data-visualization` | renders charts, gauges, sparklines, or maps | scale integrity, missing-vs-zero, denominators and uncertainty, encoding choice, non-visual alternatives |
| `resilience-and-continuity` | holds a session, unsaved work, long operations, or concurrently-editable data | expiry, offline and optimistic-update rollback, interruption, staleness and conflicts, degradation honesty |
| `accessibility-dynamic` | makes an a11y claim beyond the spine's floor, or has overlays, live regions, drag, or auth | focus over time, announcement of change, 200%/400% zoom and reflow, pointer alternatives, accessible authentication |

## Provenance

Every lens in this directory is **originally authored for this harness**. The
public catalogs below were surveyed to decide *which* lenses were worth
having and to check nothing obvious was missing; no upstream text was copied.
That keeps the repo free of mixed licensing (one surveyed catalog has no
licence at all, so its text could not be vendored even if we wanted to) and
keeps every lens in the harness's own voice, tied to its own evidence rules.

Pins are recorded so the gap-diff below compares against a known state, not
a moving target.

| Catalog | Licence | Pinned at survey | Used for |
|---|---|---|---|
| [mastepanoski/claude-skills](https://github.com/mastepanoski/claude-skills) | MIT | `fbdde8adb564` (2026-06-05) | per-framework audit granularity (Nielsen / Norman / cognitive walkthrough as separable units) |
| [phazurlabs/ux-ui-mastery](https://github.com/phazurlabs/ux-ui-mastery) | Apache-2.0 | `11389c827c31` (2026-08-01) | breadth check: i18n, mobile, motion, performance-state, agentic-UX domains |
| [tommyjepsen/awesome-ux-skills](https://github.com/tommyjepsen/awesome-ux-skills) | **none — do not copy text** | `6992218a492b` (2026-07-28) | lens naming for AI-product surfaces; Rams and Fogg as distinct lenses |
| [OneRedOak/claude-code-workflows](https://github.com/OneRedOak/claude-code-workflows) | see repo | `6a653445125d` (2025-09-14) | live-browser review phase mechanics — cross-checked against `browser-driver-contract.md` |

## Considered and deliberately not lenses

Recording these matters as much as the registry — they are the ideas most
likely to be re-proposed:

- **Outcome metrics frameworks (HEART, SUS, task-success dashboards).** These
  plan and analyse a research programme; they do not tell an explorer what to
  look at on a screen. The explorer's observable proxies (click counts,
  completion, self-reported difficulty) already live in the spine §11 and in
  the exit interview.
- **Structured critique protocols (e.g. Liz Lerman's Critical Response
  Process).** Designed for a facilitated conversation between a maker and
  responders. The harness has no maker in the room; its equivalent discipline
  is the finding-quality contract plus the actionability metric.
- **Design-token / component-library conformance.** That is a code review
  against a design system, and it needs source access — which Pass A must not
  have. Belongs in the project's code-review lane, not in the explorer.
- **Visual-regression diffing.** Deterministic tooling does this better than
  judgment does. The explorer's screenshots are evidence for human claims,
  not a baseline suite.

## Adding a lens

1. One concern per file, in the spine's voice: concrete questions an
   evaluator asks *on a rendered screen*, not principles to admire.
2. Every question must be answerable from the UI alone, without source
   access — otherwise it is a Pass-B oracle, not a lens.
3. Add a registry row with an honest "load when" trigger. If you cannot write
   a trigger that excludes most surfaces, it belongs in the spine instead.
4. Its first two charter runs are calibration runs
   (`../references/calibration-protocol.md` §Lenses are calibrated too).
   Record the outcome here.

## Refresh ritual (quarterly, ~30 minutes)

The pins exist so this is a diff, not a re-read:

```bash
# for each catalog above
survey="$(mktemp -d)"
git clone --filter=blob:none <url> "$survey" && cd "$survey"
git log --oneline <pinned-sha>..HEAD -- '*.md'
```

Read only what changed. Ask one question: *does this name a concern our spine
and lenses cannot express?* Usually the answer is no — Nielsen (1994), Norman
(1988), Gestalt (1920s) and ISO 9241-110 (2020) are not moving, so upstream
churn is mostly re-wording. When the answer is yes, write a new lens in our
own voice and bump the pin. Bump the pin either way, with a one-line note, so
the next refresh has a real baseline.

| Refreshed | By | Pins bumped | Outcome |
|---|---|---|---|
| 2026-08-03 | initial survey | all | 6 lenses authored; 4 ideas rejected above |
| 2026-08-03 | multi-reviewer audit of this repo | — | 4 lenses added (`forms-and-validation`, `data-visualization`, `resilience-and-continuity`, `accessibility-dynamic`) — gaps found by review, not by upstream drift, which is the expected source of new lenses once the pins are current |

**None of these ten lenses has been exercised against a real product.** Per
§Lenses are calibrated too in the calibration protocol, the first two runs of
any charter that names one are calibration runs. See `docs/known-limitations.md`
in the harness repo for the full maturity position.
