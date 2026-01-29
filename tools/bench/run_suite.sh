#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   tools/bench/run_suite.sh <prompts_file> <out_dir> [tag] [warmup] [repeat]
#
# Example:
#   tools/bench/run_suite.sh cases/tinyllama_fp32/prompts.txt out/bench tinyllama_fp32 1 3

PROMPTS_FILE="${1:-}"
OUT_DIR="${2:-out/bench}"
TAG="${3:-tinyllama_fp32}"
WARMUP="${4:-1}"
REPEAT="${5:-3}"

if [[ ! -f "$PROMPTS_FILE" ]]; then
  echo "ERROR: prompts file not found: $PROMPTS_FILE"
  exit 1
fi

mapfile -t PROMPTS < <(grep -v '^\s*$' "$PROMPTS_FILE")

echo "Prompts: ${#PROMPTS[@]}, warmup=$WARMUP, repeat=$REPEAT"
mkdir -p "$OUT_DIR"

# warmup：只用第一条 prompt 跑 WARMUP 次，不计入统计（但仍落盘，方便排查）
for ((i=1;i<=WARMUP;i++)); do
  echo "== Warmup $i/$WARMUP =="
  tools/bench/run_once.sh "${PROMPTS[0]}" "$OUT_DIR" "${TAG}_warmup"
done

# 正式跑：每条 prompt 跑 REPEAT 次
for p in "${PROMPTS[@]}"; do
  for ((r=1;r<=REPEAT;r++)); do
    echo "== Run: r=$r/$REPEAT prompt=$(echo "$p" | head -c 40) =="
    tools/bench/run_once.sh "$p" "$OUT_DIR" "$TAG"
  done
done
