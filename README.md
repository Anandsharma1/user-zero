# user-zero

**A UI QA explorer for coding agents.** It opens your app in a real browser and
reviews it the way a good human tester would — walking through real tasks,
noticing what is confusing, checking whether the numbers on screen are honest —
and writes up what it finds with screenshots as proof.

Works with Claude Code and Codex from one shared source.

The reviewer is an AI agent; the **harness** is everything around it that makes
its output worth believing — starting the app safely, deciding what must be
covered before it looks, keeping the first pass ignorant of the specs, demanding
a screenshot for every claim, and measuring itself against known bugs. New here?
Start with **[docs/concepts.md](docs/concepts.md)** — it explains profile,
charter, oracle and lens with one e-commerce example carried end to end.

> **Status: uncalibrated.** The method is finished; the proof that it works is
> not. Nobody has run it against a real product yet, and there are no
> calibration scores. The supporting tooling has 82 tests, but four review
> rounds each found real bugs after the previous round's tests passed — so treat
> the tests as proof about their own cases, not about the whole thing.
> [docs/known-limitations.md](docs/known-limitations.md) lists exactly what is
> checked by code and what depends on the agent following instructions.

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
| `user-zero` agent | the evaluator itself — a senior UX reviewer who tests as your user but explains problems like an expert |
| `PROFILE.md` | the one file describing *your* product: how to start it, who your users are, your wording and formatting rules, where your specs live |
| `charters/*.md` | one small file per feature — about 50 lines each |
| `calibration/` | known bugs and approved-good screens, used to score the harness |
| `qa-output/` | the results of each run: screenshots, findings, debrief |

### What the evaluator knows

- **The spine** (`ux-evaluation-taxonomy.md`) — always loaded. Layout and
  grouping, information hierarchy and density, choosing the right component
  (drawer vs popup vs dropdown vs radio), component behaviour, table craft,
  navigation and back-button safety, sizes and use of screen space, typography
  and themes, honest states, wording, mental effort, accessibility. Plus the two
  methods it uses: walking through a task step by step, and sweeping each screen
  against the checklist.
- **Ten lenses** (`lenses/`) — loaded only when relevant: AI/generated content,
  forms and validation, charts, resilience and session loss, deeper
  accessibility, simplicity, dark patterns, translations, touch/mobile, motion
  and timing. A charter names the one or two it needs. Adding one that does not
  apply produces junk findings, and that gets measured.

Lenses are read *by* the one evaluator. They are never run as separate
reviewers — five reviewers means five overlapping reports and a merge job for
you.

### Supporting scripts

| Script | Purpose |
|---|---|
| `scripts/install.sh` | install or upgrade into a product repo |
| `scripts/uninstall.sh` | remove it again, keeping your work |
| `scripts/sync-platform-dirs.sh` | regenerate the small per-tool pointer files |
| `scripts/check-platform-sync.sh` | fail if those pointers drift |
| `skills/ui-qa/scripts/verify-run.sh` | the post-run check from step 7 |
| `fixtures/serve.sh`, `fixtures/probe.sh` | the practice app and its bug checker |
| `tests/run-tests.sh` | 82 tests for all of the above |

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

```bash
./scripts/install.sh /path/to/your-product-repo
```

Options:

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
fixtures/probe.sh       # confirms all 28 planted bugs are still there
# then, in a session that has NOT read fixtures/controls.tsv:
/ui-qa fixture-dashboard --calibrate
```

`fixtures/` contains a broken two-page app (28 planted bugs across 11 kinds), a
clean app as the "should find nothing serious here" control, a ready profile,
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
./tests/run-tests.sh                           # 82 tests, no dependencies
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
