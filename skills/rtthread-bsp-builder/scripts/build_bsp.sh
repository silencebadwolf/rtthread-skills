#!/usr/bin/env bash
set -euo pipefail

REPO=""
BSP=""
PREFLIGHT=0
JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"

usage() {
  cat <<'EOF'
Usage: build_bsp.sh --repo <repo> --bsp <bsp-path-or-name> [--preflight]

Run preflight or the default GCC build flow for an official RT-Thread BSP.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="$2"; shift 2 ;;
    --bsp)
      BSP="$2"; shift 2 ;;
    --preflight)
      PREFLIGHT=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

[ -n "$REPO" ] || { echo "--repo is required" >&2; exit 2; }
[ -n "$BSP" ] || { echo "--bsp is required" >&2; exit 2; }

resolve_bsp() {
  if [ -d "$REPO/$BSP" ]; then
    printf '%s\n' "$REPO/$BSP"
    return 0
  fi
  if [ -d "$REPO/bsp/$BSP" ]; then
    printf '%s\n' "$REPO/bsp/$BSP"
    return 0
  fi
  local found
  found="$(find "$REPO/bsp" -type f -name SConstruct -path "*/$BSP/SConstruct" | head -n1 || true)"
  if [ -n "$found" ]; then
    dirname "$found"
    return 0
  fi
  return 1
}

pick_readme() {
  local dir="$1"
  for name in README.md README_zh.md README_ZH.md readme.md readme_en.md; do
    if [ -f "$dir/$name" ]; then
      printf '%s\n' "$dir/$name"
      return 0
    fi
  done
  return 1
}

parse_prefix() {
  local rtconfig="$1"
  python - "$rtconfig" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding='utf-8', errors='ignore') if p.exists() else ''
m = re.search(r"PREFIX\s*=\s*'([^']*)'", text)
print(m.group(1) if m else '')
PY
}

BSP_DIR="$(resolve_bsp)" || { echo "error=bsp_not_found"; exit 1; }
README="$(pick_readme "$BSP_DIR" || true)"
RTCONFIG="$BSP_DIR/rtconfig.py"
PREFIX="$(parse_prefix "$RTCONFIG")"
CC_BIN="${PREFIX}gcc"

printf 'repo=%s\n' "$REPO"
printf 'bsp_dir=%s\n' "$BSP_DIR"
printf 'readme=%s\n' "${README:-}"
printf 'rtconfig=%s\n' "$RTCONFIG"
printf 'compiler_prefix=%s\n' "$PREFIX"

if ! command -v scons >/dev/null 2>&1; then
  echo "missing=scons"
  exit 3
fi

if [ -n "$PREFIX" ] && ! command -v "$CC_BIN" >/dev/null 2>&1; then
  echo "missing_compiler=$CC_BIN"
  if [ -n "${RTT_EXEC_PATH:-}" ]; then
    echo "RTT_EXEC_PATH=${RTT_EXEC_PATH}"
  fi
  exit 4
fi

NEEDS_PKGS=0
if [ -n "$README" ] && grep -qi 'pkgs --update' "$README"; then
  NEEDS_PKGS=1
  if ! command -v pkgs >/dev/null 2>&1; then
    echo "missing=pkgs"
    exit 5
  fi
fi

echo "preflight=ok"
if [ "$PREFLIGHT" -eq 1 ]; then
  exit 0
fi

cd "$BSP_DIR"
if [ "$NEEDS_PKGS" -eq 1 ]; then
  echo "+ pkgs --update"
  pkgs --update
fi

echo "+ scons -j$JOBS"
scons -j"$JOBS"

echo "artifacts:"
find "$BSP_DIR" -maxdepth 2 -type f \( -name 'rtthread.bin' -o -name 'rt-thread.hex' -o -name '*.elf' -o -name '*.axf' -o -name '*.out' -o -name 'rtthread.map' -o -name 'rt-thread.map' \) | sort
