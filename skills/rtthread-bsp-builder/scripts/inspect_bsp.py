#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
from pathlib import Path

README_NAMES = ["README.md", "README_zh.md", "README_ZH.md", "readme.md", "readme_en.md"]


def find_bsp_dir(repo: Path, bsp_arg: str) -> Path | None:
    p = repo / bsp_arg
    if p.is_dir():
        return p
    p = repo / 'bsp' / bsp_arg
    if p.is_dir():
        return p
    for sconstruct in (repo / 'bsp').rglob('SConstruct'):
        if sconstruct.parent.name == bsp_arg:
            return sconstruct.parent
    return None


def readme_path(bsp_dir: Path):
    for name in README_NAMES:
        p = bsp_dir / name
        if p.exists():
            return p
    return None


def parse_rtconfig(rtconfig: Path | None):
    info = {
        "cross_tool_default": None,
        "prefix": None,
        "uses_rtt_exec_path": False,
        "uses_rtt_cc_prefix": False,
        "uses_rtt_cc": False,
    }
    if not rtconfig or not rtconfig.exists():
        return info
    text = rtconfig.read_text(encoding='utf-8', errors='ignore')
    m = re.search(r"CROSS_TOOL\s*=\s*'([^']+)'", text)
    if m:
        info["cross_tool_default"] = m.group(1)
    m = re.search(r"PREFIX\s*=\s*'([^']*)'", text)
    if m:
        info["prefix"] = m.group(1)
    info["uses_rtt_exec_path"] = 'RTT_EXEC_PATH' in text
    info["uses_rtt_cc_prefix"] = 'RTT_CC_PREFIX' in text
    info["uses_rtt_cc"] = 'RTT_CC' in text
    return info


def parse_readme(readme: Path | None):
    info = {
        "pkgs_update_required": False,
        "menuconfig_mentions": [],
        "gcc_mentions": [],
        "mdk_mentions": [],
        "iar_mentions": [],
    }
    if not readme or not readme.exists():
        return info
    lines = readme.read_text(encoding='utf-8', errors='ignore').splitlines()
    for i, line in enumerate(lines, 1):
        low = line.lower()
        if 'pkgs --update' in low:
            info["pkgs_update_required"] = True
        if 'menuconfig' in low:
            info["menuconfig_mentions"].append({"line": i, "text": line.strip()[:220]})
        if 'gcc' in low:
            info["gcc_mentions"].append({"line": i, "text": line.strip()[:220]})
        if 'mdk' in low or 'keil' in low:
            info["mdk_mentions"].append({"line": i, "text": line.strip()[:220]})
        if 'iar' in low:
            info["iar_mentions"].append({"line": i, "text": line.strip()[:220]})
    return info


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', required=True)
    ap.add_argument('--bsp', required=True)
    args = ap.parse_args()

    repo = Path(args.repo)
    bsp_dir = find_bsp_dir(repo, args.bsp)
    if not bsp_dir:
        print(json.dumps({"error": "bsp not found", "bsp": args.bsp, "repo": str(repo)}))
        return 1

    readme = readme_path(bsp_dir)
    rtconfig = bsp_dir / 'rtconfig.py'
    out = {
        "repo": str(repo),
        "bsp": bsp_dir.relative_to(repo).as_posix(),
        "readme": str(readme) if readme else None,
        "rtconfig": str(rtconfig) if rtconfig.exists() else None,
        "sconstruct": str(bsp_dir / 'SConstruct') if (bsp_dir / 'SConstruct').exists() else None,
        "rtconfig_info": parse_rtconfig(rtconfig if rtconfig.exists() else None),
        "readme_info": parse_readme(readme),
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
