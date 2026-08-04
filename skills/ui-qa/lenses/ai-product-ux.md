# Lens: AI-product UX

**Load when** the surface shows model-generated output, chat, agent activity,
recommendations, scores, forecasts, or any value the system produced rather
than recorded.

The spine's §9 (feedback and state honesty) already forbids collapsing fact,
estimate, unavailable, pending, rejected and failure into one rendering. This
lens is what §9 becomes when the *product itself* is a source of uncertainty:
the screen is not merely reporting the world, it is asserting a claim, and
the user has to decide how much to believe it.

Ask these as the persona, on the rendered screen.

## 1. Provenance — where did this come from?

- Can the persona tell, without being told by a human, which parts of this
  screen are recorded facts, which are model output, and which are the user's
  own input echoed back? Undifferentiated rendering is the defect; a subtle
  italic is not differentiation.
- Is the *basis* of a generated claim reachable — the documents, rows,
  filters, or time window it used? "Reachable" means one obvious interaction,
  not a tooltip that names an internal pipeline.
- Do citations, when present, actually resolve to something that supports the
  claim, or are they decoration? Follow one. A citation that 404s or lands on
  an unrelated page is worse than no citation, because it manufactures trust.
- Is the model/version/date of generation discoverable where staleness would
  change the decision?

## 2. Confidence — how sure is it, and does the screen say so honestly?

You cannot see whether the system has an internal confidence value — that is a
Pass-B question about the API, not something the screen tells you. What you can
judge is whether **what is displayed** supports the certainty it projects. Ask
it that way round:

- Where the screen expresses confidence (a number, a badge, a colour, a hedge),
  can the persona act on it? "Based on 2 of 14 filings" is actionable; a bare
  `0.82`, or a colour with no legend, is not.
- Where the screen expresses **no** uncertainty at all, does its presentation
  still promise more than a generated claim can carry — stated as flat fact,
  with no basis, no date, no hedge?
- **Precision theatre:** does the number's precision exceed what its own
  visible basis could support? `73.4%` beside "1 of 2 recommendations" is a
  finding from the screen alone — significant digits are a claim about
  certainty, and the denominator refutes it. This is the version of the check
  that needs no knowledge of internals.
- Are aggregates shown with their denominator (spine §5), and are single-
  sample aggregates called out as such? One recommendation rendered as a
  percentage is the canonical false-confidence defect.
- Does anything hedge so heavily that the persona cannot act at all? Both
  overclaiming and unusable hedging are findings; name which one you saw.

## 3. Steerability — can the persona direct it?

- Is there a way to constrain, re-scope, or re-run the generation, or is the
  only affordance "accept what you got"?
- Can the persona **stop** in-flight generation, and does stopping preserve
  the partial output rather than discarding it?
- Are the inputs that shaped the output visible and editable *where the
  output is*, so the persona can change one and see the effect — or must they
  navigate away and lose the result?
- Does the UI make clear what the system will and will not do on its own?
  Where an action has side effects (sending, saving, spending, filing), is
  the boundary between "drafted for you" and "already done" unmistakable
  before the fact, not after?

## 4. Correction — what happens when it is wrong?

- Assume the output is wrong. Trace the persona's path: is there one? Editing,
  overriding, rejecting, reporting, or simply dismissing all count — no path
  at all is a high-severity finding on any surface that drives a decision.
- Does a correction persist, or does the next render silently restore the
  model's version? Silently discarded user corrections are a trust defect,
  not a bug in the small.
- Is the corrected value visibly marked as human-edited afterwards, so a
  later reader is not misled about provenance?

## 5. Streaming, latency and the six states

- While generating: does the screen distinguish *thinking* from *stalled*?
  An indeterminate spinner past a few seconds is indistinguishable from a
  hang — check what the persona would conclude at 5s, 15s, 60s.
- Does partial/streamed output ever render as if complete? A response that
  stops mid-sentence with no terminal marker is a defect: the persona cannot
  tell truncation from an answer.
- On failure mid-generation: is the partial output preserved, is the failure
  named in plain language, and is retry offered without re-entering the
  request?
- Empty results: does the screen distinguish "the model found nothing",
  "the model could not run", and "there is nothing to look at yet"? Three
  different states, routinely collapsed into one blank panel.

## 6. Language and framing

- Does the copy attribute agency honestly — describing what the system did,
  not implying understanding, intent, or certainty it does not have?
- Does it avoid internal vocabulary for user-facing concepts (model names,
  pipeline stages, prompt/context/token/embedding) where the persona has a
  plain word?
- Are refusals and guardrail messages actionable — saying what the persona
  can do instead, rather than only what was declined?

## 7. Consequence proportionality

- Is the friction before a consequential AI-driven action proportional to its
  cost, and is the friction placed where the persona can still change course?
  A single click that files, sends, or spends on model output is a finding
  regardless of how good the model is.
- Does the screen ever present a generated claim in a context that implies
  institutional authority it does not have (a professional-looking
  advisory panel with no basis, source, or date)? Say so plainly — this is the
  highest-consequence finding class this lens produces.
