# Adapter: Claude in Chrome (browser extension)

Binds the browser-driver contract to Anthropic's Claude-in-Chrome extension —
Claude driving a **real Chrome**, vision-first, rather than a Playwright-managed
Chromium.

## Honest status

**Measured on 2026-08-04 against extension version 1.0.84** — the first-use
checklist at the bottom was run end to end against the shipped fixtures, and
every row below now carries a result instead of a guess. Read those results
before trusting a capability: one is worse than the old guess (network gives
metadata only), one is better (a structured accessibility tree does exist), and
one is conditional in a way no guess would have caught — resizing works, but
only on an unmaximized window, and it clamps at a viewport far wider than a
phone.

The extension auto-updates and its tool surface varies by version, so this
measurement is pinned to 1.0.84. On any other version the rows revert to
unverified until the checklist is re-run.

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
| `--cross-check` on a Playwright glance | **its sharpest role** — re-judging contrast/legibility/compositing findings in the renderer users actually run |
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
   Add, skip sign-in, name it e.g. `user-zero QA`). No logins, no extensions
   beyond Claude's, no browsing.
2. Run all glance/charter work in that profile only.
3. Between runs, clear its site data (Settings → Privacy → Clear browsing
   data → all time), or delete and recreate the profile.
4. **Leave the window unmaximized.** Measured on 1.0.84: `resize_window` is
   silently inert on a maximized window while still reporting success, so a
   maximized QA window costs you viewport control without telling you.
5. Record in the run's debrief: `browser: claude-chrome, dedicated profile,
   state cleared at <time>`.

### How the profile is actually selected (you do not pass an identifier)

There is no profile parameter to hand the agent. Profile selection happens
before the agent exists, through two properties of Chrome itself:

- **Extensions are installed per profile.** An extension in your daily profile
  does not exist in the QA profile, and vice versa. So the single most
  effective control is: **install the Claude extension ONLY in the QA
  profile** (or remove/disable it in your daily one). Then pairing *cannot*
  land anywhere else — the default behavior you observed, where Chrome opens
  with the last-used profile and the extension "takes" it, becomes harmless
  because that profile has no extension to take.
- **A window belongs to a profile.** Launch the QA profile deliberately: pick
  it from Chrome's profile switcher, or start it directly —
  `google-chrome --profile-directory="Profile 2"` (find the directory name at
  `chrome://version` → Profile Path, under the QA profile).

Measured on 1.0.84: the tool that lists paired browsers reports only a device
id, a display name, an OS and a connection time — **no profile name, no profile
path**. So the display name is the only handle you get, and it is worth
setting: pairing via `switch_browser` broadcasts a prompt to every profile that
has the extension and lets you *name* the window you accept it in. Name the QA
one (e.g. `user-zero QA`) once and later sessions can at least ask for it by
name. Declining the prompt in the other profiles works but is per-request; it
does not persist, and it does not unpair an already-connected browser.

Then pair Claude Code with that running window. Two hygiene rules and a check:

- Close your daily-profile Chrome windows while pairing, so there is no
  ambiguity about which instance the session connects to.
- **Verify before the first action, every session**: have the agent open a
  site you are normally logged into (your mail, GitHub). In the QA profile it
  must arrive logged out, with no autofill. Logged-in = wrong profile = stop.
  Record the check's screenshot as the run's first evidence item.

This makes isolation **operator-provided instead of tool-enforced**. That is a
real downgrade — a checklist someone can skip is weaker than a flag that cannot
be — which is exactly why state-mutating charters stay forbidden here: the cost
of a skipped step must be bounded at "contaminated opinions", never "mutated
real data".

## Capability mapping

Status column is as measured on 1.0.84 (2026-08-04); see the checklist results
for the evidence behind each row.

