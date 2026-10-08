# UX Evaluation Taxonomy — the expert question catalog (the spine)

The always-loaded **spine**, distilled from Nielsen, Norman, ISO 9241-110,
Gestalt, WCAG, Fitts/Hick, and component guidance from Material, Apple HIG,
Carbon, and Polaris. Keep it compact enough for fresh-eyes evaluation.

This is **method, not product knowledge**, allowed in Pass A. Product
expectations belong in Pass B. Specialized concerns live in `../lenses/`;
see `../lenses/MANIFEST.md`.

Ask applicable questions as the charter's persona, from the rendered UI,
with screenshots for claims. Judgment about what matters here is part of
expertise; no question requires manufacturing a finding.

---

## 1. Layout, positioning & visual organization (Gestalt)

- **Proximity**: are related controls/facts physically grouped, and
  unrelated ones separated? Does whitespace group things that belong
  together, or accidentally split them?
- **Alignment**: do elements sit on a consistent grid? Are edges that should
  align (labels, cells, buttons, cards) actually aligned — check at each
  declared viewport, not just the authoring one.
- **Similarity/consistency**: do same-kind things look the same (all
  primary actions one style, all statuses one chip family)? Does anything
  *look* like a group member but behave differently?
- **Figure–ground / emphasis**: does the most important thing on the screen
  visually dominate? Is the answer distinguishable from supporting
  evidence, or do four equal panels bury it?
- **Reading order**: does the layout follow the natural scan (F/Z pattern,
  left-to-right, top-to-bottom for LTR locales)? Is the first thing the eye
  lands on the right thing?

## 2. Information hierarchy & density

- Correct facts first: does the screen lead with what the persona came for,
  or with metadata/plumbing?
- Progressive disclosure: is secondary detail collapsed/expandable rather
  than competing with the primary content? Is anything important hidden one
  click too deep — or anything trivial promoted?
- Density: can the persona scan and compare what the task needs? Flag both
  cramped content and sparse layouts that force pointless scrolling.
- Subtraction: what could be removed, shortened, or disclosed later to make
  this task clearer without losing needed guidance? Non-use alone is no reason
  to remove something.
- Heading quality: does every page/section heading say what the section IS
  in the persona's words (not an internal feature name)? Would the heading
  alone let a user decide whether to read the section?
- Scent: do labels/links predict what's behind them?

## 3. Component appropriateness (the pattern-choice audit)

For each interactive element, ask: *is this the right component for the
data shape and task?* Common wrong-pattern smells:

- **Select/dropdown vs radio vs searchable select vs text input**:
  ≤5 mutually-exclusive options → radio (all visible); ~6–15 → dropdown;
  many/unbounded or user-known values → searchable select or text input
  with validation. A dropdown hiding 3 options, or 200 options without
  search, is a wrong pattern.
- **Modal vs drawer vs inline vs new page**: modal = interrupt, one
  decision, no context needed behind it; drawer = contextual detail/action
  while the list stays visible; inline expansion = comparison across rows
  matters; page = a destination users deep-link/return to. Flag a modal
  that hides context the task needs, a drawer doing a page's job, or a
  destination with no URL.
- **Tabs vs accordion vs sections**: tabs = peer views, one at a time,
  labels short; accordion = independently expandable, scanning titles;
  plain sections = users read most of it anyway.
- **Toast vs inline error vs banner vs blocking dialog**: transient
  confirmation → toast; field problem → inline at the field; condition
  affecting the whole page → banner; data-loss-risk decision → dialog.
  An error toast that vanishes before the user can read/copy it is wrong.
- **Button vs link**: actions are buttons, navigation is links; a
  destructive action styled like a quiet link (or vice versa) is a defect.
- **Search box vs filter controls**: known-item lookup → search; slicing a
  visible set → filters; both needed when the set is large AND sliceable.
- **Free text vs structured picker**: dates, identifiers, enumerable values
  should be picked/validated, not typed free-form and rejected later.

## 4. Component behavior

