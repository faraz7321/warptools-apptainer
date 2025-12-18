#!/usr/bin/env bash
set -euo pipefail

fail=0

echo "Lint: checking shell scripts with shellcheck (if available)"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/*.sh
else
  echo "shellcheck not installed; skipping"
fi

echo "Lint: checking YAML with yamllint (if available)"
if command -v yamllint >/dev/null 2>&1; then
  mapfile -t yaml_files < <(git ls-files '*.yml' '*.yaml')
  if [[ "${#yaml_files[@]}" -gt 0 ]]; then
    yamllint -d "{extends: default, rules: {line-length: {max: 120}}}" "${yaml_files[@]}" || fail=1
  fi
else
  echo "yamllint not installed; skipping"
fi

exit "${fail}"
