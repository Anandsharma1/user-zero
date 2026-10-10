# user-zero

**A UI QA explorer for coding agents.** It opens your app in a real browser and
reviews it the way a good human tester would — walking through real tasks,
noticing what is confusing, checking whether the numbers on screen are honest —
and writes up what it finds with screenshots as proof.

Works with Claude Code and Codex from one shared source, and runs in Cursor as
a Pass-B-only skill (see [Installation](#cursor)).

The reviewer is an AI agent; the **harness** is everything around it that makes
its output worth believing — starting the app safely, deciding what must be
covered before it looks, keeping the first pass ignorant of the specs, demanding
a screenshot for every claim, and measuring itself against known bugs. New here?
Start with **[docs/concepts.md](docs/concepts.md)** — it explains profile,
charter, oracle and lens with one e-commerce example carried end to end.

---

## What it is for

Normal UI tests check things somebody already thought of. They pass when the app
renders the fixture you gave it. They never notice that a page which is
technically correct is *wrong as a product*:

- a percentage with no denominator, so one data point looks like a trend
- an internal ID where a person's name should be
- a missing value shown as a confident `0`
- a popup that hides the very thing you need to read to decide
- a screen a first-time user simply cannot make sense of

That gap is what this fills. It does **not** replace your test suite — that
stays your safety net. This is the explorer that finds the problems nobody wrote
a test for.

Two things make it more than "ask an AI to look at my UI":

1. **It looks twice, in a fixed order.** Once knowing nothing, then once
   knowing everything. Fresh confusion is only real if it comes from someone who
   hasn't seen the spec — and you only get one chance at that per screen.
2. **Every finding needs proof.** A screenshot, the exact screen, what a user
   loses, and a specific fix. No "this feels cluttered."

During new development, use `glance` for quick feedback and re-run after changes.
The evaluator explicitly examines screenshots for attention, use of space,
wording, decoration, and opportunities to shorten or disclose secondary content.
It records that review even when it finds no concern. Technical terms, density,
and strong borders are judged by their usefulness to the persona's task.

## What it checks

Every judgement traces to a named principle, so a finding reads "this confused
me *because* the heading names an internal feature" — not "this feels off". The
principles come from
- Nielsen's heuristics,
- Norman's design principles,
- ISO 9241-110,
- Gestalt,
- Fitts's and Hick's laws,
- WCAG,
- Component guidance of Material, Apple HIG, Carbon and Polaris.
  
They live in three places: the **spine** (always loaded), ten optional **lenses**, and the **evaluator's own
operating rules**.

### Data honesty — the checks ordinary tests skip

- **Missing is never zero.** An unavailable value shows "—" or a label, never a
  fabricated `0`.
- **Every aggregate shows its denominator.** A percentage without its sample
  size creates false confidence.
- **No internals leak.** IDs, enum tokens, paths and stack traces never stand in
  for names or error text.
- **Numbers agree with each other.** Totals match their rows, two screens match,
  and the rendered value matches the payload the page itself received.
- **Saved means saved.** What you saved is still there after a reload.
- **No pretending.** Nothing claims to be done before it is, fact / estimate /
  unavailable / pending / rejected / failure each look different, and
  placeholder data is unmistakable.

### UX craft — the always-on spine

Twelve areas, asked only where they apply to the screen in front of it. Full
question list: [`ux-evaluation-taxonomy.md`](skills/ui-qa/references/ux-evaluation-taxonomy.md).

| Area | What is checked |
|---|---|
| Layout | Grouping, alignment, consistency, emphasis, reading order |
| Hierarchy and density | The answer comes first, detail is disclosed progressively, density suits the screen's job, headings use the user's words |
| Right component for the job | Radio vs dropdown vs search by option count; modal vs drawer vs inline vs page; toast vs inline error vs banner vs dialog; button vs link |
| Component behavior | No dead controls, disabled controls say why, safe defaults, destructive actions distanced and undoable, feedback within ~100 ms, keyboard and focus return |
| Tables | Column order and width, numeric alignment, semantic sorting, per-cell loading / unavailable / error states |
| Navigation | Orientation, Back and refresh safety, no dead ends, deep-linkable state |
| Sizing and real estate | Targets of roughly 44 px or more, above-the-fold priority, readable line length, control size matching importance |
| Type, colour, theme | WCAG AA contrast in every theme, colour never the only signal, one meaning per semantic colour |
| Feedback and trust | Visible system status, empty states that say why, plain-language errors that keep the user's work |
| Language | The user's vocabulary, one word per concept, labels over placeholders, buttons that say what they do |
| Cognitive load | Few choices at a time, recognition over recall, short paths for frequent tasks |
| Accessibility | Full keyboard traversal, visible focus, accessible names, headings and landmarks, reduced motion |

Two structured methods run over these: a **cognitive walkthrough** per task
(will the user know what to try, see the control, recognise it, and understand
the feedback?) and a **heuristic sweep** per screen.

### Lenses — loaded only when the surface needs them

A charter names the one or two it needs. A lens that does not apply produces
junk findings, and that gets measured.

| Lens | Load when the surface… | Checks |
|---|---|---|
| [`ai-product-ux`](skills/ui-qa/lenses/ai-product-ux.md) | shows model-generated output, chat, or predictions | provenance, honest confidence, steerability, correction paths |
| [`forms-and-validation`](skills/ui-qa/lenses/forms-and-validation.md) | collects input of consequence | validation timing, error summaries, preserved work, partial success |
| [`data-visualization`](skills/ui-qa/lenses/data-visualization.md) | renders charts, gauges or maps | scale integrity, missing vs zero, uncertainty, encoding choice |
| [`resilience-and-continuity`](skills/ui-qa/lenses/resilience-and-continuity.md) | holds sessions, unsaved work or long operations | expiry, offline, stale data, conflicts, honest degradation |
| [`accessibility-dynamic`](skills/ui-qa/lenses/accessibility-dynamic.md) | has overlays, live regions, drag or auth | focus over time, announced changes, 200% / 400% zoom, pointer alternatives |
| [`simplicity-and-restraint`](skills/ui-qa/lenses/simplicity-and-restraint.md) | has grown by accretion | what should not be there at all |
| [`persuasion-and-dark-patterns`](skills/ui-qa/lenses/persuasion-and-dark-patterns.md) | asks for money, consent or personal data | choice symmetry, consent honesty, pressure tactics |
| [`localization-and-locale`](skills/ui-qa/lenses/localization-and-locale.md) | ships in more than one language or region | text expansion, RTL, locale formats |
| [`touch-and-mobile`](skills/ui-qa/lenses/touch-and-mobile.md) | is used on phones or tablets | thumb reach, gestures, interruption tolerance |
| [`motion-and-timing`](skills/ui-qa/lenses/motion-and-timing.md) | animates, streams or has perceptible latency | purpose, duration, latency honesty, reduced motion |

Registry with the exact triggers: [`lenses/MANIFEST.md`](skills/ui-qa/lenses/MANIFEST.md).

### How it judges

The evaluator's persona and operating rules are in
[`agents/user-zero.md`](skills/ui-qa/agents/user-zero.md).

- **Fresh eyes first, informed second.** Pass A never sees specs or source. Pass
  B may explain a confusion but never delete it.
- **Screenshot or it did not happen.** Every finding names its screen, what the
  user loses, the principle violated, and a specific fix.
- **Severity and priority are separate numbers.** Rarity never lowers severity;
  traffic never raises it.
- **Coverage is declared, not narrated.** Every required row is done with a
  screenshot or skipped with a reason.
- **Claims stay bounded.** Without an oracle it cannot say a value is correct,
  and it does not measure users or replace research.
- **Safe by construction.** It changes the app only through its UI, redacts
  credentials as it captures, and a failed health check stops the run.

---

## Two ways to run it

Pick by what you want the output to be good for.

| | `glance` | Full mode (charters) |
|---|---|---|
| **Setup** | none — just a URL | a profile, then one charter per feature |
| **Uses the app** | yes — journeys, clicks, navigation, console | yes |
| **Checks data** | consistency, honesty, plausibility, persistence | all of that, **plus correctness against your spec, API and database** |
| **Reproduces findings** | no | yes, from a fresh context |
| **Coverage** | what it reached, stated plainly | a required checklist, gated |
| **Output is** | an expert's opinions, judge each on its screenshot | evidence you can pin as a test and cite in a decision |
| **Good for** | "what's wrong with this page", deciding where a charter is worth writing | anything you need to rely on |

Same evaluator and same expertise in both. The difference is entirely in what
surrounds it — see [docs/concepts.md](docs/concepts.md) for why that difference
falls out of one simple table.

---

## Quick start

Install into your product repo, then run it:

```bash
git clone https://github.com/Anandsharma1/user-zero.git
cd user-zero
./scripts/install.sh /path/to/your-product-repo
```

Then, in Claude Code or Codex inside your repo:

```
/ui-qa glance /dashboard                 quick expert look at one screen — no setup
/ui-qa                                   list the charters you have
/ui-qa explore /dashboard                write a charter for a screen you have not covered
/ui-qa checkout-flow                     run one charter
/ui-qa checkout-flow --calibrate         measure the harness before you trust it
/ui-qa checkout-flow --cohort novice,expert   run it as several kinds of user
```

### Just want a quick look? Use `glance`

```
/ui-qa glance /dashboard --lenses forms-and-validation
/ui-qa glance /dashboard --adapter claude-chrome          # through real Chrome
/ui-qa glance /dashboard --cross-check claude-chrome      # Playwright primary, Chrome re-check
```

`glance` needs **nothing set up** — no profile, no charter, no calibration.

Which browser drives it is a **binding, not a discovery**: an explicit
`--adapter` flag wins, else the profile's binding, else whatever the session
has. Two adapters ship — Playwright MCP (the default: isolation, network
bodies, phone viewports) and Claude-in-Chrome (real-Chrome rendering; measured
limits, dedicated QA profile required). `--cross-check` gives you both the
sane way: primary run on one, rendering-sensitive findings re-judged on the
other, every screenshot naming its instrument. Never two primaries.

It still *uses* the product: walks journeys end to end, clicks things and checks
they do what they say, tests Back/refresh/deep links, watches the console, and
checks the data on screen — totals against the rows above them, two screens
against each other, the rendered value against the payload the page itself
received, missing values against fabricated zeroes, and whether something you
saved is still there after a reload.

What it cannot do is say a value is **correct**, because that needs an authority
it does not have. So when correctness is the question, it says so:

```
needs_oracle: yes — cannot verify the figure without the batch record
```

which is useful output: it tells you exactly where a real charter would earn its
keep. Its label states the trade:

```
GLANCE — uncalibrated, no oracles. Functionality, navigation, and data honesty
were exercised through the UI. Nothing was checked against a spec, API contract,
or database, so no value here is verified as correct. Findings are not
reproduced, not suppression-checked, and are not coverage. Judge each one on its
screenshot.
```

**Uncalibrated does not mean unusable.** Calibration measures the harness, not
the finding — you are the calibration in glance mode. A problem you can see in
its screenshot is worth fixing without a rediscovery score. What you cannot do is
add glance findings up into a statement about the product, or read "no findings"
as good news. Details: `references/glance-mode.md`.

Everything below describes the **full mode**, which is what turns a finding into
evidence you can act on. It needs one file filled in (`PROFILE.md`) and a browser
tool registered — the installer prints both steps. Full walkthrough:
[docs/OPERATIONS.md](docs/OPERATIONS.md).

Want to see it work without touching your product? Skip to
[Try it on the shipped fixtures](#try-it-on-the-shipped-fixtures).

---

## How a run works, step by step

This is the **full mode**. A **charter** is one testing mission: a screen or
feature, a kind of user, and the question you want answered. Running one goes
like this.

(`glance` is roughly steps 3 and 5 with nothing around them — it explores and
reports, then stops. No health-gated startup, no required checklist, no oracle
pass, no reproduction.)

**1. Start the app and check it is really up.**
Uses the commands in your `PROFILE.md`. If the health check fails, it stops —
testing a half-started app produces fake findings. For charters that change
data, it first takes a snapshot and proves the app is actually pointed at the
copy, not your real data.

**2. Work out what must be covered.**
Builds a required checklist from the charter: every task × every screen size ×
every state (normal, loading, empty, error, unavailable, pending), plus back
button, refresh, keyboard, and each theme. This is written down *before* the
explorer starts, so the explorer cannot quietly shrink its own scope.

**3. Pass A — fresh eyes.**
Starts the `user-zero` agent in a brand-new session with a clean browser. It
gets only: the URL, the mission, who it is pretending to be, the question to
answer, the tasks, and the screen sizes. **No specs, no source code, no expected
values.** It walks the tasks like a real first-timer, screenshots everything,
watches the browser console, and writes down what confused or annoyed it.

It finishes with an **exit interview** in that user's own voice: could I answer
the question, how hard was each task (1–7), would I trust this, what would I
tell a friend. Then the report is locked and hashed.

**4. Pass B — informed.**
A second pass loads the real information: your spec, your formatting rules, your
state models. It checks whether things actually work and whether the data is
right, looking at API responses or database records when the screen alone cannot
prove it.

Pass B can *explain* something Pass A found confusing. It can never delete it.
"Correct per the spec but incomprehensible to the user" stays a finding.

**5. Sort the findings.**
Every finding is sorted by what it *is*, not by which pass found it:

| Type | Meaning | Where it goes |
|---|---|---|
| **Product defect** | Broken, dishonest, wrong data, accessibility failure | Reproduced from scratch, packaged with proof, decided by your review process, then pinned as a test |
| **Experience opportunity** | Confusing or awkward, but nothing is technically broken | A ranked list of improvements — not a pass/fail gate |
| **Observation** | Noticed, but minor or uncertain | Recorded, no action |

Anything already on your known-issues list is cited, not reported again. But if
something matches a bug you already *fixed*, that is a regression — the opposite
of ignorable.

Each defect also gets two separate numbers: **severity** (how bad it is on its
own) and **priority** (how soon to fix it). Kept apart on purpose, so a rare
data-corruption bug on a quiet page stays critical, and a crooked label on your
busiest page stays minor.

**6. Reproduce each defect from scratch.**
Fresh browser, fresh state. If it does not happen again, it is downgraded to an
observation and the failure to reproduce is recorded.

**7. Check the run itself.**
`verify-run.sh` checks the paperwork mechanically: are all the files there, does
the Pass A report still match its hash (so nobody rewrote it later), is every
required checklist item either done-with-a-screenshot or skipped-with-a-reason,
does every finding have all its fields, and are there any credentials
accidentally captured in the evidence. **A run that fails this is reported as an
incomplete run, not as coverage with excuses.**

**8. Hand off.**
Confirmed defects go to your review process, then to whoever writes the
regression test. The run leaves a folder of screenshots, findings, and a short
debrief — including how confident the explorer felt, which is the first thing a
human should read.

### And one rule around all of it

**Do not believe a run until the harness has been measured.** Until a charter
passes calibration, every run is labelled *harness calibration* and cannot be
used to claim a feature is ready. Calibration puts known bugs into the app and
checks the explorer finds them, and puts approved-good screens in front of it and
checks it stays quiet. Seven scores, each with a pass mark.

---

## What is inside

### The pieces you interact with

| Piece | What it does |
|---|---|
| `/ui-qa glance` | one expert look at a screen, no setup — see the table above |
| `/ui-qa` command | runs charters, writes new ones, runs calibration |
| [`user-zero` agent](skills/ui-qa/agents/user-zero.md) | the evaluator itself — a senior UX reviewer who tests as your user but explains problems like an expert |
| `PROFILE.md` | the one file describing *your* product: how to start it, who your users are, your wording and formatting rules, where your specs live |
| `charters/*.md` | one small file per feature — about 50 lines each |
| `calibration/` | known bugs and approved-good screens, used to score the harness |
| `qa-output/` | the results of each run: screenshots, findings, debrief |

### What the evaluator knows

- **The spine** — [`ux-evaluation-taxonomy.md`](skills/ui-qa/references/ux-evaluation-taxonomy.md),
  always loaded: the twelve areas in [What it checks](#what-it-checks), plus the
  walkthrough and sweep methods and the severity / priority model.
- **Ten lenses** — [`lenses/`](skills/ui-qa/lenses/), loaded only when relevant,
  listed in the table above.
- **The persona** — [`agents/user-zero.md`](skills/ui-qa/agents/user-zero.md):
  a senior UX reviewer who tests as your user but explains problems like an
  expert.

Lenses are read *by* the one evaluator. They are never run as separate
reviewers — five reviewers means five overlapping reports and a merge job for
you.

### Supporting scripts

| Script | Purpose |
|---|---|
| `scripts/install.sh` | install or upgrade into a product repo |
| `scripts/uninstall.sh` | remove it again, keeping your work |
| `scripts/sync-platform-dirs.sh` | regenerate the small per-tool pointer files |
| `scripts/check-platform-sync.sh` | fail if those pointers or plugin bindings drift |
| `scripts/sync-plugin-package.py` | derive plugin manifests, catalogs, and the Claude agent entry point |
| `skills/ui-qa/scripts/verify-run.sh` | the post-run check from step 7 |
| `fixtures/serve.sh`, `fixtures/probe.sh` | the practice app and its bug checker |
| `tests/run-tests.sh` | 90 tests for all of the above |

---

## Requirements

| Need | Why |
|---|---|
| Claude Code and/or Codex | runs the agent and its two passes |
| Node + `npx` | the browser tool (`@playwright/mcp`) |
| `python3` 3.9+ | the run check and the fixture server |
| An app you can actually start, with a health check | there is no mock mode; it drives the real thing |
| A way to copy your data | needed before any charter that writes data |
| A person who can approve things | the profile, the good-screen examples, and the value rankings all need a human |

---

## Installation

Choose one route per host:

| Route | What it installs | Product setup |
|---|---|---|
| Codex skill installer | Personal `ui-qa` skill, references, lenses, and run gate | Register the browser separately; full runs need a profile and charters |
| Codex or Claude Code plugin | The same canonical skill plus pinned browser configuration; Claude also gets the evaluator agent | `glance` needs an app URL; full runs need a profile and charters |
| Cursor personal skill | Personal `ui-qa` skill in `~/.cursor/skills/` | Register the browser in Cursor; Pass B only; full runs need a profile and charters |
| Cursor plugin | The canonical skill plus the pinned browser configuration; **no evaluator agent** | Needs plugin installs your Cursor team allows; Pass B only |
| Repository script | Harness files, platform pointers, and product profile/charter templates in your repo | Register the browser and fill in the product binding |

**Codex: paste this into a conversation** (not your shell):

```text
$skill-installer install https://github.com/Anandsharma1/user-zero/tree/main/skills/ui-qa
```

Install the canonical `skills/ui-qa` directory, not a generated platform pointer.
It includes all method dependencies and explicit-invocation metadata. On the
next turn, use `$ui-qa glance <url>`; restart Codex if it has not appeared. To
register the browser for this standalone route:

```bash
codex mcp add playwright -- npx -y @playwright/mcp@0.0.78 --isolated
```

**Codex plugin** (CLI versions with `codex plugin add`):

```bash
codex plugin marketplace add Anandsharma1/user-zero
codex plugin add user-zero@user-zero
```

In the desktop app, add the marketplace and install its `user-zero` entry from
the plugin browser. Start a new session, select the plugin's `ui-qa` skill, and
ask for `glance <url>` or a charter. The package bundles the browser server;
verify it connects rather than registering a second copy.

**Claude Code plugin**, from your shell:

```bash
claude plugin marketplace add Anandsharma1/user-zero
claude plugin install user-zero@user-zero
```

The install command defaults to **user scope**: the plugin is available to you
across all projects on this machine. To limit it to a project, run the command
from that product repository with one of these explicit scopes:

| Scope | Install command | Enabled in |
|---|---|---|
| User (default) | `claude plugin install user-zero@user-zero --scope user` | `~/.claude/settings.json` |
| Project, shared with collaborators | `claude plugin install user-zero@user-zero --scope project` | `.claude/settings.json` |
| Only you, only this project | `claude plugin install user-zero@user-zero --scope local` | `.claude/settings.local.json` |

Commit project-scope settings to share the configuration. Each collaborator
still needs to install the plugin on their machine. Scope controls where the
plugin is enabled; the plugin files remain in Claude Code's managed cache.
See [Claude Code installation scopes](https://code.claude.com/docs/en/discover-plugins#choose-an-install-scope).

Start a new session and use `/user-zero:ui-qa glance <url>`. The plugin also
registers the `user-zero` evaluator agent and the Playwright server. Browser
approval and a usable browser installation are still required. Full runs follow
the same fresh-context, profile, charter, and isolation rules.

**Repository-local install**, for scaffolded product bindings:

```bash
./scripts/install.sh /path/to/your-product-repo
```

Plugin and skill installation do not automatically start your application,
create an approved product profile, or grant product-readiness authority. Keep
product profiles, charters, and evidence in your product workspace; keep the
installed method in its skill or plugin directory.

See [docs/OPERATIONS.md](docs/OPERATIONS.md#native-skill-and-plugin-installation)
for upgrades, removal, local package validation, and compatibility evidence.
Native mechanisms: [Codex skills](https://learn.chatgpt.com/docs/build-skills),
[OpenAI plugin packaging](https://developers.openai.com/plugins/build/plugins),
[Claude Code plugins](https://code.claude.com/docs/en/plugins), and
[Cursor plugins](https://cursor.com/docs/plugins).

Repository installer options:

| Option | Default | What it does |
|---|---|---|
| `--dest <path>` | `skills/ui-qa` | where the harness code goes |
| `--explorer-dir <path>` | `qa/product-explorer` | where *your* profile and charters go |
| `--platforms "claude codex"` | both | which tools to generate pointers for (`cursor`, `gemini` also available) |
| `--adapter <name>` | `playwright-mcp` | which browser tool to bind |

Your choices are saved in `.ui-qa-install.json`, so later upgrades reuse them —
just run the same command again.

**What it replaces and what it never touches:**

| Path | On install and upgrade |
|---|---|
| `<dest>/` | **replaced** — this is harness code |
| per-tool pointer files | **regenerated** |
| `<explorer-dir>/` | **never touched** — your profile, charters, calibration |
| `qa-output/` | **never touched** |

It only deletes things it can prove it created (a marker file), so if you happen
to keep your own skill or command at one of the same paths, it stops and tells
you instead of overwriting it.

Then four steps the installer will not do for you, because they are your files:

1. Add `qa-output/` to `.gitignore`.
2. Register the browser tool. Claude Code reads `.mcp.json`; Codex needs its own
   config under `CODEX_HOME`. Restart the session and check the tools really
   loaded — a config file is not proof.
3. Fill in `<explorer-dir>/PROFILE.md` and have a human approve it. Until it is
   approved, no run can claim anything.
4. Add one line to your `AGENTS.md` / `CLAUDE.md`:
   `UI QA: read skills/ui-qa/SKILL.md before any UI QA or /ui-qa request.`

### Upgrading

```bash
cd user-zero && git pull
./scripts/install.sh /path/to/your-product-repo
```

Harness code is replaced; your work is untouched. Afterwards, check whether the
browser tool version moved, and remember that a newly added lens does nothing
until a charter names it.

### Cursor

Cursor runs the skill and the browser, but **Pass B only**. The Claude evaluator
agent is deliberately not registered: Cursor documents no tool grant to bound it,
and a fresh-context Pass A has not been measured there. See
`skills/ui-qa/references/pass-a-dispatch.md`.

**1. Install the skill** (personal, works in every project). From a checkout of
this repository:

```bash
mkdir -p ~/.cursor/skills
cp -r skills/ui-qa ~/.cursor/skills/ui-qa
```

Copy the canonical `skills/ui-qa/` directory, not a generated `.cursor/`,
`.agents/` or `.claude/` pointer: a pointer stub refers back to a repository
that will not exist in your product workspace. The folder name must stay `ui-qa`
to match the skill's `name`. Then run **Developer: Reload Window**.

**2. Register the browser.** Add the pinned, isolated Playwright server to
`~/.cursor/mcp.json` (all projects) or `.cursor/mcp.json` (one project):

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

If Cursor already lists a Playwright server (for example one imported from a
Claude Code plugin), check its version and that it runs `--isolated`, or the
adapter's measured caveats do not apply. Cursor names MCP tools differently from
Claude Code; use the names Cursor actually lists.

**3. Check it.** In Customize, search for `ui-qa` under Skills, or type `/ui-qa`
in an Agent chat. Then start with `/ui-qa glance <url>`. With no browser tools
listed, the skill cannot run — fix step 2 first.

**Update or remove.** The install is a snapshot. After the skill changes:
`rm -r ~/.cursor/skills/ui-qa && cp -r skills/ui-qa ~/.cursor/skills/ui-qa`. To
uninstall: `rm -r ~/.cursor/skills/ui-qa`.

**Per repository.** `./scripts/install.sh /path/to/product --platforms "claude codex cursor"`
also writes pointers Cursor reads (`.agents/skills/`, `.claude/skills/`,
`.cursor/skills/`), alongside the harness copy and product templates.

**Cursor plugin (optional).** The package carries a Cursor manifest
(`.cursor-plugin/plugin.json`) and reuses the Claude catalog
(`.claude-plugin/marketplace.json`), which Cursor falls back to. It supplies the
skill and the pinned browser server in one install. It is not on the public Cursor
marketplace, so there are two routes:

- **Local:** copy this checkout into `~/.cursor/plugins/local/user-zero`, then
  reload the window. Prefer a copy to a symlink: per the 3.22.7 loader code, a
  symlink whose target is outside that directory is rejected. This route is
  **disabled when your Cursor team's admin turns off local plugin imports**; the
  Cursor Plugins log then shows `userLocal=false` and the plugin never appears.
  Use the personal skill above instead.
- **Team:** an admin imports the repository under Dashboard → Plugins & MCPs.

**What has and has not been verified.** The manifest, discovery rules and the
team-policy gate were checked against Cursor's documentation and the 3.22.7
loader code, and the packaging is tested. No plugin install and no QA run has been
observed working in Cursor, and the personal-skill route is unconfirmed until you
see `ui-qa` listed. Details and the local verification steps:
[docs/OPERATIONS.md](docs/OPERATIONS.md#native-skill-and-plugin-installation).

---

## Layout after installation

Inside your product repo:

```
your-repo/
├── skills/ui-qa/                  ← harness code (replaced on upgrade)
│   ├── SKILL.md                     the method: passes, sorting, rules
│   ├── agents/user-zero.md          the evaluator
│   ├── references/                  taxonomy, charter/profile/evidence schemas,
│   │                                coverage contract, Pass-A dispatch,
│   │                                calibration protocol, cohorts, glance mode
│   ├── lenses/                      the ten optional lens packs
│   ├── adapters/                    browser tool bindings
│   └── scripts/verify-run.sh        the post-run check
│
├── qa/product-explorer/           ← YOUR content (never touched)
│   ├── PROFILE.md                   your product: startup, users, wording, specs
│   ├── charters/                    one file per feature
│   ├── calibration/                 known bugs + approved-good screens
│   └── dossiers/                    generated notes from `explore`
│
├── qa-output/                     ← run results (gitignored)
│   └── 2026-08-04-checkout-141530/
│       ├── pass-a-report.md         fresh-eyes report (hashed)
│       ├── exit-interview.md        the user's own words
│       ├── pass-b-report.md         informed verification
│       ├── findings.md              sorted and ranked
│       ├── coverage.tsv             what was and was not reached
│       ├── evidence/                screenshots
│       ├── packets/                 one per reproduced defect
│       └── debrief.md               summary + hashes
│
├── .claude/{skills,agents,commands}/   ← generated pointers, do not edit
├── .agents/skills/ui-qa/               ← generated pointer (Codex)
├── .codex/skills/ui-qa/                ← generated pointer (compatibility)
└── .ui-qa-install.json                 ← your install choices
```

The harness code exists **once**. The per-tool files are tiny pointers that say
"read the real thing over there", so Claude Code and Codex can never end up
running different evaluators.

---

## Uninstallation

```bash
./scripts/uninstall.sh /path/to/your-product-repo            # keeps your work
./scripts/uninstall.sh /path/to/your-product-repo --dry-run  # show the plan only
./scripts/uninstall.sh /path/to/your-product-repo --purge-explorer   # remove your charters too
```

Removes the harness directory, the generated pointer files, and
`.ui-qa-install.json`. Keeps your explorer directory and `qa-output/` unless you
ask for `--purge-explorer`. Like the installer, it only deletes files it can
prove it created — anything of yours at the same path is left alone and reported.

Three things are left for you, because they are your files: the browser tool
registration, the line you added to `AGENTS.md`/`CLAUDE.md`, and the
`qa-output/` entry in `.gitignore`.

---

## Try it on the shipped fixtures

You do not need a product to see it work. The repo ships a deliberately broken
practice app:

```bash
fixtures/serve.sh &     # prints the URL
fixtures/probe.sh       # confirms all 32 planted concerns are still there
# then, in a session that has NOT read fixtures/controls.tsv:
/ui-qa fixture-dashboard --calibrate
```

`fixtures/` contains a broken three-page app (32 planted concerns across
13 kinds), a clean app as the "should find nothing serious here" control, a ready profile,
two charters, and both calibration files. The answer key lives outside the
served folder and the pages contain no comments at all, so the explorer cannot
read the answers — and tests enforce both. See
[fixtures/README.md](fixtures/README.md).

---

## Working on the harness itself

```bash
./scripts/install-git-hooks.sh                 # pre-commit checks
./scripts/sync-platform-dirs.sh                # after editing skills/ui-qa/
./scripts/check-platform-sync.sh --from-index  # verify what git will commit
./tests/run-tests.sh                           # 90 tests, no dependencies
```

Two rules: edit only `skills/ui-qa/` (everything under `.claude/`, `.codex/`,
`.agents/` is generated), and never put product names, ports, or absolute paths
in the harness — those belong in `PROFILE.md`. See [AGENTS.md](AGENTS.md).

---

## Further reading

- **[docs/concepts.md](docs/concepts.md)** — **start here.** Harness, profile,
  charter, oracle, lens in plain terms, with a full e-commerce checkout example
  showing which concept produced which finding. Plus a glossary of every other
  term.
- **[skills/ui-qa/references/ux-evaluation-taxonomy.md](skills/ui-qa/references/ux-evaluation-taxonomy.md)** —
  the full question catalog behind [What it checks](#what-it-checks), plus the
  severity / priority model.
- **[skills/ui-qa/lenses/MANIFEST.md](skills/ui-qa/lenses/MANIFEST.md)** — the
  ten lenses, when each loads, and the ideas deliberately left out.
- **[skills/ui-qa/agents/user-zero.md](skills/ui-qa/agents/user-zero.md)** — the
  evaluator's persona, sensing rules and hard rules.
- **[docs/known-limitations.md](docs/known-limitations.md)** — what is proven,
  what is not, and which rules are enforced by code versus by instructions.
  Read this before trusting a run.
- **[docs/OPERATIONS.md](docs/OPERATIONS.md)** — install, set up a product,
  write a charter, run, calibrate, troubleshoot, upgrade.
- **[docs/threat-model.md](docs/threat-model.md)** — what the tooling protects
  against (a tired operator, a sloppy explorer, stray symlinks) and what it does
  not (someone who can already write files in your repo).
- **[docs/persona-simulation.md](docs/persona-simulation.md)** — the research on
  AI agents as fake usability-test participants, what was borrowed, and the
  claims this harness refuses to make.
- **[docs/prior-art.md](docs/prior-art.md)** — the public UX-review skills that
  already exist, and why this keeps its own harness.
- **[fixtures/README.md](fixtures/README.md)** — the practice app and how to
  keep its answers hidden.

---

## What this is not

- Not a replacement for your test suite.
- Not an accessibility scanner. It does the keyboard-and-contrast judgement a
  scanner cannot; run a scanner too.
- Not a code reviewer — Pass A must not read your source.
- Not a replacement for talking to real users. It finds what a careful expert
  would find on a live build, before you spend a real person's hour. It cannot
  tell you what people want or why they came.

## License

MIT — see [LICENSE](LICENSE).
