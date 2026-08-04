#!/usr/bin/env bash
# Test the harness's tooling. Plain bash, no dependencies.
#
#   tests/run-tests.sh [-v]
#
# Every test corresponds to a hole a reviewer found by hand (2026-08-03, two
# rounds). Do not fix a tooling bug without adding the test that would have
# caught it.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
VERBOSE=0; [ "${1-}" = "-v" ] && VERBOSE=1

pass=0; fail=0
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

ok()   { pass=$((pass+1)); printf 'ok   %s\n' "$1"; }
no()   { fail=$((fail+1)); printf 'FAIL %s\n     %s\n' "$1" "${2-}"; }
run()  { if [ "$VERBOSE" -eq 1 ]; then "$@"; else "$@" >/dev/null 2>&1; fi; }

fresh_target() { local d; d="$WORK/t$RANDOM$RANDOM"; mkdir -p "$d"; git -C "$d" init -q; echo "$d"; }

# ================================================== installer: path containment

t_dest_traversal() {
  local base="$WORK/trav$RANDOM"; mkdir -p "$base/target" "$base/victim"
  echo SENTINEL > "$base/victim/keep.txt"
  run "$REPO/scripts/install.sh" "$base/target" --dest ../victim; local rc=$?
  if [ -f "$base/victim/keep.txt" ] && [ "$rc" -ne 0 ]; then
    ok "installer rejects --dest traversal (would delete a sibling directory)"
  else no "installer --dest traversal" "rc=$rc sentinel=$([ -f "$base/victim/keep.txt" ] && echo ok || echo GONE)"; fi
}

t_dest_absolute() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --dest /etc/ui-qa \
    && no "installer --dest absolute" "accepted an absolute --dest" \
    || ok "installer rejects absolute --dest"
}

t_dest_metachars() {
  local t; t="$(fresh_target)" bad=0
  for d in 'a|b' 'a$(id)b' 'a`id`b' 'a;id' 'a b'; do
    run "$REPO/scripts/install.sh" "$t" --dest "$d" && bad=1
  done
  [ "$bad" -eq 0 ] && ok "installer rejects shell/sed metacharacters in --dest" \
                   || no "installer --dest metacharacters" "a crafted --dest was accepted"
}

t_no_injection_marker() {
  local t marker; t="$(fresh_target)"; marker="$WORK/injected-$RANDOM"
  run "$REPO/scripts/install.sh" "$t" --dest "x/$(basename "$marker")"
  [ -e "$marker" ] && no "template substitution is inert" "substitution created a file" \
                   || ok "template substitution is inert (bash expansion, never sed/eval)"
}

t_explorer_dir_validated() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --explorer-dir ../escape \
    && no "installer --explorer-dir traversal" "accepted ../escape" \
    || ok "installer rejects --explorer-dir traversal"
}

t_refuses_self() {
  run "$REPO/scripts/install.sh" "$REPO" \
    && no "installer self-target" "installed into the harness repo itself" \
    || ok "installer refuses to install into itself"
}

# ============================================== installer: destructive-delete gate

t_manifest_cannot_direct_deletion() {
  local t; t="$(fresh_target)"
  echo SENTINEL > "$t/.git/sentinel.txt"
  run "$REPO/scripts/install.sh" "$t"
  # The manifest lives in the target and is therefore untrusted input.
  sed -i 's|"dest": "[^"]*"|"dest": ".git"|' "$t/.ui-qa-install.json"
  run "$REPO/scripts/install.sh" "$t"; local rc=$?
  if [ -f "$t/.git/sentinel.txt" ] && [ "$rc" -ne 0 ]; then
    ok "manifest cannot direct deletion of .git (P0: reproduced before the fix)"
  else no "manifest-directed deletion" "rc=$rc sentinel=$([ -f "$t/.git/sentinel.txt" ] && echo ok || echo DESTROYED)"; fi
}

t_refuses_unowned_directory() {
  local t; t="$(fresh_target)"
  mkdir -p "$t/existing-stuff"; echo MINE > "$t/existing-stuff/important.txt"
  run "$REPO/scripts/install.sh" "$t" --dest existing-stuff; local rc=$?
  if [ -f "$t/existing-stuff/important.txt" ] && [ "$rc" -ne 0 ]; then
    ok "installer refuses a non-empty directory it does not own (no marker)"
  else no "ownership gate" "rc=$rc; pre-existing file survived=$([ -f "$t/existing-stuff/important.txt" ] && echo yes || echo NO)"; fi
}

t_owned_directory_is_replaceable() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" || { no "ownership marker" "first install failed"; return; }
  [ -f "$t/skills/ui-qa/.ui-qa-managed" ] || { no "ownership marker" "marker not written"; return; }
  touch "$t/skills/ui-qa/stale-file.md"
  run "$REPO/scripts/install.sh" "$t" || { no "ownership marker" "upgrade failed"; return; }
  [ ! -e "$t/skills/ui-qa/stale-file.md" ] \
    && ok "a marked directory is replaced on upgrade (stale files removed)" \
    || no "ownership marker" "upgrade did not replace the managed directory"
}

t_reserved_dirs_refused() {
  local t; t="$(fresh_target)" bad=0
  for d in .git .github .githooks node_modules; do
    run "$REPO/scripts/install.sh" "$t" --dest "$d" && bad=1
  done
  [ "$bad" -eq 0 ] && ok "installer refuses reserved destinations (.git, .github, .githooks, node_modules)" \
                   || no "reserved dests" "one was accepted"
}

# ==================================================== symlink-safe generation

t_sync_refuses_symlinked_platform_dir() {
  local base="$WORK/sym$RANDOM"; mkdir -p "$base/repo/skills" "$base/outside"
  echo KEEP > "$base/outside/file.md"
  cp -r "$REPO/skills/ui-qa" "$base/repo/skills/"
  ln -s ../outside "$base/repo/.claude"
  run "$REPO/scripts/sync-platform-dirs.sh" --root "$base/repo"
  if [ -e "$base/outside/agents/user-zero.md" ]; then
    no "symlink escape" "generator wrote outside the root through a symlink"
  else ok "generator refuses to write through a symlinked platform directory"; fi
}

