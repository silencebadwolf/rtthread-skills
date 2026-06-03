#!/usr/bin/env python3
import argparse
import difflib
import json
import re
import sys
from pathlib import Path


README_NAMES = ["README.md", "README_zh.md", "README_ZH.md", "readme.md", "readme_en.md"]


def norm(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def token_set(text: str) -> set[str]:
    n = norm(text)
    return set(n.split()) if n else set()


def score(query: str, rel: str) -> float:
    q = norm(query)
    r = norm(rel)
    base = difflib.SequenceMatcher(None, q, r).ratio()
    if q == r or q == norm(Path(rel).name):
        base += 1.5
    elif q and q in r:
        base += 0.7
    q_tokens = set(q.split())
    r_tokens = set(r.split())
    if q_tokens:
        overlap = len(q_tokens & r_tokens) / len(q_tokens)
        base += overlap
    return round(base, 4)


def find_readme(path: Path):
    for name in README_NAMES:
        p = path / name
        if p.exists():
            return str(p)
    return None


def is_strong_match(query: str, rel: str, name: str, match_score: float) -> bool:
    q = norm(query)
    if not q:
        return False

    norm_name = norm(name)
    norm_rel = norm(rel)
    q_tokens = token_set(query)
    name_tokens = token_set(name)
    rel_tokens = token_set(rel)

    exact = q == norm_name or q == norm_rel
    contains = q in norm_name or q in norm_rel
    token_subset = bool(q_tokens) and (q_tokens <= name_tokens or q_tokens <= rel_tokens)

    return exact or token_subset or (contains and match_score >= 1.0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--query", required=True)
    ap.add_argument("--limit", type=int, default=10)
    args = ap.parse_args()

    repo = Path(args.repo)
    bsp_root = repo / "bsp"
    if not bsp_root.is_dir():
        print(json.dumps({"error": "bsp directory not found", "repo": str(repo)}, ensure_ascii=False, indent=2))
        return 1

    rows = []
    for sconstruct in bsp_root.rglob("SConstruct"):
        bsp_dir = sconstruct.parent
        rel = bsp_dir.relative_to(repo).as_posix()
        match_score = score(args.query, rel)
        rows.append(
            {
                "path": rel,
                "name": bsp_dir.name,
                "score": match_score,
                "readme": find_readme(bsp_dir),
                "rtconfig": str((bsp_dir / "rtconfig.py")) if (bsp_dir / "rtconfig.py").exists() else None,
                "strong_match": is_strong_match(args.query, rel, bsp_dir.name, match_score),
            }
        )

    rows.sort(key=lambda x: (-x["score"], x["path"]))
    strong = [row for row in rows if row["strong_match"]]

    exact = [
        row
        for row in strong
        if norm(args.query) in {norm(row["name"]), norm(row["path"])}
    ]

    if len(exact) == 1:
        resolution = "exact"
        supported = True
        chosen = exact[0]
    elif len(strong) == 1:
        resolution = "strong"
        supported = True
        chosen = strong[0]
    elif len(strong) > 1:
        resolution = "ambiguous"
        supported = False
        chosen = None
    else:
        resolution = "none"
        supported = False
        chosen = None

    out = {
        "query": args.query,
        "repo": str(repo),
        "total": len(rows),
        "supported": supported,
        "resolution": resolution,
        "chosen": chosen,
        "strong_matches": strong[: args.limit],
        "matches": rows[: args.limit],
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
