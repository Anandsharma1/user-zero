---
status: draft            # draft → approved
approved_by:             # who approved it
approved_on:             # YYYY-MM-DD
---

# PROFILE — <product name>

The product binding. This is the ONLY artifact regenerated when the harness
moves to a new product (or a new deployment of the same product). Schema and
the two-role onboarding procedure: `<skill>/references/profile-schema.md`.

**A draft profile authorizes nothing.** Until a human approves it, every run
is labeled "harness calibration".

---

## 1. Product summary

<One paragraph: what the application is and who uses it.>

- **Frontend origin the explorer drives:** `http://localhost:<port>`
- **Origins the explorer must NEVER drive directly:** <e.g. the API origin —
  explorers reach it only as evidence, never as a UI>

## 2. Bring-up & health gate

```bash
# exact commands, in order
```

- **Health gate (must pass before any charter starts):** <the check, and what
  a pass looks like>
- **Port ownership discovery (never assume, never reuse a recorded PID):**
  <how to find who currently owns each port>
- **Per-feature environment requirements:** <which features are dead without
  which variable, so charters can preflight their own dependencies>

## 3. Isolation mechanism

- **Snapshot:** <how durable state is copied for state-mutating charters>
- **Redirection:** <how the running app is pointed at the copy — every store
  and artifact root it touches>
- **Live proof:** <the read-only runtime check proving the process really
  carries every redirect>
- **Marker check:** <one small UI mutation proving the row landed in the
  snapshot and NOT in real data>
- **Teardown:** <validated teardown and what it deletes>

## 4. Modes

| Mode | What it is | Valid evidence FOR | Readiness claims? |
|---|---|---|---|
| | | | |

## 5. Personas

| Persona | Knows | Wants |
|---|---|---|
| | | |

Keep these few and real. Personas are a knowledge-and-goal boundary, not
characters — see `references/persona-cohorts.md` before adding a fourth.

## 6. Domain vocabulary & format conventions

- **Terminology:** <the persona's words for each concept, and the internal
  words that must never surface>
- **Formats:** <currency, dates, numbers, units, rounding, timezone>
- **Missing-value convention:** <what "unavailable" must look like, and the
  fabricated-zero prohibition>

## 7. Oracle map

| Document | Authoritative for | Traps (usage rules that prevent false findings) |
|---|---|---|
| | | |

## 8. Suppression sources

| Source | Records | Matching rule |
|---|---|---|
| | | |

## 9. Downstream integrations

- **Verdict lane** (dispositions defect packets): <skill/agent + how invoked>
- **Regression writer** (pins confirmed defects): <skill/agent>
- **RCA / learning capture:** <skill/agent>
- **Dispatch rules this project imposes on subagents:** <any>

## 10. Browser adapter & viewports

- **Adapter:** `<skill>/adapters/playwright-mcp.md`
- **Viewports charters may declare:**

| Name | Pixels |
|---|---|
| desktop | 1440×900 |
| laptop | 1280×800 |
| tablet | 834×1112 |
| mobile | 390×844 |

## 11. Test data

- **Safe fixtures:** <what may be used freely>
- **Offline-safe entities:** <what works with no external provider>
- **Must not be mutated:** <the real working data, and how it is protected>
- **Synthetic inputs:** <where they live>

## 12. Default lens selection

Which `lenses/` packs this product's charters usually need, and which are
irrelevant here. Charters may still override per surface.

| Lens | Default for this product | Why |
|---|---|---|
| ai-product-ux | | |
| simplicity-and-restraint | | |
| persuasion-and-dark-patterns | | |
| localization-and-locale | | |
| touch-and-mobile | | |
| motion-and-timing | | |