t_install_refuses_symlinked_dest() {
  local base="$WORK/symi$RANDOM"; mkdir -p "$base/repo" "$base/outside"
  git -C "$base/repo" init -q
  ln -s ../outside "$base/repo/skills"
  run "$REPO/scripts/install.sh" "$base/repo"
  [ -e "$base/outside/ui-qa/SKILL.md" ] \
    && no "install symlink escape" "installed through a symlinked path" \
    || ok "installer refuses a symlinked --dest component"
}

# ======================================================== installer behaviour

t_install_preserves_user_content() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" || { no "install baseline" "first install failed"; return; }
  echo "MY PROFILE" > "$t/qa/product-explorer/PROFILE.md"
  echo "MY CHARTER" > "$t/qa/product-explorer/charters/mine.md"
  run "$REPO/scripts/install.sh" "$t" || { no "install upgrade" "second install failed"; return; }
  [ "$(cat "$t/qa/product-explorer/PROFILE.md")" = "MY PROFILE" ] && [ -f "$t/qa/product-explorer/charters/mine.md" ] \
    && ok "upgrade replaces harness files and preserves user content" \
    || no "upgrade preservation" "user-owned files were overwritten or removed"
}

t_manifest_persists_explorer_dir() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --explorer-dir qa/custom-explorer
  [ -f "$t/qa/custom-explorer/PROFILE.md" ] || { no "custom explorer dir" "scaffold not created"; return; }
  echo "MINE" > "$t/qa/custom-explorer/PROFILE.md"
  run "$REPO/scripts/install.sh" "$t"
  [ "$(cat "$t/qa/custom-explorer/PROFILE.md")" = "MINE" ] && [ ! -e "$t/qa/product-explorer/PROFILE.md" ] \
    && ok "install manifest persists --explorer-dir across upgrades" \
    || no "manifest persistence" "a later install did not rediscover the non-default explorer dir"
}

t_placeholder_resolved() {
  local t; t="$(fresh_target)"
  # A non-default, non-platform dest: platform dirs are now refused outright.
  run "$REPO/scripts/install.sh" "$t" --dest harness/ui-qa
  grep -q 'harness/ui-qa/references' "$t/qa/product-explorer/calibration/known-defects.md" \
    && ! grep -q '<skill>' "$t/qa/product-explorer/calibration/known-defects.md" \
    && ok "scaffolded templates resolve <skill> to the real dest" \
    || no "placeholder substitution" "template still contains <skill> or the wrong path"
}

# ============================================================== sync + check

t_codex_documented_location() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --platforms codex
  [ -f "$t/.agents/skills/ui-qa/SKILL.md" ] && [ -f "$t/.agents/skills/ui-qa/agents/openai.yaml" ] \
    && ok "codex writes the documented .agents/skills location + openai.yaml" \
    || no "codex layout" ".agents/skills/ui-qa/{SKILL.md,agents/openai.yaml} missing"
}

t_adapter_drives_tool_grant() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  grep -q 'mcp__playwright' "$t/.claude/agents/user-zero.md" \
    && ok "generated agent grants the bound adapter's tools" \
    || no "adapter tool grant" "playwright adapter did not yield mcp__playwright"
  run "$REPO/scripts/install.sh" "$t" --adapter nonexistent-adapter \
    && no "adapter validation" "accepted an adapter with no adapter file" \
    || ok "install rejects an adapter with no adapter file"
}

t_adapter_claude_chrome() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --adapter claude-chrome
  local stub="$t/.claude/agents/user-zero.md"
  [ -f "$stub" ] || { no "claude-chrome adapter" "agent stub not generated"; return; }
  if grep -q 'mcp__playwright' "$stub"; then
    no "claude-chrome adapter" "stub still grants playwright tools"
  elif ! grep -q '^tools:.*mcp__claude-in-chrome__computer' "$stub"; then
    no "claude-chrome adapter" "stub does not pin the measured extension tool names"
  elif grep -q 'mcp__claude-in-chrome__javascript_tool' "$stub"; then
    # Granting it would hand the explorer the DOM, which the persona forbids.
    no "claude-chrome adapter" "stub grants javascript_tool to the explorer"
  elif ! grep -q 'adapters/claude-chrome.md' "$stub"; then
    no "claude-chrome adapter" "stub does not point at the claude-chrome adapter file"
  else
    ok "claude-chrome adapter: stub pins measured tools, withholds JS, points at the right adapter"
  fi
}

t_narrowing_platforms_prunes() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --platforms "claude codex"
  [ -f "$t/.agents/skills/ui-qa/SKILL.md" ] || { no "prune setup" "codex stub not created"; return; }
  run "$REPO/scripts/sync-platform-dirs.sh" --root "$t" --platforms claude
  if [ -e "$t/.agents/skills/ui-qa/SKILL.md" ] || [ -e "$t/.codex/skills/ui-qa/SKILL.md" ]; then
    no "platform pruning" "obsolete codex stubs survived narrowing --platforms"
  else
    [ -f "$t/.claude/skills/ui-qa/SKILL.md" ] \
      && ok "narrowing --platforms prunes obsolete stubs and keeps selected ones" \
      || no "platform pruning" "pruning removed the selected platform too"
  fi
}

t_check_detects_worktree_drift() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  printf '\nHAND EDIT\n' >> "$t/.claude/agents/user-zero.md"
  run "$REPO/scripts/check-platform-sync.sh" --root "$t" \
    && no "worktree drift detection" "hand-edited stub reported in sync" \
    || ok "check detects a hand-edited stub in the working tree"
}

t_check_platforms_forwarded() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --platforms claude
  run "$REPO/scripts/check-platform-sync.sh" --root "$t" --platforms cursor \
    && no "platform matrix" "--platforms cursor reported in-sync (false green)" \
    || ok "check fails when --platforms disagrees with what is present"
}

