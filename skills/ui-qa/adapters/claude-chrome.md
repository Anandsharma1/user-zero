# Adapter: Claude in Chrome (browser extension)

Binds the browser-driver contract to Anthropic's Claude-in-Chrome extension —
Claude driving a **real Chrome**, vision-first, rather than a Playwright-managed
Chromium.

## Honest status

This adapter is **capability-declared, not capability-measured**. The extension
auto-updates and its tool surface varies by version, so unlike the Playwright
adapter — whose console-buffer and network behaviors were probed on a pinned
version and recorded — nothing here carries a measurement. Per repo policy
(version-less measurements are guesses), every unverified row below says so,
and the first-use checklist at the bottom is how it stops being unverified.

## When this adapter is the right choice

What actually differs from Playwright MCP is **sensing, not judgment** — the
evaluator's judgment is the model's and is identical through any adapter. The
extension senses through real Chrome:

- real fonts, GPU compositing, real device pixel ratio, real extensions-era
  rendering quirks — closer to what a user's eye receives than headless
  Chromium;
- vision-first interaction: the model works from rendered pixels as its primary
  sense, which can be stronger on canvas-heavy, WebGL, or heavily animated
  surfaces where an accessibility snapshot is thin;
- whatever Chrome-only behavior your product has.

What Playwright gives up in visual fidelity it repays in evidence machinery:
structured a11y snapshots (role+name navigation — a strength, not a fallback),
scoped console capture, full network request/response access for cross-layer
evidence, viewport control, and `--isolated` fresh profiles. Those are the
capabilities that make **charter** evidence trustworthy.

So the honest division of labor:

| Use | Adapter |
|---|---|
| `glance` — expert look, opinions with screenshots | **claude-chrome is a good fit** |
| observation-only charters | possible with the mitigations below, degraded evidence declared |
| state-mutating charters | **never through this adapter** |
| calibration runs | no — calibration measures the evaluator through the adapter it will actually use; mixed-adapter scores are not comparable |

## The isolation problem, and the required mitigation

Capability 7 (isolated browser state) is what a real-browser driver cannot
provide by itself: your everyday Chrome carries logins, cookies, history, and
other tabs. That contaminates the fresh-eyes persona, pollutes console/network
evidence with other tabs' noise, and points any mutation at real accounts.

**Required mitigation — a dedicated QA Chrome profile:**

1. Create a Chrome profile used for nothing else (Chrome → profile switcher →
   Add). No logins, no extensions beyond Claude's, no browsing.
2. Run all glance/charter work in that profile only.
3. Between runs, clear its site data (Settings → Privacy → Clear browsing
   data → all time), or delete and recreate the profile.
4. Record in the run's debrief: `browser: claude-chrome, dedicated profile,
   state cleared at <time>`.

This makes isolation **operator-provided instead of tool-enforced**. That is a
real downgrade — a checklist someone can skip is weaker than a flag that cannot
be — which is exactly why state-mutating charters stay forbidden here: the cost
of a skipped step must be bounded at "contaminated opinions", never "mutated
real data".

## Capability mapping

| Contract capability | Status | Notes |
|---|---|---|
| 1. Navigate & interact | expected | click/type/navigate are the extension's core |
| 2. Accessibility tree | **verify** | the extension is vision-first; whether a structured role+name snapshot is exposed varies. If unavailable, the explorer navigates visually and says so — element-reachability claims weaken |
| 3. Screenshots | yes | its primary sense |
| 4. Console access | **verify** | if unavailable, console-error findings are out of reach for this adapter — declare it in every report |
| 5. Network access | **verify — assume unavailable** | without it there is no cross-layer payload evidence; correctness questions become `needs_oracle` even in charter mode |
| 6. Viewport control | **verify** | a real window may not resize to declared viewports; if not, mobile-viewport rows are `blocked: adapter cannot resize`, never silently skipped |
| 7. Isolated state | **operator-provided** | dedicated profile + state clearing, above |

Recon pattern is unchanged: wait for settle, look, identify targets from what
actually rendered, act; on a blocked interaction, re-look and re-orient — never
retry blind.

## Setup

The extension pairs with Claude Code per Anthropic's current instructions
(claude.ai/chrome). Mechanics change between releases, so this file
deliberately does not transcribe them. What matters for the harness:

1. Install the extension **into the dedicated QA profile**, not your daily one.
2. Start a session and **verify the browser tools are actually present** —
   a config or an installed extension is not evidence the tools loaded.
3. Complete the first-use checklist below before the first run you intend to
   keep.

Note on tool grants: the generated `user-zero` agent stub cannot pin this
adapter's tool names (they vary by extension version), so under
`--adapter claude-chrome` the stub inherits the session's tools instead of
naming them. Tighten it after the checklist records the real names.

## Concurrency

One browser, one screen, one explorer. No parallel exploration of any kind
through this adapter — including cohort personas, which run strictly serially
with a full state clear between them.

## First-use checklist (do once per extension version, record results here)

This probes the **adapter**, not any product — it is product-independent and its
results hold for every repo the harness is installed into. Run it **in the
harness repo** (fixtures are not installed into products) against the shipped
fixture apps (`fixtures/serve.sh`), so every answer is checkable. It is not a
calibration and needs no blindness: the one control it references (KD-C01) is
already disclosed in the fixtures' own profile. Just don't read
`fixtures/controls.tsv` in a session that might later run a fixture calibration.

- [ ] List the browser tools the session actually exposes; record their names
      and the extension version.
- [ ] Capability 2: can it return a structured element tree, or only vision?
- [ ] Capability 4: open `broken-app/index.html` — control KD-C01 logs a console
      error on load. Can the adapter surface it? If yes, is the buffer scoped to
      this page or does it accumulate?
- [ ] Capability 5: can it show the failed telemetry request at all?
- [ ] Capability 6: can it set 390×844? Does the page actually reflow?
- [ ] Isolation: after clearing site data, does a revisited page arrive truly
      cold (no cookies, no localStorage)?
- [ ] Record everything above in this file with the date and version, and
      update the generated stub's tool grant via the generator.

Until this checklist is filled in, every run through this adapter should say
so: `adapter: claude-chrome (capabilities unverified)`.
