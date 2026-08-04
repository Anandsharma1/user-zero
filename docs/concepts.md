# Concepts: harness, profile, charter, oracle, lens

The words this project uses, in plain terms, with one example carried all the way
through.

## The one-minute version

| Term | What it is | How many |
|---|---|---|
| **Harness** | All the machinery *around* the reviewer: starting the app safely, deciding what must be covered, keeping the fresh-eyes pass honest, demanding proof, measuring itself | one, shipped |
| **Evaluator** | The reviewer itself — the `user-zero` agent that actually looks at your screens | one, shipped |
| **Spine** | The reviewer's general skill: layout, hierarchy, tables, navigation, honest states, accessibility | one, always loaded |
| **Lens** | Extra expertise for a *kind* of screen — forms, charts, AI output, dark patterns | 10, you pick per feature |
| **Profile** | What's true about **your product**: how to start it, who your users are, your wording and formats, where your specs live | one, you write it once |
| **Charter** | One **testing mission**: which screens, as whom, and the question to answer | one per feature, you write them |
| **Oracle** | A **source of truth** to check a claim against — a spec, an API response, a database row | a few per charter |

Two of those you write (**profile**, **charters**). The rest ships.

---

## What "harness" means

A harness is everything that surrounds a worker to make their output
trustworthy. Here, the worker is an AI agent looking at your UI. Left alone, such
an agent will happily produce a confident, plausible, unverifiable list of
opinions. The harness is what stops that:

- it **starts the app properly** and refuses to test a half-started one
- it **decides what must be covered** before the reviewer starts, so the reviewer
  can't quietly shrink its own scope
- it **keeps the fresh-eyes pass ignorant** — no specs, no source — because
  confusion is only real evidence when it comes from someone who doesn't know the
  answer
- it **demands proof**: a screenshot, the exact screen, the user consequence, a
  specific fix
- it **makes you reproduce** a defect before it counts
- it **checks its own paperwork** mechanically and fails the run if anything is
  missing
- it **measures itself** against known bugs before you're allowed to trust it

The evaluator supplies judgement. The harness supplies the reasons to believe it.

One framing to keep in mind throughout: this is a **generic explorer**, not a
test suite. Your test suite asserts the specific things you already thought of,
is written per product, and stays your regression backbone — built separately,
as it should be. This agent brings generalized UI/UX expertise (the spine and
lenses are industry knowledge: Nielsen, Gestalt, WCAG, design-system pattern
rules) to *any* product, and the profile/charter layer is the thin adapter that
points that expertise at yours. Its job is to explore and assess — to find the
problems nobody wrote an assertion for — and its confirmed defects then flow
*into* your test suite as pinned regressions, not the other way around.

---

## The easiest analogy: you're hiring a tester

- **Profile** = the onboarding doc you'd give *any* new tester. How to run the
  app, what we call things, where the specs are, which database never to touch.
  Written once.
- **Charter** = the ticket you hand them this morning. "Go through checkout as a
  first-time shopper. Tell me if they know what they'll be charged."
- **Oracle** = what you point at when they ask *"well, what **should** it say?"*
- **Lens** = specialist training you ask them to bring today. "It's a form, so
  bring your forms checklist."
- **Spine** = their general skill. They always have it; you never ask for it.

---

## Why these are separate things

Two questions sort all of them:

|  | **About your product** | **About how to review** |
|---|---|---|
| **Written once** | **Profile** | **Spine** (always on) |
| **Per feature** | **Charter** + its **oracles** | **Lenses** (you pick) |

This table is also *why the harness works the way it does*. The right column is
knowledge a reviewer legitimately has — a human expert doesn't forget how tables
should be aligned when handed an unfamiliar app. The left column is knowledge a
first-time user would **not** have.

So the two passes fall straight out of it:

- **Pass A** (fresh eyes) gets the right column only — spine plus whichever
  lenses you named. No profile facts, no specs, no expected values.
- **Pass B** (informed) gets the left column, and can now check whether things
  are actually correct.

The A-before-B ordering stops being an arbitrary rule and becomes a
consequence of the table.

If a fact would still be true on a completely different product, it belongs on
the right. If it's true only of yours, it belongs on the left.

---

## Where each piece comes from, and what happens when things change

The table above says what each piece *is*. This one says who writes it, where
it lives, and how it evolves. Everything here is a file you can open, read, and
edit — nothing is regenerated invisibly at run time.