- Every control does what it visually promises (no dead buttons, no
  enabled-looking disabled things), and every disabled control explains why.
- Hover/focus/active/loading/pressed states exist and are distinct.
- Default values are sensible and safe; the most likely choice is the
  easiest one (good defaults are the cheapest UX win).
- Destructive actions: visually distinct, physically distanced from safe
  actions, confirmed proportionally to their cost, undoable where possible
  (undo beats confirm).
- Double-submit protection, and feedback within ~100ms of any click
  (perceived response), even if just a pressed state or spinner.
- Keyboard: Tab order follows visual order; Enter/Escape do the expected
  thing in forms, dialogs, drawers; focus returns to the trigger when an
  overlay closes.

## 5. Tables & data display craft

- Column ORDER matches scan priority (identity → key judgment → detail).
- Column WIDTH fits content: no vast empty gutters next to strangled,
  truncated columns; truncation shows an affordance (tooltip/expand).
- Numeric columns right-aligned in tabular figures; text left-aligned;
  units in the header, not repeated per cell.
- Sensible default sort, visible sort state, sortable where users compare.
- Version-like/date-like values sort semantically, never lexically.
- Per-cell states: loading, unavailable ("—" or explicit label — NEVER a
  fabricated 0), error — visually distinct from real values.
- Aggregates always show their denominator/sample size next to the number;
  a percentage without its n creates false confidence.
- Row density: comfortable scanning at the declared viewports; horizontal
  scroll contained to the table, never the page.

## 6. Navigation & orientation

- **Where am I?** Active nav state, page title, and (in hierarchies)
  breadcrumbs agree with each other and with the URL.
- **Back/forward safety**: browser Back always works, returns to the
  expected place, and loses no entered state; forward/redo does not
  resubmit mutations. Missing in-app back affordances on deep detail pages
  are a finding.
- **Escape hatches**: every flow can be exited; no dead ends (a page whose
  only exits are browser chrome); every error state offers a way onward.
- **Deep-linkability**: filtered/selected/opened states that users would
  bookmark or share live in the URL; refresh reproduces the view.
- **Completeness**: can the persona reach every advertised function from
  the navigation? Is anything reachable only by knowing a URL?
- Menu breadth/depth sane (Hick's law: fewer, well-named choices beat many
  vague ones); labels are the persona's words.

## 7. Sizing, targets & real estate