| Contract capability | Status | Notes |
|---|---|---|
| 1. Navigate & interact | **yes — real input** | `navigate` + `computer`. Clicks and keystrokes arrive as `isTrusted: true` browser-level input, not synthetic JS events, so handler behavior is genuine |
| 2. Accessibility tree | **yes, but lossy** | `read_page` returns a role+name tree with `ref` ids; `find` maps natural language to refs. But table rows/cells/headers all flatten to `generic`, and headings carry no level — row/column and heading-hierarchy claims must come from the screenshot, not the tree |
| 3. Screenshots | yes, downscaled above ~1568 px | its primary sense. A 1920×941 viewport returns a 1568×768 JPEG (~0.82); a 500×663 viewport returns 1:1. Use `zoom` before judging small-text legibility on a wide window |
| 4. Console access | **yes, per-domain accumulating** | catches load-time errors with file:line. The buffer is per-tab and per-**domain**, not per-page: it keeps another page's errors after you navigate. Always `clear: true` on arrival, and check each message's source URL |
| 5. Network access | **partial — metadata only** | url + method + statusCode. **No headers, no request/response bodies, no timing.** Enough to prove a request failed; never enough for payload evidence, so correctness questions needing response contents stay `needs_oracle` |
| 6. Viewport control | **conditional — and it lies when it fails** | Works only on an **unmaximized** window; on a maximized one it returns success and does nothing. Sets **outer** size, not viewport, and clamps at ~532 outer / **500 viewport** px wide, so a 390 px phone viewport is unreachable. Phone-width rows are `blocked: adapter clamps at 500px`. Never trust the success string; assert `innerWidth` |
| 7. Isolated state | **operator-provided** | dedicated profile + state clearing, above. Measured: no adapter tool clears profile state, and a brand-new tab is **not** new state |

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

Note on tool grants: the stub now **pins** the tool names measured on 1.0.84
rather than inheriting the session's tools. Two consequences worth knowing:

- If the extension renames a tool in a later version, the stub loses that
  capability *visibly* (the tool is absent) rather than silently inheriting a
  changed surface. Re-run the checklist and re-generate on a version bump.
