#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v luac >/dev/null 2>&1; then
  echo "error: luac is required" >&2
  exit 1
fi

if [[ ! -f plugins/wezterm-ollama/plugin/init.lua ]]; then
  echo "error: plugins/wezterm-ollama is not initialized" >&2
  echo "run: git submodule update --init --recursive" >&2
  exit 1
fi

while IFS= read -r -d '' file; do
  luac -p "$file"
done < <(git ls-files -z '*.lua')
luac -p plugins/wezterm-ollama/plugin/init.lua

for test_file in tests/*-test.lua; do
  lua "$test_file"
done

if command -v wezterm >/dev/null 2>&1; then
  wezterm_version="$(wezterm --version)"
  if [[ -n "${WEZTERM_EXPECTED_VERSION:-}" && "$wezterm_version" != "wezterm $WEZTERM_EXPECTED_VERSION" ]]; then
    echo "error: expected WezTerm $WEZTERM_EXPECTED_VERSION, found: $wezterm_version" >&2
    exit 1
  fi
  wezterm --config-file "$repo_root/wezterm.lua" show-keys --key-table default >/dev/null
elif [[ "${REQUIRE_WEZTERM:-0}" == "1" || "${CI:-}" == "true" || "${CI:-}" == "1" ]]; then
  echo "error: wezterm is required for configuration validation" >&2
  exit 1
else
  echo "warning: wezterm not found; skipping WezTerm API validation" >&2
fi

echo "Configuration checks passed."
