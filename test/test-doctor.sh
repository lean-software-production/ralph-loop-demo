#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
mkdir -p "$test_tmp/bin" "$test_tmp/home/.pi/agent"
printf '{}' > "$test_tmp/home/.pi/agent/auth.json"

for name in node npm git; do
  cat > "$test_tmp/bin/$name" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$test_tmp/bin/$name"
done
cat > "$test_tmp/bin/pi" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo 'pi test'; fi
EOF
cat > "$test_tmp/bin/claude" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo 'claude test'; fi
exit 1
EOF
cat > "$test_tmp/bin/codex" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo 'codex test'; exit 0; fi
if [ "${1:-}" = "login" ] && [ "${2:-}" = "status" ] && [ "${CODEX_STUB_AUTH:-}" = 1 ]; then exit 0; fi
exit 1
EOF
chmod +x "$test_tmp/bin/pi" "$test_tmp/bin/claude" "$test_tmp/bin/codex"

PATH="$test_tmp/bin:$PATH" HOME="$test_tmp/home" NO_COLOR=1 "$repo_root/bin/doctor" > "$test_tmp/default.out"
grep -F 'PASS ready: selected requirement is configured' "$test_tmp/default.out" >/dev/null

if PATH="$test_tmp/bin:$PATH" HOME="$test_tmp/home" NO_COLOR=1 "$repo_root/bin/doctor" --agent codex >/dev/null 2>&1; then
  echo 'unconfigured selected agent unexpectedly succeeded' >&2
  exit 1
fi
if PATH="$test_tmp/bin:$PATH" HOME="$test_tmp/home" NO_COLOR=1 "$repo_root/bin/doctor" --agent all >/dev/null 2>&1; then
  echo '--agent all unexpectedly succeeded' >&2
  exit 1
fi
printf '{}' > "$test_tmp/home/.claude.json"
PATH="$test_tmp/bin:$PATH" HOME="$test_tmp/home" NO_COLOR=1 CODEX_STUB_AUTH=1 "$repo_root/bin/doctor" --agent all > "$test_tmp/all.out"
grep -F 'PASS ready: selected requirement is configured' "$test_tmp/all.out" >/dev/null
if "$repo_root/bin/doctor" --agent nope >/dev/null 2>&1; then
  echo 'invalid agent unexpectedly succeeded' >&2
  exit 1
fi
echo 'doctor tests passed'
