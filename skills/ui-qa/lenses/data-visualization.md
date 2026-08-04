# Lens: Data visualization

**Load when** the surface renders charts, graphs, gauges, sparklines, maps, or
any graphic that encodes numbers.

A chart is an argument. This lens checks whether the argument is honest and
whether the persona can check it — both judgeable from the rendered screen
without knowing the underlying data, because a misleading chart betrays itself
in its axes, its scale, and its missing denominators.

## 1. Scale integrity

- Does a **bar chart's value axis start at zero**? A truncated baseline
  exaggerates differences, and on bars it is a straightforward defect, not a
  style choice. (Line charts legitimately zoom; they must then label the range
  clearly.)
- Is the axis range stable across comparable charts on the same screen? Two
  panels side by side with different y-scales invite a false comparison.
- Is any axis non-linear (log, or an irregular tick spacing) without saying so?
- Are dual axes present? If so, can the persona tell which series belongs to
  which — and is the crossing point of the two scales doing rhetorical work?
- Do proportional graphics scale by **area** honestly (a value twice as large is
  not a circle with twice the radius)?

## 2. Labelling and legibility

- Are both axes labelled, with **units**, and do tick labels remain readable at
  every declared viewport rather than overlapping or truncating?
- Is the **time window** stated — and does it match what the surrounding copy
  claims? "Last 30 days" over a chart of 6 weeks is a data-honesty defect.
- Is the legend present, near the data, and stable in colour assignment across
  re-renders and across sibling charts?
- Can the persona get exact values (tooltip, data labels, a table)? A chart
  whose numbers cannot be read is decoration on a decision surface.
- Is a tooltip the *only* access to values? On touch there is no hover.

## 3. Honesty about what is not there

- Are **missing periods** distinguishable from zero values? A gap plotted as 0
  is the chart version of the fabricated zero, and it is the single most common
  defect in this lens.
- Is partial or in-progress data marked (a final bar that covers three days of
  a month reads as a collapse)?
- Are aggregates shown with their **denominator or n** — a percentage line with
  no sample size, an average with no count?
- Is uncertainty represented where it exists (error bars, ranges, a stated
  confidence), or is an estimate drawn with the same visual authority as a
  measurement?
- Are outliers or clipped values visible, or silently cut by the axis range?

## 4. Encoding choice

- Does the chart type match the question? Trend over time → line; comparison of
  categories → bar; part-to-whole with few parts → stacked bar or (rarely) pie;
  distribution → histogram or box; correlation → scatter. A pie with nine
  slices, or a line joining unordered categories, is a wrong pattern in the same
  sense as a drawer doing a page's job.
- Is the visual complexity earned, or would a single number, a sparkline, or a
  small table say it better? On a dashboard the answer is often the table.
- Is anything 3D, animated on load, or rotated in a way that distorts
  comparison?
- Is the sort order meaningful and stated (by value, by time, alphabetical)?

## 5. Colour and accessibility

- Is the palette distinguishable without colour vision — differing in lightness
  as well as hue, or carrying a second channel (pattern, direct labels)?
- Do semantic colours match the product's convention elsewhere (one red =
  bad, everywhere)?
- Does a sequential scale run in a defensible direction, and does a diverging
  scale have a meaningful midpoint?
- Is there a **non-visual alternative** — an accessible table, a text summary,
  or figure description — for anyone who cannot read the graphic? A chart with
  no textual equivalent excludes a user entirely, which is a high-severity
  accessibility finding, not a nicety.
- Does the chart survive at the smallest declared viewport, or does it become an
  unreadable smear that nothing tells the persona to scroll or rotate?

## 6. Interaction

- Do zoom, brush, filter, and legend-toggle states survive Back, refresh, and
  sharing — or does the persona lose their view?
- Does the chart reflect the page's active filters, and does it say so? A chart
  ignoring a filter the persona just set is a correctness defect.
- Is a loading chart distinguishable from an empty one, and an empty one from a
  failed one?
