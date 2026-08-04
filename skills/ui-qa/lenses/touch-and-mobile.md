# Lens: Touch and mobile

**Load when** the product is used on phones or tablets, or when the charter
declares a small viewport and the surface is expected to be genuinely usable
there rather than merely non-broken.

The spine already checks target sizes and responsive layout. This lens adds
what changes when the input device is a thumb, the screen is held in one hand,
the network is unreliable, and the session can be interrupted at any moment.

Note the honest limitation up front: a desktop browser at a phone viewport is
a *proxy* for a phone, not a phone. It cannot show you real touch accuracy,
system gestures, on-screen-keyboard behaviour, or performance on a mid-range
device. Findings from a resized desktop browser are legitimate but must say
that is what they are; anything that needs real hardware is reported as
"needs device verification."

## 1. Reach and posture

- Are the most frequent actions in the comfortable thumb zone — lower and
  centre of the screen — or in the top corners?
- Is anything destructive placed where a thumb naturally rests or where a
  reach-stretch lands?
- Can the primary journey be completed one-handed, or does it require both
  hands or repositioning the grip?
- Do primary actions stay reachable when content is long — sticky where it
  matters, or stranded at the bottom of a scroll?

## 2. Targets and spacing under a fingertip

- Are tap targets at least ~44×44px *including* their spacing from neighbours?
  A 44px target flush against another 44px target is still a mis-tap.
- Are adjacent targets with different consequences separated (delete beside
  edit, decline beside confirm)?
- Are tap targets the whole visual element (the full row, the full card), or
  only the small text inside it?
- Do dense tables or lists offer a touch-appropriate density, or is a desktop
  row height carried down unchanged?

## 3. Gestures

- Is every gesture-only action also available as a visible control? A swipe-to-
  delete with no button is undiscoverable and unusable with assistive tech.
- Are gestures discoverable at all — is there any signifier that swiping,
  long-pressing, or dragging does something?
- Do custom gestures conflict with system ones (edge swipes for back,
  pull-down for notifications, pinch)?
- Is scroll ever hijacked — nested scroll areas that trap the gesture,
  horizontal carousels that capture vertical intent, infinite scroll that
  makes the footer unreachable?

## 4. Input and the keyboard

- Do fields declare the right keyboard type (numeric for amounts, email for
  email)? A numeric field that opens a full alphabetic keyboard is a finding.
- When the on-screen keyboard appears, is the focused field still visible, and
  is the submit control still reachable?
- Are autocomplete/autofill hints present for name, email, address, and
  payment fields?
- Is anything hover-dependent — a tooltip, a menu, truncation-on-hover — with
  no touch equivalent? On touch there is no hover; that content is simply
  unreachable.

## 5. Interruption and unreliability

- If the app is backgrounded mid-task and returned to, is state preserved?
- On a slow or dropped connection, does the screen say what happened and keep
  the persona's input, or reset the form?
- Are optimistic UI updates rolled back honestly when the request fails, or
  does the screen keep showing a success that did not happen?
- Does a rotation change lose state or break layout?

## 6. Platform conventions

- Do navigation patterns match platform expectation (back behaviour, sheet vs
  full-screen, tab bar position), or is a desktop pattern transplanted?
- Does browser Back do the sensible thing in a mobile web app with in-app
  navigation — and does it ever exit the app when the persona expected to go
  up one level?
- Is anything sized in a way that triggers browser zoom on focus (font-size
  below 16px in inputs on iOS Safari is the classic)?
- Are safe areas respected — content not under a notch, a home indicator, or a
  browser chrome overlay?
