#!/usr/bin/env python3
import re
import csv
import glob
import os
from pathlib import Path

TIME_RE = re.compile(r'^(real|user|sys)\s+([0-9.]+)\s*$', re.M)
MEM_LINE_RE = re.compile(r'cap:\s*([0-9]+)(MB|GB),\s*used:\s*([0-9]+)(MB|GB)', re.I)
RESP_RE = re.compile(r'^🤖 Response:\s*(.*)$', re.M)

def to_mb(v: int, unit: str) -> float:
    unit = unit.upper()
    return float(v) * (1024.0 if unit == "GB" else 1.0)

def parse_time(path: str) -> dict:
    txt = Path(path).read_text(errors="ignore")
    out = {}
    for k, v in TIME_RE.findall(txt):
        out[k] = float(v)
    return out

def parse_log(path: str) -> dict:
    txt = Path(path).read_text(errors="ignore")
    resp = ""
    m = RESP_RE.search(txt)
    if m:
        resp = m.group(1).strip()

    caps_used = MEM_LINE_RE.findall(txt)
    used_mb = sum(to_mb(int(u), uu) for _, _, u, uu in caps_used)
    cap_mb = sum(to_mb(int(c), cu) for c, cu, _, _ in caps_used)

    return {
        "response_head": resp,
        "mem_cap_mb": cap_mb if cap_mb else "",
        "mem_used_mb": used_mb if used_mb else "",
    }

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("dir", nargs="?", default="out/bench", help="log dir")
    ap.add_argument("--out", default="out/bench/summary.csv")
    args = ap.parse_args()

    d = Path(args.dir)
    logs = sorted(d.glob("*.log"))
    rows = []

    for log_path in logs:
        base = log_path.with_suffix("")
        time_path = base.with_suffix(".time")
        if not time_path.exists():
            continue

        t = parse_time(str(time_path))
        l = parse_log(str(log_path))

        rows.append({
            "run_id": log_path.stem,
            "real_s": t.get("real", ""),
            "user_s": t.get("user", ""),
            "sys_s": t.get("sys", ""),
            **l
        })

    os.makedirs(Path(args.out).parent, exist_ok=True)
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=[
            "run_id","real_s","user_s","sys_s","mem_cap_mb","mem_used_mb","response_head"
        ])
        w.writeheader()
        w.writerows(rows)

    print(f"OK: wrote {args.out} ({len(rows)} rows)")

if __name__ == "__main__":
    main()
