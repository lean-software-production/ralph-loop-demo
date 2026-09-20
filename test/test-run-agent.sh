#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
mkdir -p "$test_tmp/bin"
printf 'do the exercise\n' > "$test_tmp/prompt.md"

make_stub() {
  local name="$1"
  cat > "$test_tmp/bin/$name" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$0 $*" >> "$STUB_LOG"
if [ "${1:-}" = "-p" ] && [ "$#" -eq 1 ]; then cat >> "$STUB_LOG"; fi
EOF
  chmod +x "$test_tmp/bin/$name"
}
make_stub pi
make_stub claude
make_stub codex

PATH="$test_tmp/bin:$PATH" STUB_LOG="$test_tmp/pi.log" "$repo_root/bin/run-agent" "$test_tmp/prompt.md"
grep -Fx "$test_tmp/bin/pi -p" "$test_tmp/pi.log" >/dev/null
grep -Fx 'do the exercise' "$test_tmp/pi.log" >/dev/null

PATH="$test_tmp/bin:$PATH" STUB_LOG="$test_tmp/claude.log" "$repo_root/bin/run-agent" --agent claude "$test_tmp/prompt.md"
grep -Fx "$test_tmp/bin/claude -p do the exercise" "$test_tmp/claude.log" >/dev/null

PATH="$test_tmp/bin:$PATH" STUB_LOG="$test_tmp/codex.log" "$repo_root/bin/run-agent" --agent codex "$test_tmp/prompt.md"
grep -Fx "$test_tmp/bin/codex exec --approve-for-me do the exercise" "$test_tmp/codex.log" >/dev/null

if PATH="$test_tmp/bin:$PATH" "$repo_root/bin/run-agent" --agent unknown "$test_tmp/prompt.md" >/dev/null 2>&1; then
  echo 'unknown agent unexpectedly succeeded' >&2
  exit 1
fi
echo 'run-agent tests passed'
