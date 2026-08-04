#!/usr/bin/env python3
"""Gate a completed run's evidence directory.

Mechanical checks only: this is what turns the method's prose invariants into
something that fails. What it defends against and what it explicitly does not
are stated in docs/threat-model.md -- read that before adding a check, because
"an adversary could forge this" is out of scope by design and "a tired operator
or a lazy explorer could omit this" is in scope.

Usage:
    verify_run.py <run_dir> [--cohort] [--pass-a-only] [--json]

Exit: 0 pass | 1 gate failure | 2 bad usage

Deliberately NOT checked: whether the findings are any good, whether a
screenshot really shows the state its row claims, whether an `na` reason is
honest, or whether a credential is visible inside an image. Those are
calibration's job, or a human's.

This is Python rather than shell because the previous shell implementation
accumulated a class of defects that shell invites and Python does not:
`read` silently dropping a final unterminated line, exit codes used as counters
wrapping at 256, word splitting, and path containment by string comparison.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

MANDATORY_FINDING_FIELDS = [
    "class", "route_state", "persona", "observed", "principle",
    "consequence", "recommendation", "severity", "confidence",
    "suppression_check",
]

FINDING_CLASSES = {"product-defect", "experience-opportunity", "observation"}
OPPORTUNITY_TIERS = {"highly-valuable", "valuable", "good-to-have"}
DEFECT_SEVERITIES = {"critical", "high", "medium", "low"}
COVERAGE_STATUSES = {"covered", "blocked", "na"}

STACK_MARKERS = [".qa-stack", "stack.pid", "snapshot.db", "redirects.env"]

REDACTION_RE = re.compile(r"""[<\[(]?\s*redacted\s*[)\]>]?""", re.IGNORECASE)

# Each entry: (label, compiled regex). Values must be substantial to count, so
# that a correctly redacted header ("authorization: Bearer <REDACTED>") does not
# fail the gate once the marker is stripped.
SECRET_PATTERNS = [
    ("authorization header",
     re.compile(r"authorization\s*[:=]\s*(?:[A-Za-z]+\s+)?\S{8,}", re.I)),
    ("set-cookie header",
     re.compile(r"set-cookie\s*[:=]\s*\S{8,}", re.I)),
    ("cookie header",
     re.compile(r"(?:^|[^a-z-])cookie\s*[:=]\s*\S{8,}", re.I)),
    ("bearer token",
     re.compile(r"bearer\s+[A-Za-z0-9._\-]{16,}", re.I)),
    ("jwt",
     re.compile(r"eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}")),
    ("provider api key",
     re.compile(r"\b(?:sk|rk|pk)-[A-Za-z0-9]{16,}\b")),
    # Quoted forms need their own patterns: a JSON body puts the value inside
    # quotes, so the unquoted "assigned credential" pattern below never matches
    # it, and authorization/cookie in JSON form slipped past entirely.
    ("quoted credential",
     re.compile(r'"(?:authorization|cookie|set-cookie|api[_-]?key|access[_-]?token|'
                r'refresh[_-]?token|id[_-]?token|client[_-]?secret|secret|password|'
                r'passwd|token|session[_-]?id)"\s*:\s*"[^"]{8,}"', re.I)),
    ("quoted header value",
     re.compile(r"(?:authorization|cookie|set-cookie)\s*[:=]\s*['\"][^'\"]{8,}['\"]", re.I)),
    ("assigned credential",
     re.compile(r"\b(?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|"
                r"secret|password|passwd|token|session[_-]?id)\s*[:=]\s*['\"]?[^\s\"']{8,}", re.I)),
    ("private key block",
     re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
]

HASH_LINE_RE = re.compile(
    r"sha256\(\s*(?P<path>[^)]+?)\s*\)\s*[=:]\s*(?P<hex>[0-9a-fA-F]{64})")

READ_DECLARATION_RE = re.compile(r"^\s{0,3}#{1,6}\s*read declaration\b", re.I | re.M)

# Text extensions we scan for secrets. An unknown extension is scanned too if it
# decodes as UTF-8; genuinely binary files are skipped and reported as unscanned,
# because silently skipping them would be a false green.
BINARY_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf", ".zip",
               ".gz", ".mp4", ".webm", ".mov", ".ico", ".woff", ".woff2"}


@dataclass
class Report:
    failures: list[str] = field(default_factory=list)
    passes: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def fail(self, msg: str) -> None:
        self.failures.append(msg)

    def ok(self, msg: str) -> None:
        self.passes.append(msg)

    def note(self, msg: str) -> None:
        self.notes.append(msg)


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def is_inside(root: Path, candidate: Path) -> bool:
    """True if candidate resolves inside root, symlinks included.

    os.path.realpath resolves every component, so a symlinked evidence file
    pointing outside the run directory is caught -- which string prefix
    comparison does not do.
    """
    try:
        real_root = Path(os.path.realpath(root))
        real_cand = Path(os.path.realpath(candidate))
    except OSError:
        return False
    return real_root == real_cand or real_root in real_cand.parents


def read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8", errors="strict")
    except (UnicodeDecodeError, OSError):
        return None


# --------------------------------------------------------------- artifact checks

def check_artifacts(run: Path, rep: Report, cohort: bool, pass_a_only: bool) -> list[Path]:
    required = ["findings.md", "debrief.md", "coverage.tsv", "coverage-required.tsv"]
    required += ["cohort-summary.md"] if cohort else ["pass-a-report.md", "exit-interview.md"]
    if not pass_a_only:
        required.append("pass-b-report.md")

    for name in required:
        p = run / name
        if p.is_file() and p.stat().st_size > 0:
            rep.ok(f"artifact {name}")
        else:
            rep.fail(f"missing or empty artifact: {name}")

    if (run / "evidence").is_dir():
        rep.ok("evidence/ present")
    else:
        rep.fail("missing evidence/ directory")

    if pass_a_only:
        rep.note("--pass-a-only: no functional or data-correctness pass was run. "
                 "This run is NOT evidence about behaviour or data; label it "
                 "'Pass-A only — no functional verification' wherever it is reported.")

    pass_a_reports: list[Path] = []
    if cohort:
        personas_dir = run / "personas"
        persona_dirs = []
        if personas_dir.is_dir():
            for d in sorted(personas_dir.iterdir()):
                if not d.is_dir():
                    continue
                # A symlinked persona directory would put the hashed artifacts
                # outside the run, where teardown and archival cannot reach them.
                if not is_inside(run, d):
                    rep.fail(f"personas/{d.name} resolves outside the run directory")
                    continue
                persona_dirs.append(d)
        if not persona_dirs:
            rep.fail("cohort run without personas/ subdirectories")
        else:
            rep.ok(f"personas/ populated ({len(persona_dirs)})")
            if len(persona_dirs) < 2:
                rep.fail("cohort run with fewer than 2 personas — a cohort of one "
                         "is a single-persona run mislabeled")
            for d in persona_dirs:
                for name in ("pass-a-report.md", "exit-interview.md"):
                    p = d / name
                    if not (p.is_file() and p.stat().st_size > 0):
                        rep.fail(f"cohort: missing {name} for persona {d.name}")
                pa = d / "pass-a-report.md"
                if pa.is_file():
                    pass_a_reports.append(pa)
    else:
        pa = run / "pass-a-report.md"
        if pa.is_file():
            pass_a_reports.append(pa)
    return pass_a_reports


def check_hashes(run: Path, rep: Report, cohort: bool) -> None:
    """Per-artifact, path-bound integrity.

    A bare pool of hashes lets one artifact's hash vouch for another, so the
    recorded form must be sha256(<path>) = <hex> and each artifact is matched
    against its own entry.
    """
    debrief = read_text(run / "debrief.md") or ""
    recorded: dict[str, str] = {}
    for m in HASH_LINE_RE.finditer(debrief):
        recorded[m.group("path").strip().lstrip("./")] = m.group("hex").lower()

    targets: list[str] = []
    if cohort:
        personas = run / "personas"
        if personas.is_dir():
            for d in sorted(p for p in personas.iterdir() if p.is_dir()):
                targets += [f"personas/{d.name}/pass-a-report.md",
                            f"personas/{d.name}/exit-interview.md"]
    else:
        targets = ["pass-a-report.md", "exit-interview.md"]

    for rel in targets:
        path = run / rel
        if not path.is_file():
            continue
        want = recorded.get(rel)
        if want is None:
            rep.fail(f"debrief.md records no 'sha256({rel}) = <hex>' entry "
                     "(Pass-A immutability unverifiable)")
            continue
        if sha256_of(path) == want:
            rep.ok(f"integrity {rel}")
        else:
            rep.fail(f"integrity {rel}: content changed after hashing")


def check_read_declarations(run: Path, rep: Report, reports: list[Path]) -> None:
    for path in reports:
        text = read_text(path) or ""
        rel = path.relative_to(run).as_posix()
        if not READ_DECLARATION_RE.search(text):
            rep.fail(f"no '## Read declaration' section in {rel} "
                     "(Pass-A contamination cannot be audited)")
            continue
        tail = text[READ_DECLARATION_RE.search(text).end():]
        # A section containing only its own labels ("Files read:") is as empty as
        # a blank one: it declares nothing. Require at least one item line, where
        # an explicit "none" counts.
        items = [ln.strip() for ln in tail.splitlines()
                 if re.match(r"^\s*[-*+]\s*\S", ln) or re.search(r"\bnone\b", ln, re.I)]
        if not items:
            rep.fail(f"read declaration in {rel} has no entries — list what was "
                     "read, or say 'none beyond the packet' explicitly; a heading "
                     "with only labels under it declares nothing")
        else:
            rep.ok(f"read declaration present in {rel} ({len(items)} entr{'y' if len(items)==1 else 'ies'})")


# ------------------------------------------------------------------ coverage

def read_matrix(path: Path) -> tuple[list[list[str]], list[str]]:
    """Parse a coverage TSV. Returns (rows, problems)."""
    rows: list[list[str]] = []
    problems: list[str] = []
    text = read_text(path)
    if text is None:
        return rows, [f"{path.name} is not valid UTF-8 text"]
    reader = csv.reader(text.splitlines(), delimiter="\t")
    for lineno, raw in enumerate(reader, start=1):
        if not raw or not raw[0].strip() or raw[0].lstrip().startswith("#"):
            continue
        if raw[0].strip().lower() == "journey":
            continue
        if len(raw) < 4:
            problems.append(f"{path.name}:{lineno}: expected at least 4 "
                            f"tab-separated columns, got {len(raw)}")
            continue
        rows.append([c.strip() for c in raw] + [""] * (5 - len(raw)))
    return rows, problems


def check_coverage(run: Path, rep: Report) -> None:
    declared, problems = read_matrix(run / "coverage.tsv")
    required, req_problems = read_matrix(run / "coverage-required.tsv")
    for p in problems + req_problems:
        rep.fail(p)

    if not declared:
        rep.fail("coverage.tsv has no data rows")
    if not (run / "coverage-required.tsv").is_file():
        return
    if not required:
        rep.fail("coverage-required.tsv has no data rows — the run's denominator "
                 "is undefined, so its coverage claim is unverifiable")

    bad = 0
    seen: set[tuple[str, str, str]] = set()
    for journey, viewport, state, status, detail in (r[:5] for r in declared):
        ident = f"{journey}/{viewport}/{state}"
        key = (journey, viewport, state)
        if key in seen:
            rep.fail(f"coverage {ident}: duplicate row — a cell may be accounted "
                     "for exactly once")
            bad += 1
        seen.add(key)

        status_l = status.lower()
        if status_l not in COVERAGE_STATUSES:
            rep.fail(f"coverage {ident}: status must be covered|blocked|na, got '{status}'")
            bad += 1
        elif status_l == "covered":
            if not detail:
                rep.fail(f"coverage {ident}: covered with no evidence file")
                bad += 1
            elif os.path.isabs(detail):
                rep.fail(f"coverage {ident}: evidence path must be relative: {detail}")
                bad += 1
            elif not is_inside(run, run / detail):
                rep.fail(f"coverage {ident}: evidence path escapes the run directory: {detail}")
                bad += 1
            else:
                ev = run / detail
                if not ev.is_file():
                    rep.fail(f"coverage {ident}: evidence file missing: {detail}")
                    bad += 1
                elif ev.stat().st_size == 0:
                    rep.fail(f"coverage {ident}: evidence file is empty: {detail}")
                    bad += 1
        else:  # blocked | na
            if not detail:
                rep.fail(f"coverage {ident}: '{status_l}' with no reason "
                         "(a silent gap reads as coverage)")
                bad += 1

    if declared and bad == 0:
        rep.ok(f"coverage: {len(declared)} declared cells well-formed")

    missing = [f"{j}/{v}/{s}" for j, v, s, *_ in (r[:5] for r in required)
               if (j, v, s) not in seen]
    for ident in missing:
        rep.fail(f"coverage: required cell never accounted for: {ident}")
    if required and not missing:
        rep.ok(f"coverage: all {len(required)} required cells accounted for")


# ------------------------------------------------------------------- findings

FIELD_RE = re.compile(r"^(?P<key>[a-z][a-z0-9_]*)\s*[:|]\s*(?P<val>.*)$")


def parse_findings(text: str) -> list[dict[str, str]]:
    """Split on `id:` and collect fields per record.

    Per record, not per file: counting fields across the whole document lets a
    duplicated field in one record cover a missing field in another.
    """
    records: list[dict[str, str]] = []
    cur: dict[str, str] | None = None
    for raw in text.splitlines():
        line = raw.strip()
        line = re.sub(r"^[-*+]\s*", "", line)
        line = line.replace("**", "")
        line = re.sub(r"^\|\s*", "", line)
        line = line.strip()
        m = FIELD_RE.match(line)
        if not m:
            continue
        key, val = m.group("key").lower(), m.group("val").strip().rstrip("|").strip()
        if key == "id":
            cur = {"id": val}
            records.append(cur)
        elif cur is not None and key not in cur:
            cur[key] = val
    return records


def check_findings(run: Path, rep: Report) -> None:
    text = read_text(run / "findings.md")
    if text is None:
        rep.fail("findings.md is missing or not valid UTF-8")
        return
    records = parse_findings(text)
    if not records:
        rep.fail("findings.md contains no parseable finding records (expected 'id:' fields)")
        return

    incomplete = []
    for rec in records:
        missing = [f for f in MANDATORY_FINDING_FIELDS if not rec.get(f)]
        if missing:
            incomplete.append((rec.get("id", "<no id>"), missing))
    if incomplete:
        rep.fail(f"findings.md: {len(incomplete)} of {len(records)} records missing "
                 "mandatory fields:")
        for fid, missing in incomplete[:10]:
            rep.fail(f"    {fid}: {' '.join(missing)}")
    else:
        rep.ok(f"findings: {len(records)} records each carry all mandatory fields")

    ids = [r.get("id", "") for r in records]
    dupes = {i for i in ids if i and ids.count(i) > 1}
    for d in sorted(dupes):
        rep.fail(f"findings.md: duplicate finding id '{d}'")

    # Severity vocabularies are per class and not interchangeable.
    for rec in records:
        cls = rec.get("class", "").strip().lower()
        sev = rec.get("severity", "").strip().lower()
        fid = rec.get("id", "<no id>")
        if not cls or not sev:
            continue
        # An unknown class silently escaped every downstream rule: no severity
        # vocabulary applied, no priority required, and nothing routed it.
        if cls not in FINDING_CLASSES:
            rep.fail(f"findings.md {fid}: unknown class '{cls}' — must be one of "
                     f"{sorted(FINDING_CLASSES)}")
            continue
        if cls == "experience-opportunity" and sev not in OPPORTUNITY_TIERS:
            rep.fail(f"findings.md {fid}: experience-opportunity severity must be "
                     f"one of {sorted(OPPORTUNITY_TIERS)}, got '{sev}'")
        if cls == "product-defect":
            if sev not in DEFECT_SEVERITIES:
                rep.fail(f"findings.md {fid}: product-defect severity must be one of "
                         f"{sorted(DEFECT_SEVERITIES)}, got '{sev}'")
            if not rec.get("priority"):
                rep.fail(f"findings.md {fid}: product-defect without a priority "
                         "(severity and priority are separate numbers)")


# -------------------------------------------------------------------- secrets

def check_secrets(run: Path, rep: Report) -> None:
    """Scan text artifacts for unredacted credentials.

    Two rules the shell version got wrong:
      * a redaction marker exempts only ITSELF, never the rest of its line, so a
        live token beside a redacted one is still caught;
      * matches are never echoed -- printing a secret into a terminal or CI log
        copies it somewhere new, which is the opposite of the intent.
    """
    hits: list[str] = []
    unscanned: list[str] = []
    for path in sorted(p for p in run.rglob("*") if p.is_file()):
        rel = path.relative_to(run).as_posix()
        if path.suffix.lower() in BINARY_EXTS:
            continue
        if not is_inside(run, path):
            rep.fail(f"run directory contains a symlink escaping it: {rel}")
            continue
        text = read_text(path)
        if text is None:
            unscanned.append(rel)
            continue
        # splitlines() keeps a final unterminated line, which `while read` drops.
        for lineno, line in enumerate(text.splitlines(), start=1):
            stripped = REDACTION_RE.sub("", line)
            for label, pattern in SECRET_PATTERNS:
                if pattern.search(stripped):
                    hits.append(f"{rel}:{lineno}  [{label}]")
                    break

    if hits:
        rep.fail(f"possible unredacted credentials at {len(hits)} location(s) — "
                 "redact before sharing (locations only; matched text is "
                 "deliberately not printed)")
        for h in hits[:20]:
            rep.fail(f"    {h}")
        if len(hits) > 20:
            rep.fail(f"    ... and {len(hits) - 20} more")
    else:
        rep.ok("secret scan clean (text artifacts only — cannot read images)")

    if unscanned:
        rep.note(f"{len(unscanned)} non-text file(s) not scanned for credentials "
                 f"(e.g. {unscanned[0]}); a token visible inside an image or "
                 "recording is invisible to this gate")


def check_stack_collision(run: Path, rep: Report) -> None:
    for marker in STACK_MARKERS:
        if (run / marker).exists():
            rep.fail(f"stack-runner state inside the run directory ({marker}): "
                     "teardown would delete the report")


# ----------------------------------------------------------------------- main

GLANCE_LABEL = "GLANCE — uncalibrated, Pass-A only"

# Glance findings drop the three fields that have nothing to hang on in this
# mode: priority (no triage), suppression_check (no suppression sources), and
# disposition (no verdict lane). See references/glance-mode.md.
GLANCE_FINDING_FIELDS = [
    "class", "route_state", "persona", "observed", "principle",
    "consequence", "recommendation", "severity", "confidence",
]


def check_glance(run: Path, rep: Report) -> None:
    """Gate a glance run: the small set of checks that actually apply.

    Deliberately does not check coverage, hashes, or Pass B. None of those exist
    in this mode, and pretending to check them would be the dishonesty the mode
    is designed to avoid.
    """
    path = run / "glance.md"
    if not (path.is_file() and path.stat().st_size > 0):
        rep.fail("missing or empty artifact: glance.md")
        return
    rep.ok("artifact glance.md")

    text = read_text(path) or ""
    if GLANCE_LABEL in text:
        rep.ok("glance label present (output cannot be mistaken for evidence)")
    else:
        rep.fail("glance.md does not carry the mandatory label — it must begin "
                 f'with "{GLANCE_LABEL}. ..." verbatim (references/glance-mode.md)')

    if (run / "evidence").is_dir():
        rep.ok("evidence/ present")
    else:
        rep.fail("missing evidence/ directory")

    records = parse_findings(text)
    if not records:
        rep.note("no finding records parsed — a glance that found nothing should "
                 "say so in its summary, which is a legitimate result")
    else:
        incomplete = [(r.get("id", "<no id>"),
                       [f for f in GLANCE_FINDING_FIELDS if not r.get(f)])
                      for r in records]
        incomplete = [(i, m) for i, m in incomplete if m]
        if incomplete:
            rep.fail(f"glance.md: {len(incomplete)} of {len(records)} records missing "
                     "mandatory fields (relaxing the process does not relax the finding):")
            for fid, missing in incomplete[:10]:
                rep.fail(f"    {fid}: {' '.join(missing)}")
        else:
            rep.ok(f"findings: {len(records)} records each carry all glance-mode fields")

    for rec in records:
        cls = rec.get("class", "").strip().lower()
        if cls and cls not in FINDING_CLASSES:
            rep.fail(f"glance.md {rec.get('id', '<no id>')}: unknown class '{cls}'")

    rep.note("glance mode: coverage, hashes and Pass B are not checked because "
             "they do not exist here. This run is not coverage of anything and "
             "cannot support a readiness claim.")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(add_help=True, description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("run_dir")
    ap.add_argument("--cohort", action="store_true")
    ap.add_argument("--pass-a-only", action="store_true")
    ap.add_argument("--glance", action="store_true",
                    help="gate a glance run (references/glance-mode.md)")
    ap.add_argument("--json", action="store_true", help="machine-readable result")
    args = ap.parse_args(argv)

    run = Path(args.run_dir)
    if not run.is_dir():
        print(f"verify-run: not a directory: {run}", file=sys.stderr)
        return 2

    rep = Report()
    if args.glance:
        if args.cohort or args.pass_a_only:
            print("verify-run: --glance cannot be combined with --cohort or "
                  "--pass-a-only", file=sys.stderr)
            return 2
        check_glance(run, rep)
        check_secrets(run, rep)
        check_stack_collision(run, rep)
        return _emit(rep, run, args.json)

    reports = check_artifacts(run, rep, args.cohort, args.pass_a_only)
    check_hashes(run, rep, args.cohort)
    check_read_declarations(run, rep, reports)
    check_coverage(run, rep)
    check_findings(run, rep)
    check_secrets(run, rep)
    check_stack_collision(run, rep)
    return _emit(rep, run, args.json)


def _emit(rep: Report, run: Path, as_json: bool) -> int:

    if as_json:
        print(json.dumps({
            "run": str(run),
            "passed": not rep.failures,
            "failures": rep.failures,
            "checks_passed": rep.passes,
            "notes": rep.notes,
        }, indent=2))
        return 1 if rep.failures else 0

    for msg in rep.passes:
        print(f"ok    {msg}")
    for msg in rep.notes:
        print(f"note  {msg}")
    for msg in rep.failures:
        print(f"FAIL  {msg}" if not msg.startswith("    ") else msg)

    print()
    if rep.failures:
        print(f"verify-run: FAIL — {len(rep.failures)} problem(s) in {run}")
        print("A run that does not pass this gate is not coverage. "
              "Report it as an incomplete run.")
        return 1
    print(f"verify-run: PASS — {run}")
    print("The run is well-formed and fully accounted for. This says nothing "
          "about whether the findings are correct — see the calibration protocol.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