t_check_from_index_catches_partial_staging() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  git -C "$t" add -A && git -C "$t" -c user.email=t@t -c user.name=t commit -qm base
  sed -i 's/^description: /description: CHANGED /' "$t/skills/ui-qa/SKILL.md"
  run "$REPO/scripts/sync-platform-dirs.sh" --root "$t"
  git -C "$t" add skills/ui-qa/SKILL.md
  local wt=0 idx=0
  run "$REPO/scripts/check-platform-sync.sh" --root "$t" || wt=1
  run "$REPO/scripts/check-platform-sync.sh" --root "$t" --from-index || idx=1
  [ "$wt" -eq 0 ] && [ "$idx" -eq 1 ] \
    && ok "--from-index catches partial staging the worktree check passes" \
    || no "staged-index check" "worktree_failed=$wt index_failed=$idx (expected 0 then 1)"
}

t_from_index_uses_staged_generator() {
  # A staged generator change must be judged against staged stubs. Using the
  # worktree generator makes an unstaged generator edit read as stub drift.
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  mkdir -p "$t/scripts"
  cp "$REPO/scripts/sync-platform-dirs.sh" "$REPO/scripts/lib-common.sh" "$t/scripts/"
  git -C "$t" add -A && git -C "$t" -c user.email=t@t -c user.name=t commit -qm base
  # Unstaged generator edit: index is self-consistent, so --from-index must pass.
  printf '\n# unstaged comment\n' >> "$t/scripts/sync-platform-dirs.sh"
  run "$REPO/scripts/check-platform-sync.sh" --root "$t" --from-index \
    && ok "--from-index judges staged stubs against the staged generator" \
    || no "staged generator" "an unstaged generator edit was reported as stub drift"
}

# ================================================================= run gate

GATE="$REPO/skills/ui-qa/scripts/verify-run.sh"