| Piece | First version comes from | Lives at | When your product changes |
|---|---|---|---|
| **Profile** | the **onboarding procedure**: two agent roles — one reads product docs and the UI surface, the other reads run mechanics and test infrastructure — draft it together; **a human approves it** before any run claims authority | `qa/product-explorer/PROFILE.md` | edit it by hand, or re-run onboarding for a major revision; it is a document, not a cache |
| **Charter** | you copy the template, **or** `/ui-qa explore <route>` drafts one by reading the spec, API schemas and code — then stops for your review | `qa/product-explorer/charters/<name>.md` | run `/ui-qa refresh <charter>` — a drift audit that re-derives expectations, compares three ways (old dossier, fresh dossier, charter), and proposes amendments **classified by direction**: spec moved → oracle stale, amend; only code moved → the oracle has teeth, run the charter and let the mismatch surface. Nothing updates itself silently, and code never rewrites an oracle |
| **Oracles** | picked by whoever writes the charter, from the profile's oracle map and (in `explore` mode) the drafted expectations dossier | inside the charter, §7 | amended with the charter, same review step |
| **North-star question** | the charter author — you, or `explore`'s draft that you approve | inside the charter, §2 | usually stable; it is the feature's purpose, not its implementation |
| **Journeys** | the spec's user journeys where they exist; otherwise the surface's visible affordances (`explore` derives them); the author **trims** | inside the charter, §5 | new journeys arrive as proposed amendments, not silently |
| **Lenses** | ship with the harness — they are industry knowledge, not product knowledge | `skills/ui-qa/lenses/` | grow **upstream**, via harness upgrades, when a whole *class* of concern is missing (that is how four of the ten were added). Your product never adds lenses; your charters just name them |
| **Spine** | ships with the harness | `skills/ui-qa/references/ux-evaluation-taxonomy.md` | same — upstream only |

Three rules worth pulling out of that table:

1. **Generated once, read every run, inspectable always.** The profile is not
   re-derived each time user-zero runs — that would be slow, drifting, and
   unauditable. It is drafted once (by agents reading your docs and code),
   frozen by human approval, and then simply *read*. If it says something wrong,
   you open the file and fix the line.
2. **`explore` can draft, only a human can approve.** The agent is good at
   sifting a spec, an API schema, and the code to propose journeys and oracles.
   It is explicitly forbidden from treating the code as proof of its own
   correctness (the *anti-circularity rule*: "the component renders X" is never
   evidence that X is right — code-derived expectations may support
   *consistency* findings only). And a draft charter or profile authorizes
   nothing until someone signs it.
3. **Nothing self-updates.** When you enhance a feature and run its charter, the
   run will *find* the mismatch — journeys that no longer complete, oracles that
   no longer hold — and report it. Updating the charter is then a proposed,
   reviewable diff (`/ui-qa explore <target>` again), not a side effect of
   running.

### Personas: who is used when

The **profile** lists the personas that exist (§5) — think of it as the cast.
Each **charter** names which one Pass A embodies (§1) — one persona per run,
because fresh eyes belong to *someone in particular*. Different charters
naturally pick different personas: your import flow wants the first-timer, your
dense analytics screen wants the returning analyst.

You do not choose at run time and it does not run all of them. If you *want*
several viewpoints on the same mission, that is the explicit cohort mode —
`/ui-qa <charter> --cohort novice,expert` — which runs one independent fresh
Pass A per persona and then compares, with its own rules about what agreement
does and does not prove.

---

## End to end: an online store

Imagine a small e-commerce app. You want to know whether checkout is any good.

### Step 1 — Write the profile (once, for the whole store)

Not about checkout. About *the store*.

```markdown
## 1. Product summary
An online store. Shoppers browse, add to a basket, and pay.
Frontend the explorer drives: http://localhost:3000

## 2. Bring-up & health gate
npm run dev:store
Health gate: GET /health returns 200 AND the homepage renders 3 product cards.

## 3. Isolation mechanism
Checkout writes orders. Copy orders.db to a snapshot, point the app at the copy
via ORDERS_DB, and prove it: /debug/config must report the snapshot path.
Marker check: place one test order, confirm the row is in the snapshot and NOT
in the real orders.db.

## 5. Personas
first-time-shopper  — never used this store; knows how online shops work
returning-customer  — has an account and a saved card; wants speed

## 6. Vocabulary & formats
Say "basket", never "cart". Money always shows the currency symbol and 2
decimals (£12.50). Dates use a month name (4 August 2026). A missing price
shows "Price unavailable" — never £0.00.

## 7. Oracle map
| Document | Authoritative for | Traps |
| docs/checkout-spec.md | what checkout must do | only §3–5 are assertable; §6 is a wishlist |
| docs/order-states.md | order lifecycle | "pending" means payment authorised, NOT captured |
| GET /api/basket | the true basket contents and totals | includes tax; the UI must add nothing |

## 8. Suppression sources
The known-issues board. Anything open there is cited, not re-reported.

## 10. Adapter & viewports
playwright-mcp. desktop 1440×900, mobile 390×844.
```

