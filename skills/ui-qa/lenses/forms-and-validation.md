# Lens: Forms and validation

**Load when** the surface collects input of any consequence — a multi-field
form, a multi-step flow, anything whose rejection costs the persona re-work.

The spine covers component choice (§3), control behavior (§4), and labels
(§10). This lens covers what happens across a whole form over time: when
validation fires, what an error says, where focus goes, and whether the
persona's typing survives.

## 1. Before input

- Is every field labelled with a persistent visible label, not a placeholder
  that vanishes the moment typing starts?
- Are **required and optional** fields marked unambiguously and consistently
  (mark the shorter set; do not mix an asterisk convention with the word
  "optional" on one form)?
- Does each non-obvious field carry its hint *before* the input, where it can
  prevent the error, rather than after it as a correction?
- Is the expected format shown for anything constrained (date, identifier,
  length, allowed characters) — or better, is the constraint enforced by the
  control so the error cannot happen?
- Are autofill/autocomplete attributes working for name, email, address, and
  payment fields? Try the browser's own autofill and report what breaks.

## 2. Timing of validation

- Does validation fire **on blur or on submit**, not on every keystroke while
  the field is still incomplete? An email field that shows "invalid" at the
  first character is punishing the persona for typing.
- Once a field has been corrected, does its error clear immediately, or does it
  persist until the next submit?
- Is any validation server-side only, so the persona learns of a problem after
  a full round trip? Note the delay and whether anything told them to wait.
- Does the submit control's state tell the truth — enabled when submission will
  actually be attempted, and disabled controls explaining what is missing?
  A permanently-disabled submit with no explanation of why is a dead end.

## 3. Error presentation

- Is each error shown **at its field**, adjacent and visibly associated?
- For a form with more than a handful of fields, is there also a **summary at
  the top** listing what failed, with each entry linking to its field? Long
  forms where the only signal is inline errors below the fold leave the persona
  hunting.
- On submit failure, does focus move somewhere useful — the summary or the
  first invalid field — or does it stay where it was, leaving a screen-reader
  or keyboard user unaware anything happened?
- Do error messages say what is wrong **and what to do**, in the persona's
  words? "Invalid input" fails; "Enter the date as DD Month YYYY" passes.
- Is the error signalled by more than colour (icon, text, border weight)?

## 4. Preservation of work

The highest-severity findings in this lens live here, because the cost is the
persona's time and they cannot get it back:

- After a failed submit, is **every** entered value still present — including
  selects, radios, checkboxes, file selections, and rich-text content?
- After a session expiry or auth redirect mid-form, is the work preserved or
  silently discarded? Provoke this if the profile allows it.
- After browser Back out of a form and forward again, is state intact?
- Does an accidental refresh lose everything with no warning? Is there any
  draft-save, and if so does the persona know it exists?
- On a multi-step flow: can the persona go back a step without losing the
  current step's entries, and does re-entering a completed step show what they
  chose?

## 5. Multi-step flows

- Is progress shown — which step, how many, what remains?
- Is each step's scope coherent, or are unrelated questions bundled to reduce
  the step count?
- Can the persona review everything before the final commit, and edit from that
  review without restarting?
- Is the final commit's consequence stated at the commit, not two steps
  earlier?
- Is anything re-requested that the persona already provided (WCAG 2.2 calls
  this redundant entry, and it is also just rude)?

## 6. Submission and its aftermath

- Is double submission prevented, and is the prevention visible (pressed state,
  disabled-with-spinner) within ~100ms?
- On success, is the persona told *specifically* what happened and given the
  obvious next action, or dropped on a generic confirmation?
- On partial success (some records saved, some rejected), does the screen say
  exactly which — or does it collapse into one ambiguous message? This is the
  state most often rendered dishonestly.
- Is a slow submission distinguishable from a stalled one?