- `javascript_tool` is deliberately **excluded** from the grant. It exists and
  works, and this checklist used it for probing — but handing it to the
  explorer would hand it the DOM and page internals, which the persona's hard
  rules forbid ("you report what you observed, not what you infer the code
  does"). Adapter probing is not an explorer run; keep the capability out of
  the explorer's hands. `file_upload`, `upload_image`, `gif_creator` and
  `shortcuts_*` are excluded as outside the contract.

## Concurrency

One browser, one screen, one explorer. No parallel exploration of any kind
through this adapter — including cohort personas, which run strictly serially
with a full state clear between them.

The same applies to the **operator**: while a run is live, the QA window is the
explorer's. Clicking, typing, scrolling, or switching tabs in it mid-run
injects your input into its evidence — screenshots that show states the
explorer never produced, console entries from pages it never visited. Watch,
don't touch; if you must intervene, stop the run and say so in the debrief.

## First-use checklist (do once per extension version, record results here)

This probes the **adapter**, not any product — it is product-independent and its
results hold for every repo the harness is installed into. Run it **in the
harness repo** (fixtures are not installed into products) against the shipped
fixture apps (`fixtures/serve.sh`), so every answer is checkable. It is not a
calibration and needs no blindness: the one control it references (KD-C01) is
already disclosed in the fixtures' own profile. Just don't read
`fixtures/controls.tsv` in a session that might later run a fixture calibration.

- [x] Which profile is paired? Open a normally-logged-in site — it must arrive
      logged out. Screenshot it.
- [x] List the browser tools the session actually exposes; record their names
      and the extension version.
- [x] Capability 2: can it return a structured element tree, or only vision?
- [x] Capability 4: open `broken-app/index.html` — control KD-C01 logs a console
      error on load. Can the adapter surface it? If yes, is the buffer scoped to
      this page or does it accumulate?
- [x] Capability 5: can it show the failed telemetry request at all?
- [x] Capability 6: can it set 390×844? Does the page actually reflow?
- [x] Isolation: after clearing site data, does a revisited page arrive truly
      cold (no cookies, no localStorage)?
- [x] Record everything above in this file with the date and version, and
      update the generated stub's tool grant via the generator.

## Checklist results — 2026-08-04, extension 1.0.84

Environment: Chrome on Linux (X11/GNOME), screen 1920×1080, `devicePixelRatio`
1, viewport 1920×941. Extension id `fcoeoabgfenejglbffodgkkbkcdhcgfn`,
version 1.0.84 (read from the on-disk manifest — the tool surface does not
report its own version). Fixtures served at `http://127.0.0.1:8801` by
`fixtures/serve.sh`. `controls.tsv` was not read.

**Tool surface (22 tools, all `mcp__claude-in-chrome__*`).** `browser_batch`,
`computer`, `file_upload`, `find`, `form_input`, `get_page_text`,
`gif_creator`, `javascript_tool`, `list_connected_browsers`, `navigate`,
`read_console_messages`, `read_network_requests`, `read_page`, `resize_window`,
`select_browser`, `shortcuts_execute`, `shortcuts_list`, `switch_browser`,
`tabs_close_mcp`, `tabs_context_mcp`, `tabs_create_mcp`, `upload_image`.

**1. Which profile is paired — PASS, with a caveat that weakens the mitigation.**
Two browsers were connected. `list_connected_browsers` reports only `deviceId`,
`name`, `osPlatform`, `connectedAt`, `isLocal` — **no profile name and no
profile path**, so the paired profile cannot be identified from the tool
surface at all. Selected `f7e7dcbe-9573-4871-b9b3-7da22a946091` ("Browser 1")
and loaded `github.com`: it arrived signed out ("Sign in" / "Sign up"), no
autofill.

Note what that check does and does not establish. Signed-out proves the profile
is *not a logged-in daily one*; it does not prove *which* profile it is, and any
unused profile would pass it too. Identification needed a second, out-of-band
signal: the fixture origin appeared in the browsing history of the QA profile's
directory and in no other profile carrying the extension. Treat the logged-out
check as a necessary gate, not an identification.

Two things this exposed:

- Screenshots are **viewport-only**, so Chrome's profile avatar is not in the
  frame. The logged-out check is not merely the recommended identification —
  it is the *only* in-band one.
- On this machine the Claude extension is installed in **three** profiles
  (`Profile 1`, `Profile 2`, `Profile 8`). The "install it only in the QA
  profile" mitigation above is therefore **not currently satisfied**, and
  pairing can land in a daily profile. Naming a browser via `switch_browser`
  makes it recognizable in later sessions; removing the extension from the
  non-QA profiles is the actual fix.
- **Renaming Chrome profiles does not help.** A profile has two names: the
  display name (freely editable, cosmetic) and the on-disk directory
  (`Profile 8`), which is the key Chrome stores in `Local State` →
  `profile.info_cache` and the value `--profile-directory` takes — renaming that
  folder makes Chrome forget the profile. Neither name reaches the agent, since
  the browser-list tool reports neither. Only the extension-side browser name
  does.

**2. Capability 2, structured tree — PASS, better than the old guess.**
`read_page` is a genuine role+name accessibility tree with stable `ref` ids,
`href` values, `filter=interactive|all`, `depth`/`max_chars`, and a trailing
`Viewport: WxH`. `find` resolves natural language ("Batches navigation tab") to
a single ref. The vision-first framing above understated this: role+name
navigation is available here, not just pixels.

Two real limits:

- **The tree is lossy on structure.** Every row, cell and column header of the
  fixture table came back as a flat run of `generic` nodes under `table`, and
  headings arrive as `heading` with no level. "This value sits under the wrong
  column" and "the heading order skips a level" cannot be sourced from this
  tree — read them off the screenshot.
- **The extension's own UI is in the tree**: `"Claude is active in this tab
  group"`, `Open chat`, `Dismiss`. That is adapter chrome, not product UI, and
  must never become a finding.

**3. Capability 4, console — PASS, and the scoping answer matters.**
KD-C01's load-time error surfaced immediately, with source and position:
`[ERROR] (…/broken-app/index.html:153:24) reconciliation telemetry
unavailable: telemetry 404`.

Buffer semantics, measured:

- **Per-tab, and per-domain — not per-page.** After navigating to
  `clean-app/index.html`, the buffer still returned both `broken-app` errors.
  Since both fixture apps share one origin, an evaluator reading the console
  while standing on the **positive control** would see the broken app's error.
  That is a false-positive generator; the class of mistake calibration exists
  to catch.
- **It accumulates across reloads** — one entry per load, two after two loads.
- `clear: true` returns the messages and empties the buffer (verified: the next
  read was empty).
- **Tracking arms on first call per tab.** Messages logged before the first
  `read_console_messages` on that tab are lost, so load-time errors need a
  reload after arming.

Working rule: `clear: true` on every arrival, and check each message's source
URL before attributing it to the page you are on.

**4. Capability 5, network — PARTIAL. Better than "assume unavailable", worse
than useful for payload evidence.** After a reload the failed telemetry request
was visible: `GET http://127.0.0.1:8801/api/reconciliation/telemetry` →
`404`. But the tool returns **only url, method and statusCode** — no headers,
no request or response bodies, no timing. So it proves *that* a request failed
and can substantiate a console-error finding; it can never substantiate a
claim about *what a response contained*. Correctness questions needing payload
proof remain `needs_oracle` through this adapter, exactly as the table says.
Same buffer semantics as console: per-tab, arms on first call (so a reload is
needed to catch page-load requests), accumulates across pages within the
origin, `clear: true` works.

**5. Capability 6, viewport — CONDITIONAL. Window state decides it, and the
failure is silent.**

*Maximized window (first pass).* `resize_window` to 390×844 returned
`Successfully resized window containing tab … to 390x844 pixels` and nothing
changed: `innerWidth` 1920, `innerHeight` 941, `outerWidth` 1920, `outerHeight`
1080, `scrollWidth` 1920, no reflow. Repeated at 800×600 — same success string,
same unchanged 1920×941. **A reported success with no effect is worse than a
missing capability**, because it will be believed.

*Unmaximized window (second pass, same tool, same version).* The window was
restored down by hand (baseline `outerWidth` 1749, `outerHeight` 990) and
resizing then worked, with two limits:

| Requested | Resulting outer | Resulting viewport |
|---|---|---|
| 390 × 844 | 532 × 844 | **500 × 663** |
| 300 × 800 | 532 × 800 | **500 × 619** |
| 768 × 844 | 768 × 844 | 736 × 663 |

- **It sets the outer window, not the viewport.** Chrome's frame costs 32 px of
  width and ~181 px of height, so a target viewport needs those added back.
- **Width clamps at ~532 outer / 500 viewport.** 390 and 300 both landed on the
  same 500 px viewport, so this is a floor, not a rounding. Height is honored
  exactly. **A 390 px phone viewport is therefore unreachable through this
  adapter** — the narrowest honest viewport is 500 px.

The page did genuinely reflow at 500 px (the fixture's three summary cards
restacked to 2 + 1), so what the capability delivers is real responsive
rendering, just not phone width. Screenshots at that size come back 1:1
(500×663), so the ~0.82 downscale noted below is a large-viewport cap rather
than a constant.

So the maximized-window failure is now measurement, not hypothesis: same tool
and version, inert when maximized, working when not.

Working rules: **unmaximize the QA window before any run that judges layout**;
treat phone-width rows as `blocked: adapter clamps at 500px`, never silently
skipped; add Chrome's 32/181 px frame to any target viewport; and never trust
the return string — assert `innerWidth` after every resize.

**6. Isolation — confirmed operator-provided, with no tool-side help.**
The origin arrived cold (`Object.keys(localStorage)` empty before the probe).
Set `localStorage.uz_probe` plus a `uz_probe` cookie, then opened a **brand-new
tab** via `tabs_create_mcp` on the same URL: both came back intact. **A new tab
is not new state.** No tool in the surface clears profile state. The only
in-session clear is page-scoped JS (`localStorage.clear()` plus cookie
expiry — verified effective for that origin), which does not touch other
origins, HttpOnly cookies, IndexedDB, service workers, or the HTTP cache. So
clearing between runs stays a manual Chrome-Settings step, as required above.

### Two further measurements worth carrying

- **Input is real.** A capture-phase listener recorded `isTrusted: true` for
  the click and for all 18 keystrokes of a typed string, and a click issued at
  screenshot coordinates (1463, 19) landed at page coordinates (1791, 23) —
  correct scaling of the ~0.82 downscale. Coordinates are screenshot-space and
  are mapped for you; interaction fidelity is genuinely higher than dispatching
  synthetic events.
- **Screenshot scale is not constant.** 1:1 at a 500 px viewport, ~0.82 at
  1920 px — the JPEG appears capped near 1568 px wide. Do not assume a fixed
  factor when converting between screenshot and page coordinates; the tool maps
  clicks for you, so prefer refs or screenshot-space coordinates over arithmetic.
- **The server access log is not an oracle for navigation.** Reloads and
  same-URL clicks were served from Chrome's cache with no server hit, so an
  absent log line does not mean a click failed to navigate. Verify navigation
  from the page itself, not from the fixture server's log.

Runs on extension 1.0.84 may state `adapter: claude-chrome (capabilities
measured 2026-08-04, v1.0.84)`. On any other version, revert to
`adapter: claude-chrome (capabilities unverified)` until this checklist is
re-run.
