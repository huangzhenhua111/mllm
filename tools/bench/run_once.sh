#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   tools/bench/run_once.sh "<prompt>" <out_dir> [run_tag]
#
# 依赖：adb, /usr/bin/time

PROMPT="${1:-}"
OUT_DIR="${2:-out/bench}"
TAG="${3:-tinyllama_fp32}"

if [[ -z "$PROMPT" ]]; then
  echo "ERROR: prompt is empty"
  exit 1
fi

mkdir -p "$OUT_DIR"

# 你现在手机上的固定路径（按你已跑通的为准）
DEVICE_BIN="/data/local/tmp/mllm/bin/mllm-tiny-llama-runner"
DEVICE_LIB="/data/local/tmp/mllm/lib"
MODEL="/sdcard/mllm/models/tinyllama-fp32.mllm"
TOKENIZER="/data/local/tmp/mllm/models/tokenizer/tokenizer.json"
CONFIG="/data/local/tmp/mllm/models/config_tiny_llama.json"

TS="$(date +%Y%m%d_%H%M%S)"
RUN_ID="${TAG}_${TS}_$RANDOM"
LOG="$OUT_DIR/${RUN_ID}.log"
TIMELOG="$OUT_DIR/${RUN_ID}.time"

# 用 stdin 喂两行：prompt + exit（你已验证 OK）
# 用 /usr/bin/time -p 记录 real/user/sys，写到单独文件
{
  /usr/bin/time -p bash -lc \
  "printf '%s\nexit\n' \"\$0\" | adb shell -T 'export LD_LIBRARY_PATH=$DEVICE_LIB:\$LD_LIBRARY_PATH; \
    $DEVICE_BIN -m $MODEL -mv v1 -t $TOKENIZER -c $CONFIG'" \
  "$PROMPT"
} >"$LOG" 2>"$TIMELOG"

echo "OK: $RUN_ID"
echo "  log:  $LOG"
echo "  time: $TIMELOG"
