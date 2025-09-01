# -----------------------------------------------------------------------------
# docker/Dockerfile – CPU-only Gensyn node image (Ubuntu 22.04)
# -----------------------------------------------------------------------------
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=180

# 1) System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-pip python3-dev \
      build-essential pkg-config libffi-dev libssl-dev cmake \
      rustc cargo git-lfs wget \
      git curl gnupg ca-certificates \
      nano \
 && git lfs install || true

# 2) Add Yarn’s GPG key & repo
# RUN mkdir -p /usr/share/keyrings \
#  && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarn.gpg \
#  && echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main" > /etc/apt/sources.list.d/yarn.list
 RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# 3) Add Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends nodejs yarn

# Optional: increase Yarn timeout to reduce transient errors
RUN yarn config set network-timeout 600000 -g || true

# 4) Clone rl-swarm (trackable)
ARG RL_SWARM_REPO=https://github.com/gensyn-ai/rl-swarm
ARG RL_SWARM_REF=main
RUN git clone "$RL_SWARM_REPO" /opt/rl-swarm \
 && cd /opt/rl-swarm \
 && git fetch --all --tags \
 && git checkout "$RL_SWARM_REF"

WORKDIR /opt/rl-swarm

# 5) Override config (kept for convenience; harmless if path changes)
COPY docker/grpo-qwen-0.5b-cpu.yaml /tmp/grpo-qwen-0.5b-cpu.yaml
RUN set -eux; \
    dest=/opt/rl-swarm/hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml; \
    if [ -d "$(dirname "$dest")" ]; then cp /tmp/grpo-qwen-0.5b-cpu.yaml "$dest" || true; fi

# 5b) Preserve official launcher path before host bind-mount overrides it
RUN cp /opt/rl-swarm/run_rl_swarm.sh /usr/local/bin/rlswarm_official.sh || true \
 && chmod +x /usr/local/bin/rlswarm_official.sh || true

# 6) Create virtual env and install dependencies
RUN python3 -m venv .venv \
 && . .venv/bin/activate \
 && pip install --upgrade pip setuptools wheel \
 && if [ -f requirements-cpu.txt ]; then pip install --no-cache-dir -r requirements-cpu.txt; \
    elif [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; \
    elif [ -f pyproject.toml ]; then pip install --no-cache-dir .; \
    else echo 'No requirements[-cpu].txt or requirements.txt or pyproject.toml found; skipping base deps'; fi \
 && pip install --no-cache-dir gensyn-genrl==0.1.4 "reasoning-gym>=0.1.20" trl \
 && (pip install --no-cache-dir git+https://github.com/gensyn-ai/hivemind@639c964a8019de63135a2594663b5bec8e5356dd || (sleep 5 && pip install --no-cache-dir git+https://github.com/gensyn-ai/hivemind@639c964a8019de63135a2594663b5bec8e5356dd)) \
 && set -eux; \
    if [ -f hivemind_exp/runner/grpo_runner.py ]; then \
      sed -i 's|dht = hivemind.DHT(start=True, startup_timeout=30, \*\*self._dht_kwargs(grpo_args))|dht = hivemind.DHT(start=True, ensure_bootstrap_success=False, startup_timeout=120, **self._dht_kwargs(grpo_args))|' hivemind_exp/runner/grpo_runner.py || true; \
    fi; \
    SP=$(python -c "import sysconfig; print(sysconfig.get_paths().get('purelib',''))" 2>/dev/null || true); \
    if [ -n "$SP" ] && [ -f "$SP/hivemind/p2p/p2p_daemon.py" ]; then \
      sed -i 's|idle_timeout: float = 30|idle_timeout: float = 120|' "$SP/hivemind/p2p/p2p_daemon.py" || true; \
      sed -i 's|startup_timeout: float = 15|startup_timeout: float = 120|' "$SP/hivemind/p2p/p2p_daemon.py" || true; \
    fi

# Ensure package is importable if rl-swarm uses src layout
ENV PYTHONPATH=/opt/rl-swarm

# 7) Install modal-login UI dependencies
WORKDIR /opt/rl-swarm/modal-login
RUN yarn install
# WORKDIR /opt/rl-swarm/modal-login
# RUN yarn config set network-timeout 600000 -g \
#  && yarn install --network-timeout 600000 --prefer-offline \
#  && yarn add viem@2.25.0 --exact \
#  && yarn add next@latest --exact || true

# 8) Copy entrypoint
WORKDIR /opt/rl-swarm
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 38331
ENTRYPOINT ["/entrypoint.sh"]
