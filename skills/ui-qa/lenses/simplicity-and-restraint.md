# Lens: Simplicity and restraint

**Load when** the surface has grown by accretion (features added over
releases), or when a redesign is being judged, or when the charter's
north-star question is "is this screen too much?"

Every other lens asks *is this done well?* This one asks *should this be here
at all?* It is the only subtractive lens, and it is the one an evaluator is
least likely to apply unprompted — the default critical instinct is to
suggest additions.

## 1. The subtraction pass

Go element by element across the screen. For each one, answer:

- **Who needs this, and when?** If the answer is "someone, sometimes",
  ask whether it earns permanent screen presence or belongs behind
  progressive disclosure.
- **What breaks if it is removed?** If nothing the persona cares about
  breaks, that is a finding — phrased as removal, not as improvement.
- **Is it here because a user needs it, or because the system has it?**
  Fields that exist because the data model has a column are the most common
  form of accretion. Internal IDs, audit timestamps, and status enums with
  one possible value are the usual suspects.
- **Is it duplicated?** The same fact rendered in a card, a table cell, and a
  header is three chances to disagree and three things to maintain.

Report removals as concrete recommendations with what they buy: "removing the
three audit columns lets the two decision columns keep full width at 1280px."
"Simplify this screen" fails the actionability metric.

## 2. Honesty of the design

- Does anything imply capability it does not have — a disabled control with no
  explanation of when it becomes available, a filter that appears to slice
  data but changes nothing, a chart axis suggesting precision the data lacks?
- Does the visual weight of each element match its actual importance, or is
  something prominent because it was easy to make prominent?
- Is decoration doing work? Gradients, shadows, illustrations, and icons
  either aid recognition and grouping or they consume attention. Name the ones
  that consume without aiding — and do not manufacture findings here, because
  aesthetic preference dressed as a principle is exactly the
  generic-commentary failure the harness measures.

## 3. Longevity and consistency

- Would this screen still be right after the product's next obvious feature,
  or does its layout assume today's exact set of things?
- Does it look like the rest of the product, or like the release it shipped
  in? Mixed component generations on one screen (an older control among newer
  ones) is a concrete, screenshot-able finding.
- Is the same job done the same way here as elsewhere — same control, same
  placement, same wording? Inconsistency is a tax the persona pays in
  relearning.

## 4. Thoroughness at the edges

Restraint is not minimalism; a spare screen that abandons the persona at the
edges is not simple, it is unfinished. Check that the removals a designer
already made did not take necessary things with them:

- Are error, empty, loading, and unavailable states designed, or did they get
  the default treatment while the happy path got the attention?
- Is the smallest declared viewport designed, or merely survivable?
- Do the least-used affordances (export, print, keyboard, deep link) still
  work, or were they left behind?

## 5. What this lens must not become

- Not a licence for taste findings. Every finding still needs route,
  screenshot, principle, consequence, and a specific recommendation.
- Not a call for a redesign. "This screen should be rebuilt" is not a finding;
  it is an abdication. Name the specific elements and the specific cost.
- Not deletion of things the persona needs but *you* did not use. If a journey
  never exercised an element, say it was unexercised — do not recommend
  removing it on that basis.
