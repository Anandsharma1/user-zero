# Lens: Resilience and continuity

**Load when** the surface holds a session, unsaved work, long-running
operations, or data that other people can change while the persona is looking
at it.

The spine's §9 covers whether a single state is rendered honestly. This lens
covers what happens *between* states over a real session: expiry, disconnection,
interruption, and concurrency. These are the defects that cost the persona work
they cannot get back, so this lens produces high-severity findings out of
proportion to its size.

## 1. Session lifetime

- What does expiry look like? Provoke it if the profile allows (or wait it out
  on a long-running surface). Does the persona get a warning before it happens,
  or discover it by having an action rejected?
- On expiry mid-task, is unsaved work preserved through re-authentication and
  restored afterwards — or silently discarded?
- After re-authentication, does the persona land back where they were, or at a
  generic home?
- Does an expired session ever *look* live — stale data rendered as current,
  controls that appear active but will fail?

## 2. Connectivity

- On a dropped or slow connection, does the screen say so plainly, keep the
  persona's input, and offer retry without re-entry?
- Is an **optimistic update rolled back honestly** when the request fails, or
  does the screen keep showing a success that never happened? This is the
  highest-severity pattern in this lens: it makes the product lie.
- Does a retry risk duplicating the operation, and is there anything preventing
  that (idempotency signalled to the persona, a disabled state, a confirmation
  that the first attempt failed)?
- On reconnect, does the view refresh, or sit stale with no indication its data
  is old? Is there a "last updated" anywhere?

## 3. Interruption

- Backgrounding, tab switch, screen lock, then return: is state intact?
- Reload mid-task: is anything warned about before it is lost?
- Browser Back out of a partially complete flow and forward again: intact, or
  scrambled?
- Cancel midway through a long operation: does cancelling actually stop it, and
  does the screen say what state things were left in? A "cancelled" that leaves
  a half-applied change is worse than no cancel at all.
- Closing a drawer or modal mid-edit: silent discard, or a prompt?

## 4. Long-running operations

- Can the persona leave the page and come back to find the operation's outcome,
  or is progress bound to the tab that started it?
- Is the operation's terminal state (succeeded / failed / partially applied)
  reported unambiguously, including on return?
- Is a queued operation distinguishable from a running one, and a stalled one
  from a slow one?
- If it can fail partway, does the screen say **what was and was not applied**?
  Partial application reported as one word is a data-honesty defect.

## 5. Concurrency and staleness

- If another actor changes the same record, what does the persona see — a
  conflict warning, a silent overwrite, or their own stale view saved over the
  newer one? Last-write-wins with no notice is a defect worth stating plainly.
- Are lists and detail views live, polled, or static, and does the persona have
  any way to tell which?
- Does a stale view allow an action whose precondition no longer holds, and is
  the resulting rejection explained in terms the persona can act on?
- After an action based on stale data, does the screen resynchronize?

## 6. Degradation

- With a dependency unavailable (an external provider, an optional service),
  does the affected region degrade locally and say why, or does the whole screen
  fail?
- Are partial results marked as partial, with what is missing named?
- Does anything render a dependency failure as a *value* — an empty list that
  means "we could not ask", a `0` that means "unknown"? Provoke this if you
  can; it is the exact form of dishonesty the harness exists to catch.
