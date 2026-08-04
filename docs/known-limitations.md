# Known limitations and maturity status

Last updated 2026-08-03, after two rounds of multi-reviewer audit.

> An earlier version of this repo's summary said "the tooling is tested; the
> evaluator isn't." That was too kind to the tooling: the second review found a
> destructive installer path and six false-green paths in the run gate *after*
> the first round of fixes and its 25 passing tests. A passing suite is evidence
> about the cases it covers and nothing else. The accurate statement is below.

The harness asks its users not to overclaim. This file is that rule applied to
the harness itself.

## Status: uncalibrated

**This is an uncalibrated human-style exploratory QA harness.** Not
production-proven, not a validated evaluator, and not a basis for any product
readiness claim today. The method is mature; the evidence that it works is not
yet in.

Round four found the ownership class applied to a **second** surface — generated
platform stubs were overwritten and pruned without the marker check that already
guarded `--dest` — and two holes in the fixtures shipped the round before: the
control registry was fetchable at `/controls.tsv`, and nine comments in the broken
app described each seeded defect in the DOM. Both defeated the fixtures' entire
purpose, and the blindness test that was supposed to catch them grepped only for
`data-seeded` and `KD-\d`. The lesson is the same one rounds two and three taught:
**a fix applied to one instance of a class leaves the other instances**, and a
test written against the defect you imagined does not cover the one you shipped.

The tooling now has a 79-test suite covering every hole four review rounds
found by hand — installer containment and ownership-gated deletion, symlink-safe
writes, staged-index correctness, platform pruning, fixture integrity, and
nineteen distinct false-green paths in the run gate. Three rounds each found real
defects after the previous round's tests passed, so the honest expectation is
that a fourth would find more.

The run gate was rewritten from shell to Python
(`skills/ui-qa/scripts/verify_run.py`) after round three, because the recurring
findings were a *language* problem rather than a series of independent bugs:
`read` dropping a final unterminated line (so a one-line network dump scanned as
zero lines), exit codes used as counters wrapping at 256, and path containment by
string prefix rather than by resolving symlinks. A real TSV reader, a real regex
engine, and `os.path.realpath` removed the class rather than the instances. The
remaining shell is installer and generator work, where it is a reasonable fit.

**What each round's findings were really about** is worth recording, because it
predicts where the next ones will be: rounds two and three found defects in the
*fixes* from rounds one and two, not in the original design. Patch-per-finding
grows the surface it is meant to shrink. `docs/threat-model.md` now states the bar
so that findings requiring repo write access are ranked as such instead of as
P0s.

## What has been verified

| Area | How |
|---|---|
| Installer containment | automated: `--dest`/`--explorer-dir` traversal, absolute paths, shell/sed metacharacters, self-target, reserved directories, symlinked components |
| Destructive-delete safety | automated: deletion is authorized by a `.ui-qa-managed` marker this installer wrote, never by the configured path — so a manifest naming `.git` is refused, and an unowned non-empty directory is never replaced |
| Generated-stub ownership | automated: a file at a platform path is overwritten or pruned only if it carries the generator's marker, so a user's own skill/agent/command at the same conventional location survives; `--dest` inside a platform directory is refused outright (it would leave a `SKILL.md` pointing at itself) |
| Fixture blindness | automated: only `apps/` is served and `serve.sh` refuses to start if the registry is inside it; served files must contain **zero** comments; no control IDs in markup; `probe.sh` reports `REPAIRED` when a control's fix marker appears, so a probe cannot outlive its defect |
| Upgrade safety | automated: harness files replaced, user-owned profile/charters/calibration preserved, non-default explorer dir rediscovered |
| Platform generation | automated: documented Codex `.agents/skills` layout, `openai.yaml`, adapter-driven tool grant, obsolete stubs pruned when `--platforms` narrows |
| Drift detection | automated: hand-edited stub caught; `--platforms` mismatch caught; partial staging caught via `--from-index`, which also uses the *staged* generator; purity hook scans staged blobs, not the worktree |
| Run gate | automated: artifact-bound hash tampering, missing Pass B, missing read declaration, self-selected coverage denominator, evidence paths escaping the run dir, reasonless gaps, per-record field gaps hidden by duplicates, credentials in header and quoted-JSON form, per-token (not per-line) redaction, no secret echoed into output, cohort persona artifacts, stack/evidence collision |
| Layer-1 purity | automated: no machine or product paths in `skills/` or `templates/`; every intra-skill reference resolves |
| Adapter tool caveats | measured by hand on Playwright MCP 0.0.78 (2026-07-31), with the probe results recorded |

