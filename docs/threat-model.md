# Threat model

Written 2026-08-03, after three review rounds in which a recurring class of
findings assumed an attacker this harness does not defend against. Without a
stated model, "is this a bug?" has no principled answer and the bar drifts
toward "assume an adversary" — which produces true statements and misranked
work.

This file states the bar. Findings should be ranked against it.

---

## Who this tooling defends against

**1. A tired operator.** Runs the installer twice, passes a stale `--dest`, has
a `.ui-qa-install.json` left over from a different layout, forgets teardown,
points the stack runner at the evidence directory, commits half of a
regenerated stub set.

**2. A lazy or degraded explorer.** An agent that runs out of context halfway,
skips a viewport, never provokes the error state, writes a confident report over
thin evidence, files everything as one severity, pastes a raw header block
"to trim later", or narrates coverage it did not achieve.

**3. Ordinary filesystem accidents.** A symlinked directory left over from
another checkout, a relative path that escapes the tree, an evidence file that
does not exist, a screenshot that is zero bytes.

**4. Its own prose drifting from its own tooling.** Generated stubs going stale,
platform layouts diverging, a metric with no denominator, documentation
promising an invariant nothing checks.

These are the realistic failure modes of an agent-driven QA harness, and every
one of them produces the same damage as malice would: a run that reads as
coverage and is not.

## Who it does NOT defend against

**An actor with write access to the target repository.**

If someone can write files into your repo, they can edit `install.sh`, add a git
hook, replace the skill, or run `rm -rf` directly. Nothing in a build-time
installer can be a security boundary against that, and pretending otherwise
misallocates effort.

Concretely, these are **out of scope by design**:

| Concern | Why out of scope |
|---|---|
| The `.ui-qa-managed` marker is forgeable | Writing the marker requires repo write access; so does editing the installer that reads it. The marker prevents *the installer's own misconfiguration* from deleting an unowned directory — that is its whole job, and it does it. |
| A crafted `coverage.tsv` or `findings.md` could satisfy the gate | The artifacts are authored by the entity being audited. A gate cannot validate a self-report into truth; it can only make an *accidental* gap impossible. Deliberate misreporting is calibration's problem, not the gate's. |
| An explorer could read source and not declare it | Pass A's isolation rests on the platform's dispatch boundary plus the read declaration. A dishonest declaration is undetectable from the artifacts. Stated in `docs/known-limitations.md`. |
| A repo-writable actor could poison the manifest, seeds, or exemplars | Same reasoning. Calibration integrity depends on operator discipline (blind seeding), which is procedural by nature. |
| Timing races between check and use (TOCTOU) in local scripts | Single-user, non-privileged, build-time tooling. Nothing here runs setuid or as a service. |

## What that does not excuse

Being out of scope as *security* does not make a code path correct. Two rules:

1. **If the same defect can be reached by accident, it is in scope.** A symlink
   that redirects a write is out of scope as an attack and squarely in scope as
   an accident, because stray symlinks happen. That is why the containment
   checks exist and why `realpath` is used rather than string prefixes.
2. **Blast radius sets severity, threat model sets priority.** Anything that can
   destroy data outside the directory the harness owns is P0 regardless of how
   it is reached. Deleting `.git` because a config file said `.git` is a real
   P0; the fix was refusing reserved paths and marker-gating deletion, not
   authenticating the marker.

## The gate's contract, stated positively

`verify_run.py` asserts that a run is **well-formed and fully accounted for**:

- every required artifact exists, including a functional pass unless
  `--pass-a-only` is explicit;
- Pass-A artifacts still hash to their recorded, path-bound values;
- every required coverage cell is accounted for, with evidence resolving inside
  the run directory;
- every finding record individually carries every mandatory field, with the
  severity vocabulary of its own class;
- no credential-shaped text is present unredacted;
- the run directory is not doubling as a stack directory.

It does **not** assert that the findings are correct, that a screenshot shows
what its row claims, that an `na` reason is honest, or that an image contains no
visible token. Those limits are printed by the gate itself on success, so a
passing run cannot be quoted as more than it is.

## For reviewers

Useful findings against this repo answer one of:

- Can a **tired operator or degraded explorer** reach this, with no malice?
- Does this destroy or expose data **outside** the directory the harness owns?
- Does the tooling **claim** an invariant it does not enforce, or does prose
  promise more than code delivers?
- Is a **method** claim unsupported — a metric without a denominator, a
  threshold without a formula, an authority claim without controls?

Findings that require an actor who can already write to the repository are
noted, not fixed, and belong in this table rather than in a P0 row.
