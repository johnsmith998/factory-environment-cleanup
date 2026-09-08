#!/usr/bin/env bash
# Push using GitHub Personal Access Token (classic) over HTTPS.
# Does not store the token in git config — reads from .env.local only.
#
# Per-project .env.local (required):
#   GITHUB_REPO=owner/repo          # or https://github.com/owner/repo.git
#   GITHUB_TOKEN=ghp_xxxxxxxx
#
# Usage:  npm run git:push [branch]
# PAT:    GitHub → Settings → Developer settings → Tokens (classic) → repo scope
#
# Template: ~/.cursor/templates/git-push-with-pat.sh
# Install:  bash ~/.cursor/templates/install-git-push-into-project.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env.local ]]; then
  # shellcheck disable=SC1091
  set -a
  # shellcheck disable=SC1090
  source .env.local
  set +a
fi

normalize_github_repo() {
  local ref="${1:-}"
  ref="${ref#https://github.com/}"
  ref="${ref#http://github.com/}"
  ref="${ref#git@github.com:}"
  ref="${ref%.git}"
  ref="${ref%/}"
  echo "$ref"
}

if [[ -z "${GITHUB_REPO:-}" ]] && git rev-parse --is-inside-work-tree &>/dev/null; then
  ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$ORIGIN" ]]; then
    GITHUB_REPO="$(normalize_github_repo "$ORIGIN")"
  fi
fi

GITHUB_REPO="$(normalize_github_repo "${GITHUB_REPO:-}")"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Missing GITHUB_TOKEN in .env.local"
  echo "Add: GITHUB_TOKEN=ghp_xxxxxxxx  (classic PAT with 'repo' scope)"
  exit 1
fi

if [[ -z "$GITHUB_REPO" ]] || [[ ! "$GITHUB_REPO" =~ ^[^/]+/[^/]+$ ]]; then
  echo "Missing or invalid GITHUB_REPO in .env.local"
  echo "Add: GITHUB_REPO=owner/repo   (example: your-org/your-repo)"
  exit 1
fi

OWNER="${GITHUB_REPO%%/*}"
BRANCH="${1:-main}"
REMOTE_URL="https://${OWNER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"

echo "Pushing ${BRANCH} to github.com/${GITHUB_REPO} (HTTPS + PAT)…"
git push "${REMOTE_URL}" "${BRANCH}"

echo "Done."