- Interactive target sizes: comfortable to hit (touch ≥ ~44px, dense
  desktop rows still hit-able without precision aiming — Fitts's law);
  adequate spacing between adjacent targets, ESPECIALLY safe vs destructive.
- Above-the-fold priority: at each declared viewport, is the screen's #1
  job visible and actionable without scrolling?
- Real estate: do headers, padding, sidebars, or repeated summaries push
  task-critical content out of view or squeeze comparison columns? Wider
  viewports should reveal useful content, not just wider gaps. Keep prose
  readable (~45–75 characters per line); whitespace can serve grouping.
- Component proportionality: control sizes match their importance —
  a primary action isn't a tiny link; a rarely-used option isn't a huge
  button.

## 8. Typography, color & theme

- Typography: clear, consistent title, section, body, and caption levels.
- Borders and decoration: do thick, high-contrast, or nested boundaries
  overpower content, imply wrong grouping, or make static content look
  interactive? Judge their effect, not a universal thickness limit.
- Contrast meets WCAG AA (4.5:1 body, 3:1 large text/UI); check BOTH themes
  if the product ships more than one, and check state colors (disabled,
  placeholder) which fail most often.
- Theme consistency: every surface honors the active theme — flag
  hardcoded colors that ignore theme switch, unreadable text on themed
  backgrounds, mismatched component families (one raw-HTML control among
  styled ones).
- Color is never the only signal (success/failure also differ by
  icon/label); semantic colors used consistently (one red = danger,
  everywhere).

## 9. Feedback, state honesty & trust (Nielsen #1 + system honesty)

- System status always visible: in-flight work shows progress; slow
  operations set expectations; nothing pretends to be done before it is.
- The screen distinguishes: fact vs estimate vs unavailable vs pending vs
  rejected vs system failure — six different things that must never
  collapse into one rendering.
- Empty states say WHY empty and what to do next (first-run vs no-results
  vs error are three different empty states).
- Errors: plain language, say what happened + what to do, preserve the
  user's work, never expose internals (IDs, paths, stack traces).
- No fabricated data ever: placeholders/fixtures must be unmistakable.

## 10. Language & microcopy

- Vocabulary: can this persona understand the screen using task knowledge,
  without knowing the implementation? Technical terms belong when the task
  needs them; enum tokens and raw IDs must not substitute for useful labels.
- Brevity: does each explanation help decide or act? Name repeated prose or
  implementation detail to shorten or disclose later; preserve warnings,
  necessary guidance, and recovery steps.
- Consistent terminology: one concept = one word everywhere (a "run" here
  isn't a "job" there); consistent casing convention.
- Labels over placeholders (placeholders vanish on input); dates/numbers/
  currency in locale-appropriate, consistent formats.
- Buttons say what they do ("Run the check", not "OK"/"Submit").

## 11. Cognitive load & efficiency

- Hick's law: choices per moment are few and well-differentiated.
- Recognition over recall: users never need to remember a value from a
  previous screen — the UI carries it forward.
- Frequent tasks have short paths (count the clicks for each charter
  journey; flag needless steps, re-confirmations, re-entry of known data).
- Flexibility: power users get shortcuts (keyboard, bulk actions) without
  burying novices.

## 12. Accessibility (beyond automated scans)

- Full keyboard traversal of every journey; visible focus at all times.
- Accessible names on all controls match their visible labels.
- Landmarks/headings give screen-reader users the same hierarchy sighted
  users get from layout.
- Motion/animation is modest and respects reduced-motion preferences.

---

## The two methods that structure a pass

**Cognitive walkthrough** (per charter journey, as the persona): at every
step ask the four canonical questions — (1) Will the user know what to try
to do? (2) Will they see the control for it? (3) Will they recognize the
control as the right one? (4) After acting, will the feedback tell them
they made progress? Any "no" is a finding with the step recorded.

**Heuristic sweep** (per screen): walk sections 1–12 above plus any lens
your packet selected, asking only the questions that apply, and rate what
fails on **both** axes below.

Both methods obey the standing exploration license: if something unusual
catches your eye, follow the trail even if no question named it.

---

## Severity and priority are two different numbers

Collapsing them is how a harness ends up ranking a cosmetic flaw on a busy
screen above a data-corruption path on a quiet one. Every finding carries both.

**Severity — how bad is it when it happens?** A property of the failure alone.
Reach, traffic, and business value are explicitly excluded.

| Severity | Means |
|---|---|
| critical | data loss or corruption; wrong data presented as fact on a decision surface; a security or privacy exposure; an irreversible action taken without intent; total task failure with no workaround |
| high | task fails or completes wrongly; the screen misrepresents system state; an accessibility barrier that excludes a user entirely; a documented contract violated |
| medium | task completes but with real friction, confusion, or a workaround the persona must discover |
| low | cosmetic or minor inconsistency; no task impact |

**Priority — what should be fixed first?** Severity, then reach (how many
personas and journeys touch it), frequency (how often on those journeys),
persistence (does it recur every time or once), and remediation cost.

Two rules that fall out of the split, and that exist because they are exactly
what a single blended score gets wrong:

- **Frequency and reach never lower severity.** A rare corruption, a permission
  leak, or a wrong financial figure is `critical` on a page nobody visits.
  Being rare may lower its *priority*; it does not make it less severe.
- **Frequency and reach never raise severity above its class.** A misaligned
  label on the most-visited screen is `low` severity and possibly high
  priority. Say both; do not promote one into the other.

For experience opportunities, the value tiers (`highly-valuable` / `valuable` /
`good-to-have`) already blend both axes and are a priority judgment by
construction — which is why they are the tier reviewed by the product owner, and
why they are never interchangeable with defect severities.
