#!/usr/bin/env bash
set -euo pipefail

# Usage: ./prepare-nodes.sh 3
# Will prepare data/ and identities/ for node1..node3
# and generate a docker-compose.yml with ports 38331–38333
# and cpuset ranges 0–19,20–39,40–59

if [ $# -ne 1 ]; then
  echo "Usage: $0 <number_of_nodes>"
  exit 1
fi

N=$1
BASE_PORT=38331
CORES_PER_NODE=20

# Build options (always build locally)
IMAGE_LOCAL_TAG=${IMAGE_LOCAL_TAG:-gensyn-node:local}
RL_SWARM_REF=${RL_SWARM_REF:-main}
RL_SWARM_REPO=${RL_SWARM_REPO:-https://github.com/gensyn-ai/rl-swarm}

cat > docker-compose.yml <<EOF
services:
EOF

for ((i=1; i<=N; i++)); do
  PORT=$(( BASE_PORT + i - 1 ))
  CPU_START=$(( (i-1)*CORES_PER_NODE ))
  CPU_END=$(( CPU_START + CORES_PER_NODE - 1 ))
  SVC=node$i

  # A) Prepare host directories
  mkdir -p data/$SVC/modal-login/temp-data
  mkdir -p identities/$SVC

  # B) Append the service block
  cat >> docker-compose.yml <<EOB
  $SVC:
EOB

  cat >> docker-compose.yml <<EOB
    image: $IMAGE_LOCAL_TAG
    build:
      context: .
      dockerfile: docker/Dockerfile
      args:
        RL_SWARM_REF: "$RL_SWARM_REF"
        RL_SWARM_REPO: "$RL_SWARM_REPO"
EOB

  cat >> docker-compose.yml <<EOB
    container_name: gensyn-test$i

    environment:
      - P2P_PORT=$PORT
      - CPU_ONLY=1
      - NON_INTERACTIVE=1
      - JOIN_TESTNET=true
      - DISABLE_MODAL_LOGIN=1
      - DISABLE_HF_PUSH=1
      - SWARM=A
      - PARAM_B=0.5

    volumes:
      - "./data/$SVC/modal-login/temp-data:/opt/rl-swarm/modal-login/temp-data"
      - "./identities/$SVC/swarm.pem:/opt/rl-swarm/swarm.pem"
      - "./run_rl_swarm_json_save.sh:/opt/rl-swarm/run_rl_swarm.sh:ro"
      
    ports:
      - "$PORT:$PORT"

    restart: on-failure
    cpuset: "$CPU_START-$CPU_END"
    deploy:
      resources:
        limits:
          cpus: "$CORES_PER_NODE.0"

EOB

  # C) Generate the setup script for each node
  cat > setup-$SVC.sh <<EOS
#!/usr/bin/env bash
set -euo pipefail

SERVICE=$SVC
CONTAINER=bootstrap-\$SERVICE
IDENT_DIR=./identities/\$SERVICE
IMAGE_LOCAL_TAG=$IMAGE_LOCAL_TAG
P2P_PORT=$PORT

mkdir -p "\$IDENT_DIR"

if [ -f "\$IDENT_DIR/swarm.pem" ]; then
  echo "✅ Identity exists → starting via Compose"
  docker compose up -d "\$SERVICE"
  exit 0
fi

echo "🔄 No identity found: bootstrapping \$SERVICE via 'docker run'…"

docker run -d --name "\$CONTAINER" \
  -e CPU_ONLY=1 \
  -e NON_INTERACTIVE=1 \
  -e JOIN_TESTNET=true \
  -e DISABLE_MODAL_LOGIN=1 \
  -e DISABLE_HF_PUSH=1 \
  -e SWARM=A \
  -e PARAM_B=0.5 \
  -e P2P_PORT=\$P2P_PORT \
  -p \$P2P_PORT:\$P2P_PORT \
  -v "\$(pwd)/data/\$SERVICE/modal-login/temp-data":/opt/rl-swarm/modal-login/temp-data \
  \$IMAGE_LOCAL_TAG \
  bash -c './run_rl_swarm.sh'

echo "⏳ Waiting for /opt/rl-swarm/swarm.pem in \$CONTAINER…"
while ! docker exec "\$CONTAINER" test -f /opt/rl-swarm/swarm.pem; do
  sleep 2
done
echo "✅ Detected swarm.pem inside container"

echo "⏹ Stopping \$CONTAINER"
docker stop "\$CONTAINER"

echo "📂 Copying swarm.pem out to host (\$IDENT_DIR/swarm.pem)"
rm -rf "\$IDENT_DIR/swarm.pem"
docker cp "\$CONTAINER":/opt/rl-swarm/swarm.pem "\$IDENT_DIR/swarm.pem"
chmod 600 "\$IDENT_DIR/swarm.pem"

docker rm "\$CONTAINER"

echo "🚀 Restarting \$SERVICE properly via Compose"
docker compose up -d "\$SERVICE"

echo "✅ \$SERVICE is up with its persistent identity key."
EOS

  chmod +x setup-$SVC.sh
done

echo "✅ Generated docker-compose.yml for $N nodes."
echo "✅ Created setup scripts: setup-node1.sh ... setup-node$N.sh"
echo "✅ Created data/ and identities/ subdirs for node1..node$N."
echo
echo "Next steps:"
echo " 1) Copy or generate your JSON login keys into each:"
echo "      data/nodeX/modal-login/temp-data/{userApiKey.json,userData.json}"
echo " 2) Run your bootstrap scripts (setup-nodeX.sh) to generate swarm.pem for each."
echo " 3) Finally: docker compose up -d"
