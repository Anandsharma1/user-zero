# Known defects — negative controls

Problems the harness **should** rediscover. A run that misses them is not
trustworthy yet, no matter how articulate its report is.

Protocol, thresholds, and the registered-vs-armed distinction:
`<skill>/references/calibration-protocol.md`.

Two rules that decide whether this file is worth anything:

- **`registered` counts for nothing.** A control described in prose documents
  intent. It becomes `armed` only when its seed is executable and checked in
  (`calibration/seeds/<ID>.*`) or its baseline revision is recorded exactly,
  plus a probe that proves the defect is live before the run.
- **The denominator is fixed before the run.** Choose the in-scope control set
  first, then run. Picking controls after seeing results is scoring your own
  exam.

A fixed historical defect belongs here as a control. A still-open one belongs
in the profile's suppression sources instead — an entry is in exactly one role
per run.

---

## Control records

### ID: KD-001
- **Status:** registered | armed
- **Class:** functional | semantic/data | raw-ID or label leak | misleading zero | console/network failure | accessibility | visual/usability
- **Applies to charters:** <charter names>
- **Origin:** historical escape (<ledger reference>) | seeded
- **Seed mechanism:** `calibration/seeds/KD-001.patch` | baseline revision `<sha>`
- **Live probe (proves it is present before the run):**
  ```bash
  # command + expected output
  ```
- **Observable signature (what a run that found it MUST report):**
  <the specific thing the explorer should say — route, element, wrong value>
- **Restoration proof (after the run):**
  ```bash
  # digest-verified revert
  ```
- **Last calibration result:** <date — found / missed, and by which pass>

---

## In-scope sets (predeclared per calibration run)

| Date | Charter | Control IDs in scope | Rediscovery | Notes |
|---|---|---|---|---|
| | | | | |
