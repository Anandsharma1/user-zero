# Pass-A Dispatch

The fresh-eyes guarantee is the harness's central claim, and until it has an
operational procedure it is only an intention. This file is that procedure:
how to dispatch Pass A so it *cannot* inherit context, and how to detect
afterwards that it did not.

Be clear about the strength of what follows. Context isolation is enforced by
the platform's own dispatch boundary; the packet-only rule and the read
declaration are enforced by the explorer's compliance plus an after-the-fact
check. That is weaker than a sandbox, and it is why the read declaration is
mandatory rather than encouraged: it converts a silent violation into a visible
one.

## 1. Isolation requirements

| Requirement | Why |
|---|---|
| A **fresh agent context** that has not read the repository's instruction files, specs, or source in this session | the whole point: an explorer that already knows the answer cannot discover a comprehension failure |
| A **fresh browser profile** | prior cookies/storage change what the persona sees |
| A **fresh console buffer** | a stale message from an earlier run becomes a phantom finding — see the adapter's console caveats |
| **Write access only to the evidence directory** | evidence is the output; the repository is not |
| **No source, spec, or state-model access** | contamination boundary in `charter-schema.md` §Pass-A packet |

## 2. Platform dispatch

**Claude Code.** Dispatch the registered `user-zero` subagent. A subagent
starts with its own context and receives only the prompt it is given, which is
what makes it the correct mechanism — the packet must be that prompt.

- The dispatching session has almost certainly read `CLAUDE.md`, specs, or
  source. Never paste, summarize, or allude to any of it in the packet. "As you
  know, this screen shows the reconciliation status" is contamination.
- The subagent's tool grant is the generated stub's `tools:` line — Read,
  Write, and the adapter's tools. It has no source-search tools by grant; do
  not add them for a Pass-A dispatch.
- One charter per dispatch. Reusing a subagent for a second charter carries the
  first charter's screens into the second's fresh eyes.

**Codex.** Dispatch a fresh explorer whose entire prompt is
`agents/user-zero.md` plus the packet. Do not run Pass A in the session that
authored the charter or read the profile — start a new one. Where the harness
supports per-skill agent metadata (the generated `openai.yaml` beside the
platform's skill stub), keep implicit invocation disabled so Pass A is never
entered accidentally from a context that has already read specs.

**Any platform.** If you cannot guarantee a fresh context, you cannot run
Pass A. Run Pass B only, and label the output *Pass-B only — no fresh-eyes
evidence*. A contaminated Pass A is worse than a missing one, because it
produces confident comprehension claims from someone who already knew the
answer.

## 3. The packet is the whole input

Assemble exactly the fields in `charter-schema.md` §Pass-A packet — no more.
Two failure modes to watch, both of which look harmless:

- **Helpful framing.** Adding "this is the reconciliation dashboard; users
  compare balances here" hands over the answer to the north-star question.
  The persona description is a *knowledge boundary*, not a briefing.
- **Leading oracles.** "Check that the totals match" tells the explorer both
  what to look at and what is true. Oracles are Pass B's.

## 4. Read declaration (mandatory)

Every Pass-A report ends with:

```markdown
## Read declaration
Files read:
- <path>            (or: none beyond the packet)
Commands run:
- <command>         (or: none beyond browser tools)
Packet-external material encountered:
- <anything that reached me unasked, and how>   (or: none)
```

Rules:

- The declaration is part of the hashed Pass-A artifact.
- A declaration listing anything outside the packet, the taxonomy, the selected
  lenses, and the evidence schema **voids the Pass-A run**. Re-run it fresh.
- "Encountered unasked" is a real category — an error page that dumps a stack
  trace, a source path in a console message. It is not a violation; recording
  it is what keeps the boundary auditable. Concealing a read is the violation.

## 5. Contamination detection after the fact

Cheap checks the runner should run before accepting a Pass-A report. None is
conclusive on its own; together they catch the realistic cases:

1. **Declaration diff** — anything listed beyond the allowed set → void.
2. **Vocabulary check** — grep the Pass-A report for terms that exist only in
   internal artifacts (feature names, enum tokens, table or column names,
   endpoint paths). A fresh explorer can only know these if the UI showed them,
   in which case the report should be *complaining* about them. Naming one
   approvingly is the signal.
3. **Certainty check** — Pass A stating that a value is *correct* rather than
   *plausible* implies an oracle it should not have had. Fresh eyes can say "I
   cannot tell whether this is right"; they cannot say "this is right".
4. **Hash check** — `scripts/verify-run.sh` re-verifies the recorded sha256
   after Pass B, so a later rewrite is detected rather than trusted.

## 6. Cohort dispatch

Everything above, once per persona, with one addition: **reset browser state
between personas** (the adapter's teardown call — for Playwright MCP,
`browser_close`). Without it, a console error emitted during persona 1 is still
in the buffer for persona 2, and a stale same-origin error reported by every
persona aggregates into a falsely "universal" finding — the single most
misleading artifact a cohort run can produce.

Per-persona contexts must also be mutually fresh: no explorer may see another's
report, and no explorer may be reused across personas.
