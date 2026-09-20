#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
mkdir -p "$test_tmp/bin" "$test_tmp/home/.pi/agent"
printf '{"pi-test":{"type":"api_key"}}' > "$test_tmp/home/.pi/agent/auth.json"
export PI_PROVIDER=pi-test
test_path="$test_tmp/bin:/usr/bin:/bin"

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
if [ "${1:-}" = "auth" ] && [ "${2:-}" = "check" ]; then
  [ "${PI_STUB_AUTH:-unknown}" = ready ] && exit 0
  exit 1
fi
EOF
cat > "$test_tmp/bin/claude" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo 'claude test'; fi
if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
  [ "${CLAUDE_STUB_AUTH:-unknown}" = ready ] && exit 0
  exit 1
fi
exit 1
EOF
cat > "$test_tmp/bin/codex" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo 'codex test'; exit 0; fi
if [ "${1:-}" = "login" ] && [ "${2:-}" = "status" ] && [ "${CODEX_STUB_AUTH:-}" = 1 ]; then exit 0; fi
exit 1
EOF
chmod +x "$test_tmp/bin/pi" "$test_tmp/bin/claude" "$test_tmp/bin/codex"

PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready "$repo_root/bin/doctor" > "$test_tmp/default.out"
grep -F 'PASS ready: selected requirement is configured' "$test_tmp/default.out" >/dev/null

# Exercise provider/default discovery with the real Node runtime, not its stub.
mkdir "$test_tmp/agent-bin"
for agent in pi claude codex; do ln -s "$test_tmp/bin/$agent" "$test_tmp/agent-bin/$agent"; done
printf '{"defaultProvider":"pi-test","defaultModel":"example-model"}' > "$test_tmp/home/.pi/agent/settings.json"
env -u PI_PROVIDER PATH="$test_tmp/agent-bin:$PATH" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready "$repo_root/bin/doctor" --agent pi > "$test_tmp/discovered.out"
grep -F 'PASS pi authentication verified for provider pi-test' "$test_tmp/discovered.out" >/dev/null
grep -F 'PASS pi model/default selection: pi-test/example-model' "$test_tmp/discovered.out" >/dev/null
printf '{not-json' > "$test_tmp/home/.pi/agent/auth.json"
rm "$test_tmp/home/.pi/agent/settings.json"
if env -u PI_PROVIDER PATH="$test_tmp/agent-bin:$PATH" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready "$repo_root/bin/doctor" --agent pi >/dev/null 2>&1; then
  echo 'indeterminate Pi configuration unexpectedly succeeded' >&2
  exit 1
fi
printf '{"pi-test":{"type":"api_key"}}' > "$test_tmp/home/.pi/agent/auth.json"

if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=stale "$repo_root/bin/doctor" --agent pi >/dev/null 2>&1; then
  echo 'stale Pi authentication unexpectedly succeeded' >&2
  exit 1
fi
if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=unknown "$repo_root/bin/doctor" --agent pi >/dev/null 2>&1; then
  echo 'unknown Pi authentication unexpectedly succeeded' >&2
  exit 1
fi
if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready CLAUDE_STUB_AUTH=stale "$repo_root/bin/doctor" --agent claude >/dev/null 2>&1; then
  echo 'stale Claude authentication unexpectedly succeeded' >&2
  exit 1
fi
if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready CLAUDE_STUB_AUTH=unknown "$repo_root/bin/doctor" --agent claude >/dev/null 2>&1; then
  echo 'unknown Claude authentication unexpectedly succeeded' >&2
  exit 1
fi
if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready "$repo_root/bin/doctor" --agent codex >/dev/null 2>&1; then
  echo 'unconfigured selected agent unexpectedly succeeded' >&2
  exit 1
fi
if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready "$repo_root/bin/doctor" --agent all >/dev/null 2>&1; then
  echo '--agent all unexpectedly succeeded' >&2
  exit 1
fi
PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready CLAUDE_STUB_AUTH=ready CODEX_STUB_AUTH=1 "$repo_root/bin/doctor" --agent all > "$test_tmp/all.out"
grep -F 'PASS ready: selected requirement is configured' "$test_tmp/all.out" >/dev/null
for agent in pi claude codex; do
  mv "$test_tmp/bin/$agent" "$test_tmp/$agent-hidden"
  if PATH="$test_path" HOME="$test_tmp/home" NO_COLOR=1 PI_STUB_AUTH=ready CLAUDE_STUB_AUTH=ready CODEX_STUB_AUTH=1 "$repo_root/bin/doctor" >/dev/null 2>&1; then
    echo "missing $agent executable unexpectedly succeeded" >&2
    exit 1
  fi
  mv "$test_tmp/$agent-hidden" "$test_tmp/bin/$agent"
done
if "$repo_root/bin/doctor" --agent nope >/dev/null 2>&1; then
  echo 'invalid agent unexpectedly succeeded' >&2
  exit 1
fi
echo 'doctor tests passed'