`tests/run-tests.sh` — 73 tests, no dependencies. Every one exists because a
reviewer found the corresponding hole by hand.

## What has NOT been verified

This is the important half.

1. **No real product run.** Pass A, Pass B, the ten lenses, cohort mode, exit
   interviews, and repair-lift have never been exercised end to end against a
   live application. Every claim about what the evaluator *finds* is a design
   claim.
2. **No calibration scores exist.** The seven thresholds (rediscovery ≥70%,
   zero rejected high-severity findings on exemplars, consistency ≥60%, tier
   agreement ≥70%, specificity ≥80%, actionability ≥75%, ≤1 generic finding)
   are targets nobody has hit yet. Rediscovery, false-positive rate, and
   run-to-run stability are all **unknown**.
3. **Fixtures now exist; no calibration has been run against them.**
   `fixtures/` ships a deliberately broken two-page app (28 armed controls
   across 11 defect classes, machine-verified by `fixtures/probe.sh`), a curated
   clean app as positive control, an approved profile, two charters, and both
   calibration input files. Everything needed for a first blind calibration is
   in place — the run itself has not happened, so rediscovery, false-positive
   rate, and consistency remain unmeasured.
4. **No runner exists.** The method says "the runner enforces" isolation
   classes, packet assembly, coverage-row derivation, snapshot verification,
   and teardown. Today those are executed by an agent following prose. Two
   pieces are real code — `scripts/verify-run.sh` (the post-run gate) and the
   sync/check tooling — and the rest is not.

## Where enforcement is prose, not code

Stated plainly, because "enforced" appears throughout the method and it does not
mean the same thing everywhere:

| Invariant | Enforcement today |
|---|---|
| Pass-A immutability | **code** — per-artifact, path-bound hashes re-verified by the run gate |
| Coverage completeness | **code** against a runner-written required matrix; **prose** for whether a screenshot really shows the state its row claims |
| Read declaration present | **code**; its *truthfulness* is **prose** |
| A functional pass happened | **code** — `pass-b-report.md` required unless `--pass-a-only` is explicit |
| Credential redaction | **code** for text patterns; **nothing** for credentials visible inside screenshots |
| Finding-record completeness | **code**, per record |
| Destructive-delete safety | **code** — marker-gated ownership, reserved-path refusal, symlink refusal |
| Fresh-context Pass A | **platform** dispatch boundary + **prose** packet rule + **prose** read declaration, checked after the fact (`references/pass-a-dispatch.md`) |
| Isolation class / snapshot verification | **prose** — the profile supplies the mechanism, an agent runs it |
| Blind calibration | **prose** — an operator discipline, unenforceable by tooling |
| Suppression checks | **prose** |

An agent following prose is not nothing, but it is not a guarantee, and a
reader deciding whether to trust a run should know which kind of assurance each
line rests on.

## Path to beta

In order, because each step depends on the previous one:

1. ~~Local deliberately-broken fixtures spanning functional, data, visual,
   accessibility, and recovery defect classes.~~ **Done** — `fixtures/`.
2. **A first blind calibration against those fixtures, with the actual seven
   scores published here — pass or fail.** This is now the only thing standing
   between the harness and its first honest number, and it needs an operator who
   has not read `fixtures/controls.tsv`. Publishing an unfavourable result is
   part of the deal; a calibration reported only when it flatters the harness is
   not a calibration.
3. A real-product calibration on one charter, meeting the control floor (≥5
   armed controls across ≥3 classes, ≥2 exemplars, ≥2 repeat runs).
4. A runner that assembles packets and derives coverage rows mechanically, so
   the contamination boundary stops depending on the dispatcher's care.
5. Repair-lift on a sample, with its unchanged-build recurrence control.

Until step 3, every run is labeled *harness calibration*, and this file is the
answer to "can I trust it?" — the honest one being: not yet, and here is exactly
what is missing.
