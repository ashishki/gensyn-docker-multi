#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <number-of-nodes>\n' "$0" >&2
  printf 'Optional environment: GENSYN_IMAGE, BASE_PORT, CORES_PER_NODE, MAX_NODES\n' >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

node_count=$1
base_port=${BASE_PORT:-38331}
cores_per_node=${CORES_PER_NODE:-20}
max_nodes=${MAX_NODES:-32}
image=${GENSYN_IMAGE:-ghcr.io/ashishki/gensyn-node:cpu-2.7.8}

for value_name in node_count base_port cores_per_node max_nodes; do
  value=${!value_name}
  if [[ ! $value =~ ^[0-9]+$ ]]; then
    printf 'error: %s must be a positive integer (got %q)\n' "$value_name" "$value" >&2
    exit 64
  fi
done

if ((node_count < 1 || node_count > max_nodes)); then
  printf 'error: number-of-nodes must be between 1 and %d\n' "$max_nodes" >&2
  exit 64
fi
if ((base_port < 1024 || base_port > 65535)); then
  printf 'error: BASE_PORT must be between 1024 and 65535\n' >&2
  exit 64
fi
if ((cores_per_node < 1)); then
  printf 'error: CORES_PER_NODE must be at least 1\n' >&2
  exit 64
fi
last_port=$((base_port + node_count - 1))
if ((last_port > 65535)); then
  printf 'error: requested node range exceeds TCP port 65535\n' >&2
  exit 64
fi
if [[ -z $image || $image =~ [[:space:]] ]]; then
  printf 'error: GENSYN_IMAGE must be a non-empty image reference without whitespace\n' >&2
  exit 64
fi

tmp_compose=$(mktemp .docker-compose.yml.XXXXXX)
cleanup() {
  rm -f "$tmp_compose"
}
trap cleanup EXIT

cat >"$tmp_compose" <<'YAML'
name: gensyn-local
services:
YAML

for ((i = 1; i <= node_count; i++)); do
  port=$((base_port + i - 1))
  cpu_start=$(((i - 1) * cores_per_node))
  cpu_end=$((cpu_start + cores_per_node - 1))
  service="node$i"

  install -d -m 700 \
    data identities \
    "data/$service" \
    "data/$service/modal-login" \
    "data/$service/modal-login/temp-data" \
    "identities/$service"

  cat >>"$tmp_compose" <<YAML
  $service:
    image: "$image"
    container_name: "gensyn-local-$service"
    environment:
      CPU_ONLY: "1"
      P2P_PORT: "$port"
      IDENTITY_PATH: "/opt/rl-swarm/identity/swarm.pem"
    volumes:
      - "./data/$service/modal-login/temp-data:/opt/rl-swarm/modal-login/temp-data"
      - "./identities/$service:/opt/rl-swarm/identity"
    ports:
      - "$port:$port"
    restart: "on-failure:3"
    cpuset: "$cpu_start-$cpu_end"
    deploy:
      resources:
        limits:
          cpus: "${cores_per_node}.0"
    security_opt:
      - "no-new-privileges:true"

YAML
done

mv "$tmp_compose" docker-compose.yml
trap - EXIT

printf 'Generated docker-compose.yml for %d local node(s).\n' "$node_count"
printf 'Created private data and identity directories under data/ and identities/.\n'
printf 'Review docs/SUPPORT_MATRIX.md and place credentials outside Git before launch.\n'
