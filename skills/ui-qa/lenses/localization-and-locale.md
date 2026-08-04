# Lens: Localization and locale

**Load when** the product ships in more than one language or region, or when
the surface renders locale-formatted data (dates, numbers, currency, names,
addresses, time) even in a single locale.

Most localization defects are visible without speaking the language: they are
layout failures, formatting lies, and assumptions baked into structure. That
is what this lens checks. It does not check translation quality — that needs a
native reviewer, and saying so is a legitimate finding ("unverifiable here").

## 1. Text expansion and contraction

- Does the layout survive longer strings? German and Finnish commonly run
  30–50% longer than English; some languages run shorter and leave holes.
  Where the product exposes a language switch, switch it and re-check the
  money screens at the smallest declared viewport.
- Do buttons, tabs, chips, and table headers wrap gracefully, truncate with an
  affordance, or clip? Clipped labels with no tooltip are a defect.
- Are fixed-width containers sized to the English string? A nav item that fits
  exactly is a container that will break.
- Do headings and labels stay on one line where the design assumes one line?

## 2. Bidirectional and script support

- In an RTL locale, does the whole layout mirror — navigation side, icon
  direction, progress direction, table column order — or only the text?
  Half-mirrored screens are more confusing than unmirrored ones.
- Do directional icons (back arrows, chevrons, next/previous) flip? Do
  non-directional ones (clocks, checkmarks) stay put?
- Are mixed-direction strings (an English product name inside RTL text)
  rendered without scrambling punctuation and numbers?
- Do CJK and Indic scripts render with adequate line height, and do
  ascenders/descenders clip in tight rows?

## 3. Formatting honesty

- Dates: is the order unambiguous to the persona? `03/08/2026` is two
  different days depending on locale — either use a month name or state the
  format. Flag any bare all-numeric date on a decision surface.
- Numbers: decimal and grouping separators follow the locale (`1.234,56` vs
  `1,234.56`), and one convention is used consistently on a screen.
- Currency: symbol *and* code where more than one currency is plausible
  (`$` alone is ambiguous across at least a dozen currencies); conversion
  shown with its rate and time, never silently.
- Percentages, units, and measurement systems stated, not assumed.
- Time: does the screen say which timezone it is showing? A timestamp with no
  zone on a surface where events matter is a finding. Relative times ("2 hours
  ago") need an absolute value available on hover or nearby.

## 4. Structural assumptions about people and places

- Name fields: does the form assume first/last, a single given name, Latin
  characters, or a specific ordering? Does it break on one-word names,
  particles, or non-Latin scripts?
- Addresses: are state/province and postcode required in a form that also
  offers countries without them? Is postcode validated against one country's
  pattern?
- Phone numbers: is a country code selectable, and is validation
  country-appropriate?
- Sorting: are localized strings sorted by locale collation, or by byte order?
  Accented characters filed at the end of a list are a visible symptom.

## 5. Completeness of the localized experience

- Do untranslated strings, raw translation keys, or fallback-language text
  appear on screen? Quote them with their route — this is the highest-value,
  easiest-to-verify finding in this lens.
- Are error messages, empty states, validation text, tooltips, and email/PDF
  output localized too, or only the main UI? Peripheral surfaces are where
  localization stops.
- Does the language choice persist across navigation and reload, and is it
  reflected in the URL or user settings rather than being ephemeral?
- Are locale-dependent images, examples, and placeholder data appropriate, or
  do they carry one region's assumptions (currency in screenshots, sample
  names, holiday references)?

## 6. What to report as unverifiable

Say so explicitly rather than guessing:

- translation accuracy, tone, and register;
- cultural appropriateness of imagery, colour, and iconography;
- legal or regulatory copy requirements per region.

An honest "cannot assess from the rendered UI — needs a native reviewer for
locale X" is a useful finding that routes work to the right person. A confident
guess about a language you cannot read is not.
