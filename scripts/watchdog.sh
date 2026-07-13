#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: watchdog.sh --node-dir DIR --log FILE [options] -- COMMAND [ARG...]

Options:
  --restart-delay SECONDS  Delay after a failed run (default: 30)
  --max-runs COUNT         Stop after COUNT launches; 0 means unlimited (default: 0)
  --restart-on-clean       Restart even when COMMAND exits successfully
EOF
}

node_dir=
log_file=
restart_delay=30
max_runs=0
restart_on_clean=false

while (($#)); do
  case $1 in
    --node-dir)
      [[ $# -ge 2 ]] || { usage; exit 64; }
      node_dir=$2
      shift 2
      ;;
    --log)
      [[ $# -ge 2 ]] || { usage; exit 64; }
      log_file=$2
      shift 2
      ;;
    --restart-delay)
      [[ $# -ge 2 ]] || { usage; exit 64; }
      restart_delay=$2
      shift 2
      ;;
    --max-runs)
      [[ $# -ge 2 ]] || { usage; exit 64; }
      max_runs=$2
      shift 2
      ;;
    --restart-on-clean)
      restart_on_clean=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option %q\n' "$1" >&2
      usage
      exit 64
      ;;
  esac
done

if [[ -z $node_dir || -z $log_file || $# -eq 0 ]]; then
  usage
  exit 64
fi
if [[ ! -d $node_dir ]]; then
  printf 'error: node directory does not exist: %s\n' "$node_dir" >&2
  exit 66
fi
for pair in "restart_delay:$restart_delay" "max_runs:$max_runs"; do
  name=${pair%%:*}
  value=${pair#*:}
  if [[ ! $value =~ ^[0-9]+$ ]]; then
    printf 'error: %s must be a non-negative integer\n' "$name" >&2
    exit 64
  fi
done

command=("$@")
install -d -m 700 "$(dirname "$log_file")"
touch "$log_file"
chmod 600 "$log_file"

child_pid=
forward_signal() {
  local signal=$1
  if [[ -n ${child_pid:-} ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill -s "$signal" "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  exit 128
}
trap 'forward_signal TERM' TERM
trap 'forward_signal INT' INT

record() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$log_file"
}

run_count=0
while :; do
  run_count=$((run_count + 1))
  record "run=$run_count event=start"

  set +e
  (
    cd "$node_dir"
    exec "${command[@]}"
  ) >>"$log_file" 2>&1 &
  child_pid=$!
  wait "$child_pid"
  status=$?
  child_pid=
  set -e

  record "run=$run_count event=exit status=$status"
  if ((status == 0)) && [[ $restart_on_clean == false ]]; then
    exit 0
  fi
  if ((max_runs > 0 && run_count >= max_runs)); then
    exit "$status"
  fi
  sleep "$restart_delay"
done
