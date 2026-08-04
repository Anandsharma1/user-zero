# Lens: Persuasion and dark patterns

**Load when** the surface asks for money, consent, personal data, a
subscription, a public action, or any commitment the persona might later
regret.

The question is not "does this screen persuade?" — every well-designed screen
guides. The question is **whether the persona, having acted, would say they
chose freely and knew what they were choosing.** That is the line between
guidance and manipulation, and it is judgeable from the rendered screen.

## 1. Choice symmetry

- Are accept and decline equally reachable, equally legible, equally named? A
  bright "Continue" beside a grey "No thanks" in half the font size is
  asymmetric by design.
- Is declining expressible in one action, or does it require hunting, multiple
  steps, or a link styled to be overlooked?
- Do the two paths use parallel language, or is one framed as loss ("No, I
  don't want to save money")? Confirmshaming is a finding — quote the exact
  words.
- Is the safe option the default, or is the consequential one pre-selected?

## 2. Consent honesty

- Does the persona learn what they are agreeing to *before* the agreement
  control, without opening another page?
- Are separate things bundled into one consent (service terms with marketing
  permission, required processing with optional sharing)? Name what was
  bundled.
- Are pre-ticked boxes doing work the persona did not ask for?
- Is withdrawal as easy as granting, and is the path visible from where the
  grant happened?

## 3. Pressure and scarcity

- Are countdowns, "N others viewing", "only 2 left", or expiring offers
  present — and is there any visible basis for them? An unverifiable urgency
  claim is a finding on the trustworthiness dimension whether or not it is
  true, because the persona cannot tell.
- Does a timer create a decision deadline the underlying task does not have?
- Does the screen interrupt a task in progress to make an unrelated ask, at a
  moment when dismissing is the fastest way to continue?

## 4. Cost and commitment clarity

- Is the total the persona will actually pay — including recurrence, renewal
  date, fees, and taxes — visible before the commit control, or revealed
  stepwise (drip pricing)?
- Is a trial's conversion date and amount stated where the trial is accepted?
- Is cancellation discoverable from the product itself, and does its path
  match the sign-up path in length?
- Does anything convert a one-time intent into a recurring commitment without
  naming it in the same sentence as the button?

## 5. Friction placement

- Is friction on the *risky* action (spending, deleting, publishing) or on the
  *safe* one (declining, leaving, exporting your own data)? Inverted friction
  is the signature of a dark pattern.
- Are irreversible actions reversible, undoable, or at least confirmed
  proportionally (spine §4)? Where undo exists, is it discoverable in the
  moment it is needed?
- Does the flow ever obstruct exit — no visible close, a modal without
  Escape, a step with no back?

## 6. Attention and defaults

- Do defaults favour the persona or the business? State which, concretely.
- Is anything auto-enabled on the persona's behalf (notifications, visibility,
  data sharing) with no in-flow notice?
- Does the screen use badges, dots, or counts to manufacture return visits
  where nothing actionable happened?

## How to report findings from this lens

Two disciplines, because this lens carries the highest risk of over-reading:

- **Describe the mechanism, not the motive.** "The decline link is 11px grey
  on white beside a filled 16px primary button" is evidence. "This is designed
  to trick users" is an accusation the screenshot cannot support. State what
  is on screen and what it does to the persona's choice; let the reader draw
  the intent.
- **Distinguish pattern from consequence.** A mildly asymmetric layout on a
  newsletter prompt and a hidden recurring charge are not the same severity.
  Rate by what the persona loses if they act wrongly — money, privacy, or
  reversible annoyance.
