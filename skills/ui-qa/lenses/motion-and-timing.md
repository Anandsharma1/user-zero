# Lens: Motion and timing

**Load when** the surface animates, transitions between states, streams,
polls, or has perceptible latency.

Motion is not decoration with a duration; it is a claim about causality — this
came from there, that is still happening, this replaced that. This lens checks
whether each animation makes a true claim, and whether the product's timing is
honest about what the system is doing.

Do not load this lens on a static surface. A motion lens on a static reporting
table will produce motion findings about a screen that correctly has none.

## 1. Purpose — what is each animation for?

For every animation you can see, name its job. The legitimate jobs are:

- **Continuity** — showing that this screen came from that element (a drawer
  from the row that opened it), so the persona does not lose their place.
- **Attention** — directing the eye to a change it would otherwise miss.
- **Feedback** — confirming an input was received.
- **Explanation** — showing a relationship or a reordering as it happens.

An animation with no job is a cost with no benefit — flag it, with the delay
it adds. Be specific and be sparing here; "too much animation" without a named
element and a measured effect is generic commentary.

## 2. Duration and restraint

- Do transitions feel instant where they should be (state changes on a control:
  under ~100ms), quick for small movements (~150–250ms), and only slower for
  large ones (a full-screen transition, ~300–400ms)? Anything past ~500ms on a
  routine, repeated action is friction the persona will feel on the tenth use.
- Is the same kind of transition the same duration everywhere?
- Does anything animate on *every* render — a list that re-animates each time
  it is revisited, a number that counts up every poll — turning a one-time
  delight into a recurring tax?
- Does motion block interaction? Can the persona click through or interrupt a
  transition, or must they wait it out?

## 3. Timing honesty (the important half of this lens)

- Is there feedback within ~100ms of every input, even when the work takes
  longer? Silence after a click is indistinguishable from a dead control.
- Does the product distinguish **working** from **stuck**? An indeterminate
  spinner makes no claim about progress; past a few seconds the persona cannot
  tell a slow response from a hang. Check what the screen communicates at 1s,
  5s, 15s, and 60s, and report the point at which a real user would give up or
  retry.
- Where duration is knowable, is it shown (determinate progress, step counts,
  "about a minute")? Where it is not knowable, does the copy say so honestly
  rather than showing a bar that fills to 90% and waits?
- Are skeleton screens honest — do they resemble the content that actually
  arrives, and do they not persist so long they read as broken layout?
- Do artificial delays exist (a spinner shown for a fixed minimum, a success
  animation gating the next step)? Manufactured waiting is a finding.
- On polling surfaces: does the persona know the screen is live, when it last
  updated, and whether "no change" means nothing happened or nothing was
  fetched?

## 4. Transitions that lie

- Does a transition imply a spatial relationship that does not exist — a
  drawer that slides in from the right but is closed by a control on the left?
- Does anything move under the persona's finger or cursor? Late-loading
  content that shifts a button just as it is clicked is a defect with a real
  cost — check for layout shift after first paint at each declared viewport.
- Does a success animation play before the operation actually succeeds? A
  checkmark that appears on request rather than on response is dishonest
  state, and it belongs in the finding list as such, not as a motion nit.
- Do enter/exit animations agree? An element that slides in and vanishes
  abruptly breaks the causal story.

## 5. Accessibility and comfort

- Does the product respect `prefers-reduced-motion` — and does respecting it
  mean *reduced*, not *broken*? Check that reduced-motion mode still conveys
  the state changes the animation carried (cross-fade instead of slide, not
  nothing at all).
- Is any large-area, parallax, or continuous motion present that can trigger
  vestibular discomfort? Note it whether or not reduced-motion is honoured.
- Does anything flash, blink, or loop rapidly (a seizure risk above ~3
  flashes/second)? Report immediately at high severity.
- Is auto-playing motion (carousels, video, marquees) pausable, and does it
  stop on focus?
- Does focus survive a transition — after a drawer opens does focus move into
  it, and does it return to the trigger on close?

## 6. Reporting motion findings

Motion is the hardest thing to evidence with a still screenshot. Compensate:

- Capture the state **before** and **after**, and describe the movement between
  them in words.
- Where the finding is about duration, say how you established it (counted
  against an observable event, measured against a network request, or
  perceived) and mark perceived timings as approximate.
- Where the tooling cannot capture it, say so and mark the finding
  "needs video verification" rather than dropping it or overclaiming.