hash_of() {
  if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

write_debrief() {  # <run-dir>
  local d="$1"
  {
    printf 'PROOF debrief\n\n'
    printf 'sha256(pass-a-report.md) = %s\n' "$(hash_of "$d/pass-a-report.md")"
    printf 'sha256(exit-interview.md) = %s\n' "$(hash_of "$d/exit-interview.md")"
  } > "$d/debrief.md"
}

make_run() {  # <dir> ; a minimal run that should PASS
  local d="$1"; mkdir -p "$d/evidence"
  printf 'Pass A report.\n\n## Read declaration\nFiles read:\n- none beyond the packet\nCommands run:\n- none beyond browser tools\n' > "$d/pass-a-report.md"
  printf 'north_star_answer: I could not tell from these screens.\n' > "$d/exit-interview.md"
  printf 'Pass B report: oracles verified.\n' > "$d/pass-b-report.md"
  printf 'shot\n' > "$d/evidence/01-home.png"
  {
    printf -- '- id: r-01\n  class: product-defect\n  route_state: /home happy\n  persona: novice\n'
    printf -- '  screenshot: evidence/01-home.png\n  observed: total shown without denominator\n'
    printf -- '  principle: taxonomy 5 aggregates\n  consequence: false confidence\n'
    printf -- '  recommendation: show n beside the percentage\n  severity: high\n  priority: high\n'
    printf -- '  confidence: high\n  suppression_check: checked ledger; no match\n'
  } > "$d/findings.md"
  printf 'journey\tviewport\tstate\tstatus\tevidence_or_reason\n' > "$d/coverage-required.tsv"
  printf 'home\tdesktop\thappy\trequired\t\n'   >> "$d/coverage-required.tsv"
  printf 'home\tdesktop\terror\trequired\t\n'   >> "$d/coverage-required.tsv"
  printf 'journey\tviewport\tstate\tstatus\tevidence_or_reason\n' > "$d/coverage.tsv"
  printf 'home\tdesktop\thappy\tcovered\tevidence/01-home.png\n' >> "$d/coverage.tsv"
  printf 'home\tdesktop\terror\tblocked\tno fault injection in this mode\n' >> "$d/coverage.tsv"
  write_debrief "$d"
}

t_gate_accepts_complete_run() {
  local d="$WORK/run-good"; make_run "$d"
  run "$GATE" "$d" && ok "gate accepts a complete, redacted, fully covered run" \
                   || no "gate false negative" "a compliant run failed the gate"
}

t_gate_requires_pass_b() {
  local d="$WORK/run-nob"; make_run "$d"; rm "$d/pass-b-report.md"
  if run "$GATE" "$d"; then
    no "pass B required" "a run with no functional pass was accepted silently"
  else
    run "$GATE" "$d" --pass-a-only \
      && ok "gate requires pass-b-report.md unless --pass-a-only is explicit" \
      || no "pass-a-only mode" "--pass-a-only did not accept an otherwise valid run"
  fi
}

t_gate_requires_read_declaration() {
  local d="$WORK/run-nodecl"; make_run "$d"
  printf 'Pass A report with no declaration.\n' > "$d/pass-a-report.md"
  write_debrief "$d"
  run "$GATE" "$d" && no "read declaration" "Pass A without a read declaration was accepted" \
                   || ok "gate requires the Pass-A read declaration (contamination audit)"
}

t_gate_hashes_are_artifact_bound() {
  local d="$WORK/run-swap"; make_run "$d"
  # Record only the exit-interview hash, then tamper with the Pass-A report.
  # An undifferentiated hash pool would accept this.
  printf 'PROOF\nsha256(exit-interview.md) = %s\n' "$(hash_of "$d/exit-interview.md")" > "$d/debrief.md"
  printf 'Pass B rewrote this.\n\n## Read declaration\nFiles read:\n- none\n' > "$d/pass-a-report.md"
  run "$GATE" "$d" && no "artifact-bound hashes" "one artifact's hash vouched for another" \
                   || ok "gate binds each hash to its artifact by path"
}

t_gate_catches_tampering() {
  local d="$WORK/run-tamper"; make_run "$d"
  printf 'Pass B rewrote this.\n' >> "$d/pass-a-report.md"
  run "$GATE" "$d" && no "hash integrity" "post-hoc edit of pass-a-report.md accepted" \
                   || ok "gate catches a Pass-A report edited after hashing"
}

t_gate_catches_uncovered_cell() {
  local d="$WORK/run-cov"; make_run "$d"
  printf 'home\tmobile\thappy\tcovered\tevidence/99-missing.png\n' >> "$d/coverage.tsv"
  run "$GATE" "$d" && no "coverage gate" "covered cell with missing evidence accepted" \
                   || ok "gate catches a covered cell whose evidence file is absent"
}

t_gate_catches_evidence_escape() {
  local d="$WORK/run-escape"; make_run "$d"
  printf 'secret\n' > "$WORK/outside-evidence.png"
  printf 'home\tmobile\thappy\tcovered\t../outside-evidence.png\n' >> "$d/coverage.tsv"
  run "$GATE" "$d" && no "evidence containment" "evidence path outside the run dir accepted" \
                   || ok "gate rejects a coverage evidence path that escapes the run directory"
}

t_gate_requires_independent_denominator() {
  local d="$WORK/run-denom"; make_run "$d"
  # Explorer trims its own matrix; the required set still names the error cell.
  printf 'journey\tviewport\tstate\tstatus\tevidence_or_reason\n' > "$d/coverage.tsv"
  printf 'home\tdesktop\thappy\tcovered\tevidence/01-home.png\n' >> "$d/coverage.tsv"
  run "$GATE" "$d" && no "independent denominator" "a self-selected matrix passed" \
                   || ok "gate compares coverage.tsv against the pre-declared required matrix"
  rm "$d/coverage-required.tsv"
  run "$GATE" "$d" && no "required matrix" "a run with no required matrix passed" \
                   || ok "gate fails when coverage-required.tsv is absent"
}

t_gate_catches_reasonless_gap() {
  local d="$WORK/run-gap"; make_run "$d"
  printf 'home\tmobile\tempty\tna\t\n' >> "$d/coverage.tsv"
  run "$GATE" "$d" && no "coverage gate" "na cell with no reason accepted (silent gap)" \
                   || ok "gate catches a blocked/na cell with no reason"
}

t_gate_per_record_fields() {
  local d="$WORK/run-perrec"; make_run "$d"
  # Second record duplicates fields that the third omits: a global field count
  # is satisfied while one record is incomplete.
  {
    printf -- '- id: r-02\n  class: observation\n  route_state: /a happy\n  persona: novice\n'
    printf -- '  screenshot: evidence/01-home.png\n  observed: x\n  principle: y\n  consequence: z\n'
    printf -- '  recommendation: w\n  severity: low\n  confidence: low\n  suppression_check: none\n'
    printf -- '  persona: novice\n  observed: duplicate field\n'
    printf -- '- id: r-03\n  class: observation\n  observed: something felt off\n'
  } >> "$d/findings.md"
  run "$GATE" "$d" && no "per-record validation" "an incomplete record hid behind duplicates" \
                   || ok "gate validates finding fields per record, not by global count"
}

t_gate_catches_credentials() {
  local d="$WORK/run-secret"; make_run "$d"
  printf 'authorization: Bearer abcdefghijklmnopqrstuvwxyz012345\n' > "$d/evidence/02-network.txt"
  run "$GATE" "$d" && no "secret scan" "unredacted bearer token accepted" \
                   || ok "gate catches an unredacted credential in evidence"
  printf 'authorization: Bearer <REDACTED>\n' > "$d/evidence/02-network.txt"
  run "$GATE" "$d" && ok "gate accepts a properly redacted header" \
                   || no "secret scan" "redacted header rejected"
}

t_gate_redaction_is_per_token() {
  local d="$WORK/run-partial"; make_run "$d"
  # A redacted cookie beside a live authorization header on ONE line: exempting
  # the whole line would let the live credential through.
  printf 'cookie: <REDACTED>; authorization: Bearer abcdefghijklmnopqrstuvwxyz012345\n' > "$d/evidence/02-network.txt"
  run "$GATE" "$d" && no "per-token redaction" "a live credential beside a redacted one passed" \
                   || ok "gate does not exempt a whole line because it contains a redaction marker"
}

t_gate_catches_json_credentials() {
  local d="$WORK/run-json"; make_run "$d"
  printf '{"user":"a","access_token":"abcd1234efgh5678ijkl"}\n' > "$d/evidence/03-body.json"
  run "$GATE" "$d" && no "json secret scan" "quoted JSON token missed" \
                   || ok "gate catches credentials in quoted JSON form"
}

t_gate_does_not_echo_secrets() {
  local d="$WORK/run-echo"; make_run "$d"
  local tok="zzTOPSECRETVALUE1234567890"
  printf 'authorization: Bearer %s\n' "$tok" > "$d/evidence/02-network.txt"
  local out; out="$("$GATE" "$d" 2>&1)"
  printf '%s' "$out" | grep -q "$tok" \
    && no "diagnostic sanitation" "the gate printed the secret to its output" \
    || ok "gate reports locations without echoing the credential"
}

t_gate_catches_stack_dir_collision() {
  local d="$WORK/run-stack"; make_run "$d"; touch "$d/snapshot.db"
  run "$GATE" "$d" && no "stack collision" "stack state inside the run dir accepted" \
                   || ok "gate catches stack-runner state inside the run directory"
}

t_gate_cohort_requires_personas() {
  local d="$WORK/run-cohort"; make_run "$d"
  printf 'cohort summary\n' > "$d/cohort-summary.md"
  run "$GATE" "$d" --cohort && no "cohort gate" "cohort run without personas/ accepted" \
                            || ok "gate requires per-persona artifacts for a cohort run"
}

# ============================== gate: defects the shell implementation had

t_gate_scans_unterminated_final_line() {
  # `while read` returns 0 lines for a file with no trailing newline, so a
  # one-line network dump was scanned as empty. Python's splitlines() keeps it.
  local d="$WORK/run-noeol"; make_run "$d"
  printf 'authorization: Bearer abcdefghijklmnopqrstuvwxyz012345' > "$d/evidence/02-net.txt"
  run "$GATE" "$d" && no "unterminated line" "a credential on an unterminated final line was skipped" \
                   || ok "gate scans a final line with no trailing newline"
}

t_gate_counts_beyond_256() {
  # Exit codes wrap at 256, so exactly 256 hits read as clean.
  local d="$WORK/run-256"; make_run "$d"
  : > "$d/evidence/02-net.txt"
  local i=0; while [ "$i" -lt 256 ]; do
    printf 'authorization: Bearer abcdefghijklmnopqrstuvwxyz%06d\n' "$i" >> "$d/evidence/02-net.txt"
    i=$((i+1))
  done
  run "$GATE" "$d" && no "hit counting" "exactly 256 credential hits reported as clean" \
                   || ok "gate does not use exit codes as counters (256 hits still fail)"
}

t_gate_resolves_symlinked_evidence() {
  local d="$WORK/run-symev"; make_run "$d"
  printf 'secret outside\n' > "$WORK/outside-ev.png"
  ln -s "$WORK/outside-ev.png" "$d/evidence/linked.png"
  printf 'home\tmobile\thappy\tcovered\tevidence/linked.png\n' >> "$d/coverage.tsv"
  printf 'home\tmobile\thappy\trequired\t\n' >> "$d/coverage-required.tsv"
  run "$GATE" "$d" && no "symlinked evidence" "evidence symlinked outside the run dir accepted" \
                   || ok "gate resolves symlinks when containing evidence paths"
}

t_gate_catches_duplicate_coverage_row() {
  local d="$WORK/run-dupcov"; make_run "$d"
  printf 'home\tdesktop\thappy\tcovered\tevidence/01-home.png\n' >> "$d/coverage.tsv"
  run "$GATE" "$d" && no "duplicate coverage" "the same cell was accounted for twice" \
                   || ok "gate rejects a duplicate coverage row"
}

t_gate_catches_empty_read_declaration() {
  local d="$WORK/run-emptydecl"; make_run "$d"
  printf 'Pass A.\n\n## Read declaration\n' > "$d/pass-a-report.md"
  write_debrief "$d"
  run "$GATE" "$d" && no "empty declaration" "a heading with no content passed as a declaration" \
                   || ok "gate rejects an empty read-declaration section"
}

t_gate_requires_defect_priority() {
  local d="$WORK/run-noprio"; make_run "$d"
  sed -i '/^  priority: /d' "$d/findings.md"
  run "$GATE" "$d" && no "priority required" "a product-defect with no priority passed" \
                   || ok "gate requires priority on product defects (severity is not priority)"
}

t_gate_checks_severity_vocabulary() {
  local d="$WORK/run-vocab"; make_run "$d"
  sed -i 's/^  class: product-defect/  class: experience-opportunity/' "$d/findings.md"
  run "$GATE" "$d" && no "severity vocabulary" "an opportunity carried a defect severity" \
                   || ok "gate rejects a class/severity vocabulary mismatch"
}

t_gate_cohort_needs_two_personas() {
  local d="$WORK/run-cohort1"; make_run "$d"
  printf 'cohort summary\n' > "$d/cohort-summary.md"
  mkdir -p "$d/personas/novice"
  cp "$d/pass-a-report.md" "$d/personas/novice/"
  cp "$d/exit-interview.md" "$d/personas/novice/"
  {
    printf 'PROOF\n'
    printf 'sha256(personas/novice/pass-a-report.md) = %s\n' "$(hash_of "$d/personas/novice/pass-a-report.md")"
    printf 'sha256(personas/novice/exit-interview.md) = %s\n' "$(hash_of "$d/personas/novice/exit-interview.md")"
  } > "$d/debrief.md"
  run "$GATE" "$d" --cohort \
    && no "cohort size" "a one-persona cohort passed as a cohort" \
    || ok "gate rejects a cohort of one (a single-persona run mislabeled)"
}

t_gate_rejects_unknown_class() {
  local d="$WORK/run-cls"; make_run "$d"
  sed -i 's/^  class: product-defect/  class: nitpick/' "$d/findings.md"
  run "$GATE" "$d" && no "class validation" "an unknown finding class passed" \
                   || ok "gate rejects an unknown finding class"
}

t_gate_rejects_labels_only_declaration() {
  local d="$WORK/run-labelonly"; make_run "$d"
  printf 'Pass A.\n\n## Read declaration\nFiles read:\nCommands run:\n' > "$d/pass-a-report.md"
  write_debrief "$d"
  run "$GATE" "$d" && no "declaration content" "a declaration with only labels passed" \
                   || ok "gate rejects a read declaration containing only its labels"
}

t_gate_rejects_symlinked_persona_dir() {
  local d="$WORK/run-sympersona"; make_run "$d"
  printf 'cohort summary\n' > "$d/cohort-summary.md"
  mkdir -p "$d/personas" "$WORK/outside-persona-a" "$d/personas/b"
  for p in "$WORK/outside-persona-a" "$d/personas/b"; do
    cp "$d/pass-a-report.md" "$d/exit-interview.md" "$p/"
  done
  ln -s "$WORK/outside-persona-a" "$d/personas/a"
  run "$GATE" "$d" --cohort \
    && no "symlinked persona" "a persona directory outside the run dir was accepted" \
    || ok "gate rejects a symlinked persona directory"
}

t_gate_catches_quoted_header_credentials() {
  local d="$WORK/run-qhdr"; make_run "$d"
  printf '{"headers":{"authorization":"Bearer abcd1234efgh5678ijkl"}}\n' > "$d/evidence/04-hdr.json"
  run "$GATE" "$d" && no "quoted header scan" "a quoted JSON authorization header was missed" \
                   || ok "gate catches credentials in quoted header form"
}

# ============================================ generated-stub ownership (round 4)

t_sync_refuses_to_clobber_user_file() {
  local t; t="$(fresh_target)"
  mkdir -p "$t/skills" "$t/.claude/commands"
  cp -r "$REPO/skills/ui-qa" "$t/skills/"
  echo "MY OWN COMMAND" > "$t/.claude/commands/ui-qa.md"
  run "$REPO/scripts/sync-platform-dirs.sh" --root "$t"
  grep -q "MY OWN COMMAND" "$t/.claude/commands/ui-qa.md" \
    && ok "sync refuses to overwrite an ungenerated file at a platform path" \
    || no "stub ownership" "a user-authored command file was overwritten"
}

t_sync_refuses_to_prune_user_file() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --platforms "claude codex"
  mkdir -p "$t/.cursor/skills/ui-qa"
  echo "MY OWN CURSOR SKILL" > "$t/.cursor/skills/ui-qa/SKILL.md"
  run "$REPO/scripts/sync-platform-dirs.sh" --root "$t" --platforms claude
  grep -q "MY OWN CURSOR SKILL" "$t/.cursor/skills/ui-qa/SKILL.md" 2>/dev/null \
    && ok "prune leaves an ungenerated file alone when a platform is deselected" \
    || no "prune ownership" "a user-authored stub was deleted by pruning"
}

