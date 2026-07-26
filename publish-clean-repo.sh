#!/usr/bin/env bash
set -euo pipefail

# Validate a prepared public checkout before it is pushed. This intentionally
# does not copy the private repository: publication is allowlisted by review,
# and this script is the final fail-closed gate.

repo_path="${1:-.}"
cd "$repo_path"

if [[ ! -d .git && ! -f .git ]]; then
  echo "error: not a Git checkout: $repo_path" >&2
  exit 1
fi

denylist=.public-export-denylist
if [[ ! -s "$denylist" ]]; then
  echo "error: missing publication denylist: $denylist" >&2
  exit 1
fi

echo "Checking forbidden public paths..."
forbidden="$(git ls-files | grep -Ef "$denylist" || true)"
if [[ -n "$forbidden" ]]; then
  echo "error: private-only paths are tracked:" >&2
  printf '%s\n' "$forbidden" >&2
  exit 1
fi

echo "Checking common credential filenames..."
sensitive_names="$(git ls-files | grep -Ei '(^|/)(\.env|credentials?|secrets?)(\.|$)|\.(key|pem|token)$' | grep -Ev '\.example($|\.)' || true)"
if [[ -n "$sensitive_names" ]]; then
  echo "error: suspicious tracked filenames:" >&2
  printf '%s\n' "$sensitive_names" >&2
  exit 1
fi

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "error: gitleaks is required for publication validation" >&2
  exit 1
fi

echo "Scanning the working tree with gitleaks..."
gitleaks dir . --redact --no-banner

echo "Checking for unstaged or uncommitted publication changes..."
if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: the checkout is not clean" >&2
  git status --short >&2
  exit 1
fi

echo "Public checkout validation passed."