You write this once. Every future charter reuses it.

### Step 2 — Write the charter (one mission)

```markdown
# Charter — checkout

## 1. Mission & persona
Someone who has picked a product tries to buy it and needs to know exactly
what they will be charged before they commit.
Persona: first-time-shopper

## 2. North-star question
Before pressing Pay, does the shopper know the full amount that will leave
their account, and what it is made of?

## 4. Isolation class
state-mutating — this creates orders. Allowed: place test orders in the snapshot.

## 5. Primary journeys
1. Add an item to the basket and reach checkout.
2. Enter a delivery address and choose a delivery option.
3. Apply a discount code.
4. Pay with a card that will be declined, then recover.
5. Pay successfully and confirm the order.

## 6. Pass-A brief
Focus: data presentation, trustworthiness, user friction.
lenses: [forms-and-validation, persuasion-and-dark-patterns]

## 7. Pass-B oracles
Functional:
1. Applying a valid discount code changes the total shown.
2. A declined card leaves the basket intact and the order uncreated.

Data correctness:
1. The total shown equals items + delivery + tax from GET /api/basket.
2. Currency and decimals follow PROFILE §6 everywhere money appears.

Recovery/error:
1. Card declined — the message says what to do and preserves the address.
```

Note what the charter is **not**: it isn't a list of 40 assertions. Four
journeys, four oracles. The reviewer explores the rest.

### Step 3 — The run, and who found what

This is the part worth studying: each concept produces a *different kind* of
finding.

**The spine found** (general reviewing skill, no product knowledge needed):

> A promotional banner is visually louder than the order total. The most
> important number on the screen is not the most prominent thing on it.

> Delivery options are three choices hidden inside a dropdown. Three mutually
> exclusive options should all be visible as radio buttons.

**The `forms-and-validation` lens found** (only because you named it):

> After a declined card, every address field is empty. The shopper must retype
> everything to try a different card.

> Card errors appear only in a summary at the top of the page, and focus stays
> in the card field, so a keyboard user gets no signal that anything failed.

**The `persuasion-and-dark-patterns` lens found** (same — only because named):

> Express delivery (+£4.99) is pre-selected. The cheaper standard option
> requires an action to choose.

> The newsletter decline reads "No thanks, I don't like saving money."

**The oracles found** (impossible without a source of truth):

> The page shows £42.50. `GET /api/basket` returns items £37.51, delivery £4.99,
> tax £0.00 — total £42.50 — but the page renders the delivery line as "Free".
> The number is right and the breakdown lies about why.

**The profile made three things possible** that nothing else could:

- The reviewer knew to check for a currency symbol and two decimals, because
  §6 says so — that's a *product* rule, not a general one.
- One finding (the delivery dropdown) was already on the known-issues board, so
  it was **cited, not re-reported** — §8.
- The run created real orders safely, because §3 said how to snapshot and how to
  *prove* the app was using the copy. Without that, this charter should never
  have run at all.

**The persona shaped everything.** A `returning-customer` with a saved card would
never have touched the address form, and would have found none of the form
findings — but might have found that their saved card isn't offered until step 3.
That's a different charter.

### Step 4 — What the harness did around all of that

- started the store and refused to continue until the health gate passed
- snapshotted the orders database and verified the running app was pointed at
  the copy, then placed a marker order to prove it
- built the required checklist — 5 journeys × 2 viewports × the states that
  matter (normal, loading, empty basket, payment error) — **before** the
  reviewer started
- ran Pass A in a fresh session with the packet only, then **locked and hashed**
  that report before Pass B opened a single oracle
- sorted the findings: the delivery-line lie is a **product defect**; the
  banner-versus-total problem is an **experience opportunity**; a slightly
  cramped mobile summary is an **observation**
- reproduced the defect from a clean browser before it counted
- checked its own paperwork and would have failed the run for a missing
  screenshot or an unexplained gap in the checklist
- labelled the whole thing *harness calibration* — because this charter hasn't
  been calibrated yet, so it isn't allowed to say "checkout is ready"

### Step 5 — Next time

The profile is done forever. Adding coverage for the returns flow is one new
charter — about 50 lines. Moving the whole harness to a different product is one
new profile.

---

## Where `glance` fits

