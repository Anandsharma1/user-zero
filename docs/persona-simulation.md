# Persona-simulated usability research: what to borrow, what to run, what to refuse

There is an active research line that does something adjacent to this harness:
LLM agents acting as *synthetic usability-test participants* rather than as
expert reviewers. It is the closest external work to `user-zero`, and it is
worth understanding precisely, because its good ideas are cheap to adopt and
its central claim is one this harness must not make.

**Verification note.** UXAgent's design below is from its repository README
and paper listing. UXCascade, PerceptUI, and UXBench are summarized from their
arXiv abstracts and pages — enough to judge the ideas, not enough to vouch for
their results. Anything marked *(abstract only)* has not been read in full.

---

## The landscape in one table

| System | What it is | Core mechanism | Where it sits relative to us |
|---|---|---|---|
| [UXAgent](https://github.com/neuhai/UXAgent) (MIT, CHI'25 EA) | Simulates usability-test *participants* at scale | Persona Generator samples weighted demographics into template profiles; dual-system (fast/slow) reasoning loop; Universal Browser Connector drives Chrome via Playwright; batch mode runs 20+ agents from `runConfig.yaml` with post-task questionnaires; outputs traces, screenshots, recordings, aggregated metrics | Same "agent drives a real browser as a persona" core. No craft taxonomy, no oracle pass, no calibration. Optimizes breadth (thousands of personas); we optimize evidentiary weight per finding. |
| UXCascade *(abstract only)* | Makes agent-generated feedback *readable* at scale | Three-level top-down analysis: patterns across persona traits/goals/outcomes → agent reasoning linked to specific issues → proposed edits with cross-persona impact measured; studied with 8 UX professionals | This is the aggregation layer we need the moment cohort mode has more than two personas. Directly informed `references/persona-cohorts.md`. |
| PerceptUI *(abstract only)* | Predicts how a *specific* persona would answer UI questions, with explanations | Two-stage training: contrastive reflection fine-tuning on human explanations, then reflective prompt evolution on the model's own errors; claims human-level realism and population-level response distributions | The ambitious version of our exit interview. Requires human-response training data we do not have. Its stated worry — that naive agents produce "superficial commentary" or model bias dressed as user response — is our generic-commentary metric, arrived at independently. |
| UXBench *(abstract only)* | Benchmarks LLMs *as UX judges* | Local-first runnable web fixtures across 10 product-surface families; **coverage-gated** browser exploration forcing evidence collection before reporting; 7 rubric dimensions; scored by whether a fixed downstream **repair agent** can improve the interface from the critique; 8 frontier models, plus blind human validation | The most immediately useful of the four. Its repair-lift protocol is a better actionability metric than any prose bar, and its coverage gate is a mechanism we lacked. |

---

## What I wired in already

Three ideas were cheap enough and clearly enough right to implement now.

### 1. Cohort mode — `references/persona-cohorts.md`

UXAgent's persona breadth, cut down to what this harness can stand behind:
run Pass A once per *profile-approved* persona in independent fresh contexts,
then aggregate on route + observed problem into universal / majority /
persona-specific / contradictory clusters (UXCascade's pattern layer, done in
prose instead of a GUI).

Two guardrails are in the file because they are the whole difference between
useful and misleading:

- **No averaging, no percentages, no population claims.** Four chosen
  viewpoints are not a sample. "3 of 4 personas were confused" describes those
  four personas and nothing else.
- **Agreement is not authority.** Four explorers on the same model share its
  blind spots, so unanimity is correlated, not independent. A universal
  finding is a strong prioritization signal, never evidence — it still needs
  reproduction and a verdict-lane disposition.

### 2. Exit interview — `references/evidence-schema.md`

UXAgent's post-task questionnaire, adapted. The expert report is written by
someone who has already rationalized the experience; the exit interview
captures the naive judgment before rationalization: the north-star answer in
the persona's words, per-journey difficulty (self-reported 1–7), trust, what
they'd tell a friend, surprises, and the point at which they'd have left.

Written before any oracle opens, hashed with the Pass-A report, never
rewritten afterwards. The valuable case is the contradiction: *every journey
completed, difficulty 6* means the product works and hurts — precisely what
scripted suites cannot see.

### 3. Actionability, and repair-lift as its strong form — `references/calibration-protocol.md`

UXBench's central insight is that a UX critique's worth is measured
downstream: can a repair agent that never saw the screen improve the interface
from the critique alone? That became a seventh calibration metric with a
threshold, plus the repair-lift protocol as its measured (rather than judged)
form — apply the recommendation blind in a throwaway branch, re-run the
charter, and count **repaired / misrepaired / unrepairable**. Misrepair is the
subtle one: a real finding whose recommendation was ambiguous enough to send
an implementer at the wrong thing still failed.

---

## What is worth doing next, in order

1. **Coverage gate before a report is accepted** (from UXBench). Today the
   charter names journeys and viewports and we trust the explorer walked them.
   A gate would refuse a Pass-A report whose evidence directory does not
   contain screenshots for every declared journey milestone and viewport —
   turning "screenshot every claim" from a rule into an enforced precondition.
   Cheap, mechanical, and it closes the harness's most plausible silent
   failure: a thin run that reads like a thorough one.
2. **Local-first fixtures for harness self-test** (from UXBench). The
   calibration protocol currently needs a real product plus armed seeds, which
   makes calibrating the *harness itself* (as opposed to a charter) expensive.
   A handful of deliberately-broken static fixtures — one per defect class —
   would let a new install verify the evaluator finds a fabricated zero and a
   raw-ID leak before it is ever pointed at a real product. This is the single
   highest-value addition to this repo.
3. **Structured cohort aggregation output** (from UXCascade). `cohort-summary.md`
   is prose today. Once cohorts routinely run 4+ personas, the journey ×
   persona difficulty matrix and the finding clusters want to be machine
   readable so trends across runs are diffable rather than re-read.

## What to refuse, and why

- **Scaling to hundreds or thousands of generated personas.** UXAgent's
  headline capability is exactly what this harness should not do. Our unit of
  output is a finding with a screenshot, a reproduction, and a disposition —
  each carries human review cost. A thousand personas produce a distribution,
  and a distribution over synthetic users is *not* a distribution over users:
  it is a distribution over one model's priors, which will look like data and
  is not. Cohorts of 2–5 profile-approved personas, or single-persona runs.
- **Any population-level or quantitative UX claim.** No satisfaction scores,
  no "N% of users would fail", no A/B substitution. The exit interview's 1–7
  ratings are explicitly self-report, comparable across runs of the same
  charter and nothing more.
- **Fine-tuning an evaluator on human response data** (PerceptUI's approach).
  Right in principle, out of reach in practice — it needs a corpus of real
  user responses to this product's screens. If such a corpus ever exists, the
  cheaper first move is to use it as *calibration controls* (does the explorer
  reach the same conclusions humans did?) rather than as training data.
- **Replacing human research.** Worth stating in the repo because it is the
  claim this technology invites and the one that discredits it fastest. This
  harness finds the problems a careful expert would find on a live build,
  before you spend a real participant's hour. It does not tell you what people
  want, why they came, or what they would pay for — and a synthetic
  participant's enthusiasm is worth exactly nothing.

## Can any of them be run as-is from the orchestrator?

**UXAgent: yes, as a separate instrument — not as a pass.** It is MIT-licensed,
`uv`-managed, Playwright-driven, and accepts Anthropic/OpenAI keys, so a
charter-adjacent invocation is mechanically easy: point it at the same isolated
stack a state-mutating charter uses, give it the profile's personas as
intents, and read its traces as *exploratory input* — a source of journeys and
friction hypotheses that the charter author then turns into oracles and
journeys.

What it must not do is produce findings that enter our finding stream. Its
output has no screenshot-per-claim rule, no suppression check, no
reproduction, no severity vocabulary, and no verdict lane. Merging it would
import exactly the failure mode this repo avoids elsewhere: several
independent reporters emitting overlapping, differently-scaled reports whose
reconciliation lands on a human. Treat it as a *charter-authoring aid* and a
second opinion on where to look — the same relationship the harness has to any
other exploratory tool.

**UXCascade, PerceptUI: no.** Research prototypes; adopt the ideas, not the
code.

**UXBench: not runnable against your product** — it is a fixed fixture
benchmark, not a testing tool. But it is the right *shape* to copy for item 2
above, and if its fixtures are published they are a ready-made self-test
corpus for a new install of this harness.

---

## Sources

- UXAgent — repo: <https://github.com/neuhai/UXAgent> · papers:
  [arXiv:2502.12561](https://arxiv.org/abs/2502.12561) (CHI'25 EA),
  [arXiv:2504.09407](https://arxiv.org/abs/2504.09407) (system) · project page:
  <https://uxagent.hailab.io/>
- UXCascade — [arXiv:2601.15777](https://arxiv.org/abs/2601.15777) *(abstract only)*
- PerceptUI — [arXiv:2606.05697](https://arxiv.org/abs/2606.05697) *(abstract only)*
- UXBench — [arXiv:2606.16262](https://arxiv.org/abs/2606.16262) *(abstract only)*
