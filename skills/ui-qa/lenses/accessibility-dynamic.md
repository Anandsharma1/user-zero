# Lens: Dynamic accessibility

**Load when** the charter makes an accessibility claim beyond the spine's
keyboard-and-contrast floor, or when the surface has overlays, live regions,
drag interactions, zoom-sensitive layout, or authentication.

The spine's §12 covers the always-on floor: keyboard traversal, visible focus,
accessible names, landmark structure, reduced motion. This lens covers the
requirements that only appear once the interface *moves* — and that automated
scanners systematically miss, which is why they belong to a human evaluator.

An automated scanner should also run. This lens does not replace it; it covers
what a scanner cannot see.

## 1. Focus over time

- When an overlay (modal, drawer, menu, popover) opens, does focus move **into**
  it, and is focus trapped inside while it is open?
- On close, does focus return to the control that opened it? Losing focus to the
  document start is disorienting and easy to miss visually.
- After content is inserted or removed (a row deleted, a step advanced), where
  does focus land? Focus on a removed element is lost focus.
- Is the focused element ever **obscured** by a sticky header, footer, or
  floating panel when tabbing through? Scroll through a long form by keyboard
  and watch for the focused field disappearing under a sticky bar.
- Is focus order still visual order after dynamic content changes?

## 2. Announcement of change

Judgeable without a screen reader by asking: *if I could not see this change,
would anything tell me it happened?*

- Do asynchronous outcomes (saved, failed, filtered, loaded) exist anywhere in
  text, or only as a colour change, a spinner disappearing, or a toast that is
  purely visual?
- Do status messages appear in a region that persists long enough to be read,
  and are they text rather than an icon alone?
- Does a form's error state have a text announcement path (a summary, a status
  line), or only red borders?
- Do progress and count changes ("3 of 12 loaded", "8 results") appear as text?
- Is anything announced *too much* — a live region on a rapidly changing value
  would be a stream of noise.

## 3. Zoom and reflow

- At **200% browser zoom**, is all content and functionality still available,
  with no loss of information? Test it; do not assume the responsive layout
  covers it.
- At 400% zoom or an equivalent narrow viewport, does content **reflow** into a
  single column without requiring two-dimensional scrolling? Horizontal scroll
  on the page as a whole is the failure; contained scroll on a wide table is
  acceptable.
- Does text remain readable and unclipped when text size alone is increased
  (a fixed-height container with `overflow: hidden` clips it)?
- Do sticky elements consume so much of a zoomed viewport that little content
  remains?

## 4. Pointer alternatives

- Is every **drag** interaction (reordering, sliders, resizing, drawing) also
  achievable with a single-pointer action or the keyboard? A drag-only
  interaction excludes users who cannot drag.
- Are hover-only affordances (tooltips, row actions, truncation reveal)
  reachable by keyboard and touch, and do hover-revealed contents stay visible
  long enough to move the pointer into them?
- Are gesture-only actions duplicated as visible controls?
- Are there any targets so small or so tightly packed that precision aiming is
  required (spine §7, and here specifically for the icon-only clusters that
  appear in table rows)?

## 5. Authentication and re-entry

- Does signing in require a cognitive test — solving a puzzle, transcribing a
  code from memory, retyping something the browser could supply? Is there an
  alternative path?
- Does the flow permit paste into every field, including one-time codes? Paste
  blocking is a common and avoidable barrier.
- Is information the persona already provided requested again within the same
  flow, without an option to reuse it?
- Are password managers and autofill able to work with the fields?

## 6. Structure under change

- After navigation within a single-page app, does the page title change, and is
  the new view's heading structure coherent — or does the persona land in a view
  whose heading is still the previous page's?
- Do dynamically added regions carry the same landmark and heading discipline as
  server-rendered ones?
- Are icon-only controls named, and does the name say the **action** ("Delete
  invoice") rather than the glyph ("trash")?
- Do error and empty states carry headings, so a non-visual reader can find them
  in the structure rather than by reading everything?

## Reporting from this lens

- Say what you tested with and what you did not. "Keyboard only, no screen
  reader" is honest and useful; implying a screen-reader pass you did not run
  is not.
- Where a check needs assistive technology you do not have, mark it **needs AT
  verification** with the specific check named, rather than guessing.
- Accessibility barriers that exclude a user from completing a task are `high`
  severity or above regardless of how many users they affect — reach belongs to
  priority, not severity.