t_sync_still_prunes_its_own_stubs() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --platforms "claude codex cursor"
  [ -f "$t/.cursor/skills/ui-qa/SKILL.md" ] || { no "prune setup" "cursor stub absent"; return; }
  run "$REPO/scripts/sync-platform-dirs.sh" --root "$t" --platforms claude
  [ ! -e "$t/.cursor/skills/ui-qa/SKILL.md" ] \
    && ok "prune still removes stubs it generated itself" \
    || no "prune regression" "ownership check stopped legitimate pruning"
}

t_dest_inside_platform_dir_refused() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t" --dest .claude/skills/ui-qa
  if [ -f "$t/.claude/skills/ui-qa/references/charter-schema.md" ]; then
    no "self-referencing dest" "the canonical skill was installed into a generated platform dir"
  else
    ok "install refuses a --dest inside a platform directory (self-referencing stub)"
  fi
}

# ================================================================ glance mode

make_glance() {  # <dir> ; a minimal glance run that should PASS
  local d="$1"; mkdir -p "$d/evidence"; printf 'shot\n' > "$d/evidence/01.png"
  {
    printf 'GLANCE — uncalibrated, no oracles. Nothing verified as correct.\n\n'
    printf -- '- id: g-01\n  class: product-defect\n  route_state: /dashboard loaded\n'
    printf -- '  persona: capable first-time user\n  screenshot: evidence/01.png\n'
    printf -- '  observed: match rate shown with no denominator\n'
    printf -- '  principle: taxonomy 5 aggregates\n  consequence: one point reads as a trend\n'
    printf -- '  recommendation: show "11 of 15" beside the percentage\n'
    printf -- '  severity: high\n  confidence: high\n'
  } > "$d/glance.md"
}

