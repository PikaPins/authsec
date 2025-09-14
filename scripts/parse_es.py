#!/usr/bin/env python3
"""
Attempt to parse the fetched response into a list of "technical resources".
Heuristics:
 - If top-level JSON array -> treat each element as a resource candidate.
 - If dict with common keys (results, data, items) -> extract that.
 - Otherwise, scan for nested dicts containing keys like 'title','name','url','link' and collect them.
"""
import json
import sys
from pathlib import Path

def find_candidates(obj):
    results = []
    if isinstance(obj, list):
        for item in obj:
            results.extend(find_candidates(item))
    elif isinstance(obj, dict):
        # If dict looks like resource
        keys = set(obj.keys())
        if keys & {"title","name","url","link","href","content"}:
            results.append(obj)
        else:
            for v in obj.values():
                results.extend(find_candidates(v))
    return results

def main():
    if len(sys.argv) < 3:
        print("Usage: parse_es.py <input.json> <output.json>", file=sys.stderr)
        sys.exit(2)
    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    if not in_path.exists():
        print("Input file not found", file=sys.stderr)
        sys.exit(1)
    try:
        data = json.loads(in_path.read_bytes())
    except Exception as e:
        print("Not valid JSON or parse error:", e, file=sys.stderr)
        sys.exit(1)

    candidates = []
    # Common wrappers
    if isinstance(data, dict):
        for key in ("results","data","items","hits","articles"):
            if key in data:
                candidates = find_candidates(data[key])
                break
    if not candidates:
        candidates = find_candidates(data)

    # Deduplicate by stringified representation (simple)
    seen = set()
    unique = []
    for c in candidates:
        s = json.dumps(c, sort_keys=True, ensure_ascii=False)
        if s not in seen:
            seen.add(s)
            unique.append(c)

    if unique:
        out_path.write_text(json.dumps(unique, ensure_ascii=False, indent=2))
        print(f"Wrote {len(unique)} parsed resources to {out_path}")
        sys.exit(0)
    else:
        print("No structured resources found")
        sys.exit(0)

if __name__ == "__main__":
    main()