`glance` is the same evaluator with the left column of the 2×2 removed:

```
glance   = spine (+ lenses you name)                     ← reviewer knowledge only
charter  = spine + lenses + profile + oracles            ← everything
```

On the checkout example, `glance` would have found the banner-versus-total
problem, the dropdown, the pre-selected express delivery, the confirmshaming, and
the wiped address form — most of the list. It could not have found the
delivery-line lie, because that needed `GET /api/basket`. It would instead have
said:

```
needs_oracle: yes — "Free" delivery is shown; cannot confirm whether a delivery
fee is actually being charged without the basket API
```

Which is a useful thing to hand someone. That's the mode's real output: a
shortlist of what a charter should verify.

One refinement: if a profile *does* exist, glance borrows its **broad** rules —
the §6 vocabulary and format conventions ("money shows £ and two decimals",
"never render a missing value as 0") — and judges against them directly,
because those are rules about how things should *appear*, not about which value
is right. It still never loads the oracle map or anything per-feature. So on
the checkout example, "£0.00 where the price is unknown" becomes a direct
finding citing the store's own convention, while the delivery-line lie still
needs a charter.

---

## The overloaded word: "oracle"

In the simplest terms: **an oracle is anything that lets you say "this is what
it *should* be."** A spec section, an API response, a database row, a stated
formatting rule. A charter's oracles are then the handful of specific
assertions you make against those sources — "the total shown must equal the
API's total." No oracle, no correctness verdict; that is the whole boundary
between what `glance` can and cannot say.

Beyond that, it gets used two ways, worth separating:

1. **The oracle map** (profile §7) — the *library*. Which documents and endpoints
   are trustworthy, and the traps in using them ("only §3–5 are assertable").
2. **A charter's oracles** (charter §7) — the *few books you open today*. The
   specific checks for this feature.

Charters cap oracles at 3–4 per group deliberately. A charter with 20 checks
turns the reviewer into a checklist-runner and it stops finding anything you
didn't already suspect. Exploration is the point; the oracles are there to catch
the handful of things exploration cannot judge.

---

## Two confusions worth naming

**"Profile or lens?"** Ask: would it still be true on a different product? If
yes, it's a lens (or the spine). *"Money shows £ and two decimals"* is a profile
fact. *"An ambiguous all-numeric date is bad"* is reviewer knowledge.

**"Why not load every lens all the time?"** Two reasons. The reviewer has to fit
its expertise alongside the mission with room left to think. And a lens invites
findings in its territory whether or not the territory has problems — load the
motion lens onto a static price table and you'll get motion findings about a
screen that correctly has none. That gets measured against the harness.

---

## Everything else, briefly

| Term | Meaning |
|---|---|
| **Pass A** | The fresh-eyes pass. Knows nothing about your product. Its report is hashed so a later pass can't rewrite it. |
| **Pass B** | The informed pass. Loads oracles and checks correctness. May *explain* a Pass-A confusion, never delete it. |
| **Packet** | The exact, small set of facts Pass A is given. If it isn't in the packet, Pass A doesn't get it. |
| **Exit interview** | The last thing Pass A writes, in the persona's own voice: could I answer the question, how hard was each task, would I trust this. |
| **Coverage matrix** | The checklist of what must be looked at, written *before* the reviewer starts, then filled in. Gated. |
| **Gate** | `verify-run.sh`. Checks the run's paperwork mechanically and fails it if anything is missing. |
| **Finding classes** | *Product defect* (broken, dishonest, wrong), *experience opportunity* (confusing but not broken), *observation* (minor or uncertain). |
| **Severity vs priority** | Severity = how bad it is on its own. Priority = how soon to fix it. Kept separate so a rare data-corruption bug stays critical on a quiet page. |
| **Calibration** | Measuring the harness itself: plant known bugs, check it finds them; show it approved-good screens, check it stays quiet. Seven scores with pass marks. |
| **Control / exemplar** | A planted known bug (negative control) / a screen a human has approved as fine (positive control). |
| **Isolation class** | Whether a charter only looks (`observation-only`), writes data (`state-mutating`), or calls paid services (`external-provider`). Decides how carefully it must be run. |
| **Suppression** | Citing a known-open issue instead of re-reporting it. A *fixed* bug reappearing is the opposite — that's a regression. |
| **Verdict lane** | Whatever process in your project decides whether a defect is real. The harness hands it evidence; it makes the call. |
| **Cohort** | Running the same charter as several personas and comparing. |
| **Dossier** | Notes `explore` writes when inventing a charter for a screen nobody has covered yet. |
