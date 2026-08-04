# Browser Driver Contract

The ui-qa core is tool-agnostic. Any browser adapter must provide these
capabilities; the profile names which adapter binds them for the project.
Charters and profiles describe intent in these abstract terms only — concrete
tool commands live exclusively in the adapter file.

## Required capabilities

1. **Navigate and interact** — open URLs, click, type, select, upload files,
   handle dialogs, use keyboard (Tab/Enter/Escape traversal must be possible
   for accessibility checks).
2. **Accessibility-tree inspection** — a structured snapshot of the rendered
   page (roles, names, states) sufficient to locate elements by role+name
   without pixel coordinates or CSS selectors.
3. **Screenshots** — full-page and viewport captures, savable to the run's
   evidence directory.
4. **Console access** — read browser console messages emitted during the
   session, with severity. The buffer MUST be scoped to the run under
   observation: a console read that can return a message emitted by an earlier
   run's stack manufactures phantom findings, and a *fresh profile* does not by
   itself give you this (profile isolation is about cookies and storage, not
   about the message buffer's lifetime). Where the tool cannot guarantee it,
   the adapter says so and states the remedy.
5. **Network access** — observe requests/responses issued by the page (URL,
   method, status; response bodies where the tool allows).
6. **Viewport control** — set the viewport to each size the charter declares.
7. **Isolated browser state** — start a session with a fresh profile
   (no cookies, storage, or cache carried over), and persist state within a
   run when a journey requires it.

## Optional capabilities

Not required, because most adapters lack them — but their absence bounds what
the harness can evidence, so an adapter must state which it has.

8. **Recording / trace** — a video or interaction trace of a journey segment.
   This is the only honest evidence for **temporal** claims: jank, feedback
   delay, focus loss on transition, layout shift under the cursor, a success
   animation that fires before the response resolves. Screenshots cannot
   establish any of them.
9. **Timing anchors** — the ability to relate an observed change to a concrete
   event (a network request completing, a DOM state appearing), so a duration
   claim rests on something measurable rather than on perception.

**Degrade honestly.** Without capability 8, temporal findings are reported as
before/after stills plus a described sequence, marked **needs video
verification**, with any duration marked approximate unless anchored per
capability 9. Reporting a perceived duration as measured is the failure mode
here; dropping the finding is the other one. Do neither.

## Adapter obligations

- Pin the tool version; never float on `latest`.
- Document known sensing caveats (e.g. whether the accessibility snapshot
  includes off-screen elements) so explorers don't act on unreachable UI.
- Document the reconnaissance-then-act pattern for the tool: wait for the
  page to settle, snapshot, identify targets from what actually rendered,
  then act; on a blocked interaction, re-snapshot and re-orient.
- State how each of the seven required capabilities maps to concrete tool
  calls, and which (if any) are unavailable so the runner can degrade honestly.
- State whether the optional capabilities (recording, timing anchors) exist,
  because that determines whether temporal findings can be evidenced at all.
- State the redaction obligation for whatever network access it provides:
  which calls can return credentials, and the narrowest call that still proves
  a payload claim.

## Choosing / swapping adapters

Adapters are interchangeable by design. If the bound adapter proves
token-heavy or unreliable, add a new adapter file and repoint the profile —
no charter or profile oracle text should need to change.

**A word on real-browser drivers** (e.g. a Chrome extension driving the
operator's everyday browser, such as Claude's): the contract does not forbid
one, but capability 7 — isolated browser state — is exactly what such a driver
cannot provide. The operator's browser carries their cookies, logins, history
and extensions, which (a) contaminates Pass A: a "first-time user" who arrives
already logged in with warm state is not a first-time user; (b) makes
console/network evidence unattributable — other tabs and extensions emit into
the same session; and (c) points state-mutating journeys at whatever real
accounts that browser is signed into. An adapter over such a driver must
declare capability 7 unavailable, which limits it to `glance` on
observation-only surfaces at most. The default adapter is Playwright MCP with
`--isolated` precisely because of this.
