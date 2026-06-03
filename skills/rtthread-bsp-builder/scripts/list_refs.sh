#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/RT-Thread/rt-thread.git"
TYPE="all"
LIMIT=30

usage() {
  cat <<'EOF'
Usage: list_refs.sh [--type branches|tags|all] [--limit N]

List recent remote branches/tags from the official RT-Thread repository.
Use this when the user wants to choose a repository version before cloning/building.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --type)
      TYPE="$2"; shift 2 ;;
    --limit)
      LIMIT="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

case "$TYPE" in
  branches)
    git ls-remote --heads "$REPO_URL" | sed 's#.*refs/heads/##' | sort | tail -n "$LIMIT"
    ;;
  tags)
    git ls-remote --tags "$REPO_URL" | sed 's#.*refs/tags/##' | sed 's/\^{}$//' | sort -Vu | tail -n "$LIMIT"
    ;;
  all)
    echo "[branches]"
    git ls-remote --heads "$REPO_URL" | sed 's#.*refs/heads/##' | sort | tail -n "$LIMIT"
    echo
    echo "[tags]"
    git ls-remote --tags "$REPO_URL" | sed 's#.*refs/tags/##' | sed 's/\^{}$//' | sort -Vu | tail -n "$LIMIT"
    ;;
  *)
    echo "Invalid --type: $TYPE" >&2
    exit 2 ;;
esac