t_glance_accepts_minimal_run() {
  local d="$WORK/glance-ok"; make_glance "$d"
  run "$GATE" "$d" --glance \
    && ok "glance gate accepts a labeled run with no profile, coverage or Pass B" \
    || no "glance gate" "a valid glance run was rejected"
}

t_glance_requires_label() {
  local d="$WORK/glance-nolabel"; make_glance "$d"
  sed -i '1s/.*/Quick UI look/' "$d/glance.md"
  run "$GATE" "$d" --glance \
    && no "glance label" "an unlabeled glance passed — it could be quoted as evidence" \
    || ok "glance gate requires the label that stops it reading as evidence"
}

t_glance_still_requires_finding_quality() {
  local d="$WORK/glance-thin"; make_glance "$d"
  printf -- '- id: g-02\n  class: observation\n  observed: feels cluttered\n' >> "$d/glance.md"
  run "$GATE" "$d" --glance \
    && no "glance finding quality" "a bare judgement passed in glance mode" \
    || ok "glance relaxes the process but not the finding-quality contract"
}

t_glance_does_not_demand_full_artifacts() {
  # The point of the mode: no coverage matrix, no hashes, no pass-b-report.
  local d="$WORK/glance-min"; make_glance "$d"
  local out; out="$("$GATE" "$d" --glance 2>&1)"
  printf '%s' "$out" | grep -qiE 'coverage-required|pass-b-report|sha256' \
    && no "glance scope" "glance gate demanded full-mode artifacts" \
    || ok "glance gate does not demand coverage, hashes or a Pass-B report"
}

t_glance_correctness_claim_needs_marker() {
  local d="$WORK/glance-claim"; make_glance "$d"
  sed -i 's|  observed: match rate shown with no denominator|  observed: the total is incorrect, it should be 15|' "$d/glance.md"
  run "$GATE" "$d" --glance \
    && no "glance authority" "a correctness verdict passed without needs_oracle" \
    || ok "glance rejects a correctness claim with no needs_oracle marker"
}

t_glance_allows_marked_oracle_question() {
  local d="$WORK/glance-q"; make_glance "$d"
  sed -i 's|  observed: match rate shown with no denominator|  observed: the total should be 15 but shows 11|' "$d/glance.md"
  printf '  needs_oracle: yes — cannot verify without the batch record\n' >> "$d/glance.md"
  run "$GATE" "$d" --glance \
    && ok "glance accepts a correctness question marked needs_oracle" \
    || no "glance authority" "a properly marked open question was rejected"
}

t_glance_flag_is_exclusive() {
  local d="$WORK/glance-excl"; make_glance "$d"
  run "$GATE" "$d" --glance --cohort \
    && no "glance flags" "--glance combined with --cohort was accepted" \
    || ok "--glance refuses to combine with --cohort/--pass-a-only"
}

t_glance_catches_credentials() {
  local d="$WORK/glance-secret"; make_glance "$d"
  printf 'authorization: Bearer abcdefghijklmnopqrstuvwxyz012345\n' > "$d/evidence/02.txt"
  run "$GATE" "$d" --glance \
    && no "glance secret scan" "a credential in glance evidence was accepted" \
    || ok "glance gate still scans evidence for credentials"
}

# =================================================================== uninstall

