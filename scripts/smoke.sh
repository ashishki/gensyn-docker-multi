#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

generator_dir="$tmp_dir/generator"
mkdir -p "$generator_dir"
(
  cd "$generator_dir"
  GENSYN_IMAGE="example.invalid/gensyn@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
    BASE_PORT=40000 CORES_PER_NODE=2 "$repo_root/prepare-nodes.sh" 2
)

compose_file="$generator_dir/docker-compose.yml"
grep -Fq 'name: gensyn-local' "$compose_file"
grep -Fq 'container_name: "gensyn-local-node2"' "$compose_file"
grep -Fq 'P2P_PORT: "40001"' "$compose_file"
grep -Fq 'cpuset: "2-3"' "$compose_file"
grep -Fq 'IDENTITY_PATH: "/opt/rl-swarm/identity/swarm.pem"' "$compose_file"
grep -Fq 'no-new-privileges:true' "$compose_file"
test "$(stat -c '%a' "$generator_dir/data/node1")" = 700
test "$(stat -c '%a' "$generator_dir/identities/node2")" = 700

if (cd "$generator_dir" && "$repo_root/prepare-nodes.sh" 0 >/dev/null 2>&1); then
  printf 'expected zero-node generation to fail\n' >&2
  exit 1
fi
if (cd "$generator_dir" && BASE_PORT=65535 "$repo_root/prepare-nodes.sh" 2 >/dev/null 2>&1); then
  printf 'expected overflowing port range to fail\n' >&2
  exit 1
fi

node_dir="$tmp_dir/node"
mkdir -p "$node_dir"
fixture="$node_dir/fixture.sh"
cat >"$fixture" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count=0
if [[ -f $WATCHDOG_STATE_FILE ]]; then
  count=$(<"$WATCHDOG_STATE_FILE")
fi
count=$((count + 1))
printf '%s\n' "$count" >"$WATCHDOG_STATE_FILE"
if ((count == 1)); then
  exit 23
fi
exit 0
EOF
chmod +x "$fixture"

WATCHDOG_STATE_FILE="$tmp_dir/watchdog-state" \
  "$repo_root/scripts/watchdog.sh" \
  --node-dir "$node_dir" \
  --log "$tmp_dir/logs/watchdog.log" \
  --restart-delay 0 \
  --max-runs 2 \
  -- ./fixture.sh

grep -Fq 'run=1 event=exit status=23' "$tmp_dir/logs/watchdog.log"
grep -Fq 'run=2 event=exit status=0' "$tmp_dir/logs/watchdog.log"
test "$(stat -c '%a' "$tmp_dir/logs/watchdog.log")" = 600

printf 'smoke checks passed\n'
