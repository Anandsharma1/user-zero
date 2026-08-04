# Prior art: what exists publicly, and why this repo still exists

Surveyed 2026-08-03. Anyone considering this harness should know what they
could use instead, and the honest answer is: **a lot of the knowledge, almost
none of the harness.**

## The landscape

| Bucket | Examples | Drives a real browser? | Persona / charter? | Calibrated? | Overlap here |
|---|---|---|---|---|---|
| **Static heuristic rubrics** — review code, screenshots, or descriptions | [glebis/claude-skills](https://github.com/glebis/claude-skills) (337★, MIT, `nielsen-heuristics`) · [tommyjepsen/awesome-ux-skills](https://github.com/tommyjepsen/awesome-ux-skills) (125★, no licence — `ux-heuristics-review`, `dieter-rams-principles`, `craft`, `cognitive-load-conversion`) · [mastepanoski/claude-skills](https://github.com/mastepanoski/claude-skills) (44★, MIT — separate Nielsen / Norman / WCAG / cognitive-walkthrough skills) · [phazurlabs/ux-ui-mastery](https://github.com/phazurlabs/ux-ui-mastery) (34★, Apache-2.0, 19 skills, ~310k words) · [wondelai/skills](https://github.com/wondelai/skills) · [bitjaru/styleseed](https://github.com/bitjaru/styleseed) | No | No | No | **High** — this is our spine + lenses |
| **Live-browser design review** | [OneRedOak/claude-code-workflows `design-review`](https://github.com/OneRedOak/claude-code-workflows/tree/main/design-review) — Playwright MCP, Stripe/Airbnb/Linear-style principles, phased pass (interaction → responsiveness → polish → a11y → robustness → code health) | Yes | No — diff-triggered, not journey-driven | No | Medium — closest public thing to a harness |
| **Persona-simulated usability research** | [UXAgent](https://github.com/neuhai/UXAgent) · UXCascade · PerceptUI · UXBench — see [persona-simulation.md](persona-simulation.md) | Yes | Yes — up to thousands of generated personas | Partly (UXBench benchmarks judges) | Medium — same core, different goal |
| **Goal-driven browser agents / autonomous E2E** | browser-use · Skyvern · Agent-E · Anthropic's [`webapp-testing`](https://github.com/anthropics/skills/blob/main/skills/webapp-testing/SKILL.md) skill | Yes | No | No | Low — drivers, not evaluators |

## The "community will outpace you" argument, checked

It is the right instinct and it does not survive the numbers:

| Repo | Stars | Licence | Total commits | Age at survey |
|---|---|---|---|---|
| glebis/claude-skills | 337 | MIT | 100+ | 9 months |
| tommyjepsen/awesome-ux-skills | 125 | **none** | 18 | 3 months |
| mastepanoski/claude-skills | 44 | MIT | 32 | 6 months |
| phazurlabs/ux-ui-mastery | 34 | Apache-2.0 | **7** | 6 months |

These are one-to-three-person markdown repos. glebis' 100+ commits span fonts,
presentations, and image search; its `nielsen-heuristics` skill is one file.

More decisive than the commit counts: **the content is canon that stopped
moving.** Nielsen's heuristics are from 1994, Norman's principles from 1988,
Gestalt from the 1920s, ISO 9241-110 last revised 2020. There is no upstream
improvement stream to ride, so upstream churn is mostly rewording. That is why
`lenses/MANIFEST.md` pins each catalog and schedules a *quarterly 30-minute
diff* rather than a dependency.

Where "community moves faster" genuinely is true is one layer down — browser
drivers. Which is why this repo does not have one: the adapter binds Microsoft's
Playwright MCP and can be repointed without touching a charter.

## What is actually ours

None of the surveyed projects has any of these, and they are the parts that
took judgment rather than transcription:

1. **The Pass A / Pass B contamination boundary** — fresh eyes first, hashed,
   then oracles. Comprehension judgment is only meaningful from someone who
   does not yet know the answer, and each surface affords exactly one such
   someone. Nothing public models this.
2. **Charter + profile schemas** — a testing *mission* with a persona and a
   north-star question, rather than "review this diff".
3. **The evidence contract** — a screenshot per claim, cross-layer evidence for
   data claims, fresh-context reproduction before a defect is dispositioned.
4. **The calibration protocol** — armed controls, predeclared denominators,
   blind operators, seven thresholded metrics, and `not measurable` as a
   distinct outcome. The public skills stop at a 0–4 severity scale and never
   measure their own false-positive rate. (UXBench is the one external project
   that takes this seriously — for benchmarking models, not for calibrating an
   installed harness.)
5. **The learning loop** — confirmed defects pinned as regressions and captured
   as RCA, so a finding cannot recur silently.
6. **Single-source dual-platform dispatch** — one canonical skill, generated
   stubs, drift blocked at commit time, so Claude Code and Codex cannot run
   different evaluators.
7. **The accumulated calibration corpus** — findings, tier reviews, and
   false-positive corrections against *your* product. Nothing external can hand
   you this, and no amount of upstream evolution substitutes for it. It is the
   only asset here that compounds.

## What was taken from the survey

Deliberately: **the lens list, not the lens text.** The catalogs above were
read to decide which lenses were worth having and to check nothing obvious was
missing; every lens in `lenses/` is originally authored for this harness. That
keeps the repo single-licensed (one surveyed catalog has no licence at all, so
its text could not be vendored regardless) and keeps each lens tied to this
harness's own evidence rules.

Cross-checked but not copied: OneRedOak's phase mechanics, against
`references/browser-driver-contract.md`.

## Honest summary

Had this survey happened before the harness was built, the sensible start would
have been one of the Nielsen skills. Given the harness exists, the taxonomy is
the replaceable 20% and the harness is the 80% nothing public offers — so the
correct move was a half-day gap-diff, not a migration. That gap-diff is what
produced `lenses/` and the four ideas listed under "considered and deliberately
not lenses" in the manifest.