t_uninstall_removes_what_it_installed() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  run "$REPO/scripts/uninstall.sh" "$t"
  local left=""
  for p in skills/ui-qa .claude/skills/ui-qa/SKILL.md .claude/agents/user-zero.md \
           .claude/commands/ui-qa.md .agents/skills/ui-qa/SKILL.md \
           .codex/skills/ui-qa/SKILL.md .ui-qa-install.json; do
    [ -e "$t/$p" ] && left="$left $p"
  done
  [ -z "$left" ] && ok "uninstall removes the skill, all generated stubs and the manifest" \
                 || no "uninstall" "left behind:$left"
}

t_uninstall_keeps_user_work() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  echo "MY PROFILE" > "$t/qa/product-explorer/PROFILE.md"
  mkdir -p "$t/qa-output/2026-08-04-x-120000"; echo ev > "$t/qa-output/2026-08-04-x-120000/findings.md"
  run "$REPO/scripts/uninstall.sh" "$t"
  [ "$(cat "$t/qa/product-explorer/PROFILE.md" 2>/dev/null)" = "MY PROFILE" ] \
    && [ -f "$t/qa-output/2026-08-04-x-120000/findings.md" ] \
    && ok "uninstall keeps the explorer directory and run evidence by default" \
    || no "uninstall preservation" "user work was removed without --purge-explorer"
}

t_uninstall_purge_removes_explorer() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  run "$REPO/scripts/uninstall.sh" "$t" --purge-explorer
  [ ! -e "$t/qa/product-explorer" ] \
    && ok "--purge-explorer removes the explorer directory" \
    || no "uninstall purge" "explorer directory survived --purge-explorer"
}

t_uninstall_keeps_unowned_files() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  echo "MY OWN COMMAND" > "$t/.claude/commands/ui-qa.md"      # user replaced a stub
  mkdir -p "$t/keepme"; echo MINE > "$t/keepme/.ui-qa-managed-not"
  run "$REPO/scripts/uninstall.sh" "$t"
  grep -q "MY OWN COMMAND" "$t/.claude/commands/ui-qa.md" 2>/dev/null \
    && ok "uninstall keeps a platform file that is not marker-stamped" \
    || no "uninstall ownership" "deleted a file the harness did not generate"
}

t_uninstall_dry_run_changes_nothing() {
  local t; t="$(fresh_target)"
  run "$REPO/scripts/install.sh" "$t"
  run "$REPO/scripts/uninstall.sh" "$t" --dry-run
  [ -f "$t/skills/ui-qa/SKILL.md" ] && [ -f "$t/.ui-qa-install.json" ] \
    && ok "--dry-run changes nothing" \
    || no "uninstall dry run" "--dry-run modified the target"
}

t_uninstall_refuses_reserved_manifest_dest() {
  local t; t="$(fresh_target)"
  echo SENTINEL > "$t/.git/sentinel.txt"
  run "$REPO/scripts/install.sh" "$t"
  sed -i 's|"dest": "[^"]*"|"dest": ".git"|' "$t/.ui-qa-install.json"
  run "$REPO/scripts/uninstall.sh" "$t"
  [ -f "$t/.git/sentinel.txt" ] \
    && ok "uninstall refuses a reserved directory named by the manifest" \
    || no "uninstall P0" ".git was destroyed via the manifest"
}

# ==================================================================== fixtures

t_fixture_controls_all_armed() {
  run "$REPO/fixtures/probe.sh" --quiet \
    && ok "every fixture control is armed and the control floor is met" \
    || no "fixture drift" "fixtures/probe.sh reports missing controls"
}

t_fixture_answer_key_is_not_under_served_dir() {
  # serve.sh serves fixtures/apps only. Anything reachable over HTTP is reachable
  # by the browser the explorer drives, and /controls.tsv was fetchable before.
  local leak=""
  for f in controls.tsv probe.sh README.md explorer serve.sh; do
    [ -e "$REPO/fixtures/apps/$f" ] && leak="$leak $f"
  done
  [ -z "$leak" ] && ok "the answer key, charters and probe live outside the served directory" \
                 || no "served answer key" "reachable over HTTP:$leak"
}

t_fixture_serve_refuses_if_key_inside() {
  local tmp; tmp="$WORK/fxs$RANDOM"; cp -r "$REPO/fixtures" "$tmp"
  cp "$tmp/controls.tsv" "$tmp/apps/controls.tsv"
  run "$tmp/serve.sh" --port 8899 \
    && no "serve guard" "serve.sh started with the answer key inside the served dir" \
    || ok "serve.sh refuses to start if the answer key is inside the served directory"
}

t_fixture_served_files_have_no_comments() {
  # Comments describing the seeded defects are an answer key in the DOM. The rule
  # is mechanical because "is this comment a hint?" is not: no comments at all.
  local leak=""
  leak=$(grep -rnE '<!--|/\*|(^|[^:/])//' "$REPO/fixtures/apps" 2>/dev/null \
         | grep -viE '<!doctype' || true)
  [ -z "$leak" ] && ok "served fixture files contain no comments of any kind" \
                 || no "fixture blindness" "$leak"
}

t_fixture_clean_app_has_no_seeded_probes() {
  local hits=0
  while IFS=$'\t' read -r id class page probe antiprobe signature; do
    case "${id:-}" in ''|'#'*) continue ;; esac
    [ "$probe" = "-" ] && continue
    grep -qF -- "$probe" "$REPO/fixtures/apps/clean-app/index.html" 2>/dev/null && hits=$((hits+1))
  done < "$REPO/fixtures/controls.tsv"
  [ "$hits" -eq 0 ] && ok "the clean app contains none of the seeded defect probes" \
                    || no "exemplar purity" "$hits seeded probe(s) found in clean-app"
}

t_fixture_probe_detects_drift() {
  local tmp; tmp="$WORK/fx$RANDOM"; cp -r "$REPO/fixtures" "$tmp"
  sed -i 's/73\.4%/73% of 15 positions/' "$tmp/apps/broken-app/index.html"
  run "$tmp/probe.sh" --quiet \
    && no "probe drift detection" "probe passed after a seeded defect was edited away" \
    || ok "probe fails when a seeded defect is edited away (denominator protection)"
}

