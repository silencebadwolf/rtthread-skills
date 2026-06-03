#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/RT-Thread/rt-thread.git"
DEST=""
UPDATE=0
REF=""

usage() {
  cat <<'EOF'
Usage: ensure_repo.sh --dest <path> [--update] [--ref <branch|tag|commit>]

Clone the official RT-Thread repository if missing.
If the destination already contains a git repo, verify the origin and optionally fast-forward it.
If --ref is provided, checkout that branch/tag/commit safely (refuses on dirty repo).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)
      DEST="$2"; shift 2 ;;
    --update)
      UPDATE=1; shift ;;
    --ref)
      REF="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

[ -n "$DEST" ] || { echo "--dest is required" >&2; exit 2; }

checkout_ref() {
  local repo="$1"
  local ref="$2"
  [ -n "$ref" ] || return 0
  git -C "$repo" fetch --depth 1 origin "$ref" >/dev/null 2>&1 || git -C "$repo" fetch --tags origin >/dev/null 2>&1 || true
  if git -C "$repo" rev-parse --verify --quiet "origin/$ref" >/dev/null; then
    git -C "$repo" checkout -B "$ref" "origin/$ref"
    echo "checked_out_ref=origin/$ref"
    return 0
  fi
  if git -C "$repo" rev-parse --verify --quiet "$ref" >/dev/null; then
    git -C "$repo" checkout "$ref"
    echo "checked_out_ref=$ref"
    return 0
  fi
  echo "error=ref_not_found"
  echo "ref=$ref"
  exit 6
}

if [ -d "$DEST/.git" ]; then
  origin="$(git -C "$DEST" remote get-url origin 2>/dev/null || true)"
  branch="$(git -C "$DEST" branch --show-current 2>/dev/null || true)"
  dirty="$(git -C "$DEST" status --porcelain 2>/dev/null || true)"
  head="$(git -C "$DEST" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_exists=1"
  echo "repo_path=$DEST"
  echo "origin=$origin"
  echo "branch=${branch:-detached}"
  echo "head=$head"
  if [ -n "$dirty" ]; then
    echo "dirty=1"
  else
    echo "dirty=0"
  fi
  if [ "$UPDATE" -eq 1 ]; then
    if [ -n "$dirty" ]; then
      echo "update_skipped=dirty_repo"
      exit 0
    fi
    git -C "$DEST" fetch --depth 1 origin
    if [ -n "$branch" ]; then
      git -C "$DEST" pull --ff-only origin "$branch"
    else
      echo "update_skipped=detached_head"
    fi
    echo "updated=1"
  fi
  if [ -n "$REF" ]; then
    if [ -n "$dirty" ]; then
      echo "checkout_skipped=dirty_repo"
      exit 0
    fi
    checkout_ref "$DEST" "$REF"
  fi
  exit 0
fi

mkdir -p "$(dirname "$DEST")"
git clone --depth 1 "$REPO_URL" "$DEST"
if [ -n "$REF" ]; then
  checkout_ref "$DEST" "$REF"
fi
echo "repo_exists=1"
echo "repo_path=$DEST"
echo "origin=$REPO_URL"
echo "dirty=0"
echo "updated=0"
echo "head=$(git -C "$DEST" rev-parse HEAD 2>/dev/null || true)"
