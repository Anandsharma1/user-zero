# Adapter: Playwright MCP

Binds the browser-driver contract to Microsoft's Playwright MCP server.

## Installation — per harness

**Claude Code** — project `.mcp.json` (repo root):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.0.78", "--isolated"]
    }
  }
}
```

**Codex** — `.mcp.json` is NOT read by Codex; register the server in Codex's
own config, which lives under `CODEX_HOME`. That is not necessarily
`~/.codex` — check the environment before assuming, because registering into
the wrong home produces a server that silently never loads. Prefer the CLI so
the right home is resolved:

```bash
echo "${CODEX_HOME:-$HOME/.codex}"        # confirm which home you are writing to
codex mcp add playwright -- npx -y @playwright/mcp@0.0.78 --isolated
codex mcp list                            # verify it actually registered
```

(equivalent `config.toml` entry: `[mcp_servers.playwright]` with
`command = "npx"`, `args = ["-y", "@playwright/mcp@0.0.78", "--isolated"]`)

- **Pinned** at `0.0.78` (2026-07). Bump deliberately; never `@latest`. The
  caveats measured below are version-specific — re-measure them when you bump.
- `--isolated` starts every session with a fresh browser profile — this is
  how the contract's "isolated browser state" capability is satisfied.
  In-run persistence (e.g. staying logged in across pages) works within the
  session; nothing carries over between sessions.
- MCP servers load at agent-session start; adding or changing the config
  requires a session restart (and, in Claude Code, user approval of the
  server) before the tools appear. Verify the tools are actually present
  before starting a run — do not assume from the config file.

## Concurrency

One MCP server connection provides **one** browser context. Subagents of a
session share that connection — two explorers driving it interleave and
corrupt each other's sessions. Therefore:

- **Browser exploration is serialized by default**, even for
  observation-only charters.
- Parallel observation-only charters (and parallel personas in a cohort run)
  are permitted ONLY when each explorer has a dedicated isolated server
  instance of its own; absent that provisioning, run serially.

## Capability mapping

| Contract capability | Playwright MCP tools |
|---|---|
| Navigate & interact | `browser_navigate`, `browser_click`, `browser_type`, `browser_select_option`, `browser_file_upload`, `browser_handle_dialog`, `browser_press_key`, `browser_navigate_back` |
| Accessibility tree | `browser_snapshot` (structured a11y snapshot with element refs — the primary sense) |
| Screenshots | `browser_take_screenshot` (element / viewport / `fullPage`) |
| Console | `browser_console_messages` |
| Network | `browser_network_requests` (numbered list; `filter` regexp, e.g. `"/api/.*"`) + `browser_network_request` (full headers AND body of one request by `index`, or a single `part`) |
| Viewport | `browser_resize` |
| Isolated state | `--isolated` flag (above) for profile state; `browser_close` ends the session and is **required at run teardown** — it, not the flag, is what stops console evidence bleeding into the next run (see caveats) |

## Tool caveats

- **Off-screen elements appear in snapshots.** The a11y snapshot includes
  elements outside the viewport; before asserting that something is
  user-reachable (or screenshotting it as evidence), scroll it into view.
  Do not "interact" with UI a real user cannot see.
- **Settle before sensing.** After navigation or an action that triggers
  loading, wait for the page to settle before snapshotting; a snapshot taken
  mid-load produces phantom findings about missing content. Prefer waiting
  for a concrete element/state over fixed sleeps.
- **Blocked clicks name the blocker.** When a click fails because an overlay
  covers the target, the error names the covering element — dismiss it,
  re-snapshot, retry. Never retry blind.
- **`browser_console_messages` accumulates across runs, and `--isolated` does
  NOT prevent it.** The flag gives a fresh *profile* per server session, but the
  server session outlives an individual charter run: consecutive runs in one
  agent session share it, so the buffer still holds messages emitted by the
  previous run's stack — potentially on a different port. Observed in practice:
  a run auditing one port read an error that originated from the prior run's
  stack on the adjacent port. The explorer traced the origin and dropped it,
  but a phantom console error is exactly the kind of finding that survives
  review unchallenged, and it scores against the harness.

  Measured on 0.0.78 (2026-07-31), because the remedy is worth knowing rather
  than guessing:

  | Act | Effect on the buffer |
  |---|---|
  | `browser_navigate` to another page | **does NOT clear it** — a `console.error` emitted before the navigation is still returned afterwards under `all: true` |
  | `browser_close` | **clears it** — 196 errors → 0, including under `all: true` |

  So: **end every run with `browser_close`.** That, not `--isolated` and not
  navigating away, is what resets the buffer. Then filter console evidence by
  origin anyway — a message is admissible only when its source URL matches the
  run's own origin — because the teardown step is one a tired operator skips.

- **`all` defaults to false, which is a mitigation you should not throw away.**
  The default scope is "since the last navigation"; `all: true` deliberately
  reaches back across the whole session, which is precisely how stale
  cross-origin messages enter evidence. Prefer the default, and when a census
  genuinely needs `all: true`, filter by origin in the same breath.

- **The result header is scoped to the CURRENT page; the returned list is scoped
  to your request.** They disagree, and the disagreement reads the wrong way: a
  call can print `Total messages: 0 (Errors: 0, Warnings: 0)` and then list a
  stale error underneath it. Never treat the header count as the verdict on
  console cleanliness — read the list. (Verified in the same probe: header `0`,
  body one surviving pre-navigation marker.)
- **Response bodies are available** (verified in the 0.0.78 package,
  2026-07-31): `browser_network_requests` lists numbered requests, then
  `browser_network_request` with that `index` returns full headers and
  body. Use THIS for cross-layer payload evidence — it carries the page's
  own session, so it stays correct in auth-on modes where an
  unauthenticated direct fetch would not reproduce what the page received.

  **This is also the harness's main credential-leak vector, and it is on by
  default.** In an auth-on mode those headers contain the session: `Cookie`,
  `Authorization: Bearer …`, CSRF tokens; bodies contain personal data. So:

  | Do | Not |
  |---|---|
  | request a single `part` — the status, or the one field in dispute | dump whole headers "to trim later" |
  | redact at capture: `authorization: Bearer <REDACTED>` | paste raw and rely on review |
  | quote the 3 lines that prove the claim | attach the full response body |

  `scripts/verify-run.sh` fails a run whose artifacts carry credential-shaped
  strings that are not marked `<REDACTED>` — a floor, not a proof: it cannot
  read a token that is visible inside a screenshot, and a novel token format
  will pass it. Full rule: `references/evidence-schema.md` §Redaction.

## Temporal evidence (recording)

Not part of the required capability set, and its absence is a real limitation:
a still screenshot cannot prove jank, delayed feedback, focus loss, or a
success animation that fires before the response. Where the tool offers a
trace or video, use it for those claims and store it under `evidence/`. Where
it does not, mark the finding **needs video verification** rather than dropping
it or overclaiming from stills — see `references/browser-driver-contract.md`
§Optional capabilities.

On 0.0.78 no video/trace tool is exposed through MCP, so temporal findings from
this adapter are limited to before/after stills plus a described sequence, with
timings marked approximate unless anchored to an observable event (a network
request, a state change).