t_fixture_probe_detects_repair() {
  # A positive probe survives the repair it is meant to detect: adding an
  # aria-label fixes the unnamed-button control without changing the markup.
  local tmp; tmp="$WORK/fxr$RANDOM"; cp -r "$REPO/fixtures" "$tmp"
  sed -i 's|onclick="removeRow(this)|aria-label="Delete position" onclick="removeRow(this)|g' \
    "$tmp/apps/broken-app/index.html"
  local out; out="$("$tmp/probe.sh" --quiet 2>&1)"
  if printf '%s' "$out" | grep -q 'REPAIRED KD-A02\|REPAIRED  KD-A02'; then
    ok "probe reports REPAIRED when a control's fix is applied (antiprobe)"
  else
    no "antiprobe" "probe did not notice that KD-A02 was repaired"
  fi
}

# ============================================================ layer purity

t_layer1_has_no_product_strings() {
  local hits
  hits=$(grep -rniIE 'localhost:[0-9]+|(^|[^a-zA-Z$])/(home|Users)/' \
         "$REPO/skills" "$REPO/templates" 2>/dev/null || true)
  [ -z "$hits" ] && ok "Layer 1 and templates carry no machine or product paths" \
                 || no "layer purity" "$hits"
}

t_purity_hook_scans_staged_content() {
  local t; t="$(fresh_target)"
  cp -r "$REPO/scripts" "$REPO/.githooks" "$REPO/skills" "$REPO/templates" "$t/"
  git -C "$t" add -A >/dev/null && git -C "$t" -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1
  # Stage a leak, then remove it from the worktree only.
  printf '\nsee /home/someone/notes.md\n' >> "$t/skills/ui-qa/SKILL.md"
  git -C "$t" add skills/ui-qa/SKILL.md
  git -C "$t" checkout-index -f -- skills/ui-qa/SKILL.md 2>/dev/null
  sed -i '/see \/home\/someone/d' "$t/skills/ui-qa/SKILL.md"
  if ( cd "$t" && run ./.githooks/pre-commit ); then
    no "purity hook staged scan" "a staged leak passed because the worktree was clean"
  else ok "purity hook scans staged content, not the working tree"; fi
}

t_all_skill_refs_resolve() {
  local missing=""
  cd "$REPO/skills/ui-qa" || return
  while read -r p; do [ -e "$p" ] || missing="$missing $p"; done < <(
    grep -rhoE '(references|lenses|adapters|agents|scripts)/[a-zA-Z0-9._-]+\.(md|sh|yaml|py)' . | sort -u)
  cd "$REPO" || return
  [ -z "$missing" ] && ok "every intra-skill file reference resolves" \
                    || no "dangling references" "$missing"
}

for t in \
  t_dest_traversal t_dest_absolute t_dest_metachars t_no_injection_marker \
  t_explorer_dir_validated t_refuses_self \
  t_manifest_cannot_direct_deletion t_refuses_unowned_directory \
  t_owned_directory_is_replaceable t_reserved_dirs_refused \
  t_sync_refuses_symlinked_platform_dir t_install_refuses_symlinked_dest \
  t_install_preserves_user_content t_manifest_persists_explorer_dir t_placeholder_resolved \
  t_codex_documented_location t_adapter_drives_tool_grant t_adapter_claude_chrome \
  t_narrowing_platforms_prunes \
  t_check_detects_worktree_drift t_check_platforms_forwarded \
  t_check_from_index_catches_partial_staging t_from_index_uses_staged_generator \
  t_gate_accepts_complete_run t_gate_requires_pass_b t_gate_requires_read_declaration \
  t_gate_hashes_are_artifact_bound t_gate_catches_tampering \
  t_gate_catches_uncovered_cell t_gate_catches_evidence_escape \
  t_gate_requires_independent_denominator t_gate_catches_reasonless_gap \
  t_gate_per_record_fields \
  t_gate_catches_credentials t_gate_redaction_is_per_token t_gate_catches_json_credentials \
  t_gate_does_not_echo_secrets \
  t_gate_catches_stack_dir_collision t_gate_cohort_requires_personas \
  t_gate_scans_unterminated_final_line t_gate_counts_beyond_256 \
  t_gate_resolves_symlinked_evidence t_gate_catches_duplicate_coverage_row \
  t_gate_catches_empty_read_declaration t_gate_requires_defect_priority \
  t_gate_checks_severity_vocabulary t_gate_cohort_needs_two_personas \
  t_glance_accepts_minimal_run t_glance_requires_label \
  t_glance_still_requires_finding_quality t_glance_does_not_demand_full_artifacts \
  t_glance_correctness_claim_needs_marker t_glance_allows_marked_oracle_question \
  t_glance_flag_is_exclusive t_glance_catches_credentials \
  t_uninstall_removes_what_it_installed t_uninstall_keeps_user_work \
  t_uninstall_purge_removes_explorer t_uninstall_keeps_unowned_files \
  t_uninstall_dry_run_changes_nothing t_uninstall_refuses_reserved_manifest_dest \
  t_gate_rejects_unknown_class t_gate_rejects_labels_only_declaration \
  t_gate_rejects_symlinked_persona_dir t_gate_catches_quoted_header_credentials \
  t_sync_refuses_to_clobber_user_file t_sync_refuses_to_prune_user_file \
  t_sync_still_prunes_its_own_stubs t_dest_inside_platform_dir_refused \
  t_fixture_controls_all_armed t_fixture_answer_key_is_not_under_served_dir \
  t_fixture_serve_refuses_if_key_inside t_fixture_served_files_have_no_comments \
  t_fixture_clean_app_has_no_seeded_probes t_fixture_probe_detects_drift \
  t_fixture_probe_detects_repair \
  t_layer1_has_no_product_strings t_purity_hook_scans_staged_content \
  t_all_skill_refs_resolve; do
  "$t"
done

echo
echo "tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
