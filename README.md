# Gensyn RL-Swarm Multi-Node Docker Toolkit

`gensyn-docker-multi` generates a reviewable local Docker Compose file for a
small set of CPU-oriented RL-Swarm nodes. It is a lower-tier infrastructure
experiment: the generator and watchdog have deterministic smoke tests, but no
public-swarm availability, production deployment, external user, or uptime is
claimed.

## Current maturity

- The maintained proof covers input validation, deterministic port/CPU ranges,
  private host directories, ShellCheck, generated Compose parsing, and a local
  watchdog restart fixture.
- Containers are deliberately not started in CI because they require external
  Gensyn services and private login material.
- The default image tag and upstream network can change independently. Review
  the [support matrix](docs/SUPPORT_MATRIX.md) and, when possible, set
  `GENSYN_IMAGE` to a digest you inspected.
- This repository is not official Gensyn documentation, a managed node service,
  a multi-host scheduler, or a security/availability guarantee.

## Five-minute reviewer path

No credentials or network access are needed for the bounded local proof:

```bash
git clone https://github.com/ashishki/gensyn-docker-multi.git
cd gensyn-docker-multi
bash -n prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh
scripts/smoke.sh
```

Expected final line:

```text
smoke checks passed
```

The smoke test generates a two-node configuration in a temporary directory,
checks invalid inputs, exercises one failed watchdog run followed by one clean
run, and verifies private file/directory modes.

## Generate a local configuration

Prerequisites for generation are Bash and standard GNU utilities. A real launch
also requires Docker with Compose v2, sufficient CPU/storage/network capacity,
an operator-reviewed image, and valid login material obtained outside this
repository.

```bash
./prepare-nodes.sh 2
docker compose -f docker-compose.yml config
```

Generated paths:

```text
docker-compose.yml
data/node1/modal-login/temp-data/
data/node2/modal-login/temp-data/
identities/node1/
identities/node2/
```

`data/`, `identities/`, and generated Compose files are ignored by Git. The
generator creates sensitive host directories with mode `0700`. Apply mode
`0600` to every key/identity file and keep it outside commits, issues, and public
evidence.

### Explicit configuration

```bash
GENSYN_IMAGE='registry.example/gensyn@sha256:<reviewed-digest>' \
BASE_PORT=40000 \
CORES_PER_NODE=8 \
MAX_NODES=4 \
./prepare-nodes.sh 2
```

| Variable | Default | Boundary |
|---|---:|---|
| `GENSYN_IMAGE` | `ghcr.io/ashishki/gensyn-node:cpu-2.7.8` | Compatibility reference, not an immutable supply-chain claim |
| `BASE_PORT` | `38331` | Validated user port; the complete range must remain below 65536 |
| `CORES_PER_NODE` | `20` | Generates non-overlapping `cpuset` ranges; host capacity is not auto-detected |
| `MAX_NODES` | `32` | Safety bound for accidental generation; not a tested scale claim |

Inspect `docker-compose.yml`, credential mounts, port exposure, image identity,
and host capacity before any launch. The generated services use
`no-new-privileges`, a bounded restart policy, and per-node identity directories.

## Local watchdog

The migrated supervisor restarts a launcher after non-zero exit without relying
on hard-coded process names or destructive `kill -9` scans:

```bash
scripts/watchdog.sh \
  --node-dir /srv/rl-swarm \
  --log /var/log/rl-swarm/watchdog.log \
  --restart-delay 30 \
  -- ./run_rl_swarm.sh
```

It is process supervision only. It does not prove application health, GPU
correctness, upstream connectivity, or successful training. Prefer a real
service manager for boot persistence and operational policy.

The useful boundaries from `gensyn-node-watchdog` and `gensyn_node_octa` were
preserved with exact source revisions in
[migrated operations notes](docs/MIGRATED_OPERATIONS_NOTES.md) before those
repositories are archived.

## Repository layout

```text
.
├── prepare-nodes.sh
├── scripts/
│   ├── smoke.sh
│   └── watchdog.sh
├── docker/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── grpo-qwen-0.5b-cpu.yaml
├── docs/
│   ├── MIGRATED_OPERATIONS_NOTES.md
│   └── SUPPORT_MATRIX.md
└── run_rl_swarm_json_save.sh
```

`run_rl_swarm_json_save.sh` is a historical upstream-derived compatibility
snapshot and is not mounted by the current generator. It is excluded from the
maintained shell gate; review or replace it against the exact upstream revision
before use. The Dockerfile pins upstream source revision `385e0b3`, but its
package downloads are not fully content-addressed.

## Security boundaries

- Never commit `swarm.pem`, `userApiKey.json`, `userData.json`, `.env`, logs, or
  generated node state.
- Do not place access tokens on command lines; process listings and CI logs can
  expose them.
- Do not pipe changing remote scripts into a privileged shell. Follow current
  official provider/upstream documentation and inspect commands first.
- Backups containing identity material must be encrypted/restricted and kept
  outside this repository.
- Exposure requires provider-side rotation or revocation. Removing a Git file
  does not revoke a credential.

## Verification

The GitHub Actions gate runs:

```bash
bash -n prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh docker/entrypoint.sh
shellcheck prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh docker/entrypoint.sh
scripts/smoke.sh
docker compose -f docker-compose.yml config --quiet
```

The Compose check parses generated configuration only; it is not a node launch
or external network test.

## Report a bounded problem

Read the [contribution boundary](docs/CONTRIBUTING.md), then use the closest
structured form:

- [reproducible script or smoke defect](https://github.com/ashishki/gensyn-docker-multi/issues/new?template=reproducible-script-defect.yml);
- [tested-version request](https://github.com/ashishki/gensyn-docker-multi/issues/new?template=tested-version-request.yml).

The second form requests a dated compatibility check; opening or closing it is
not evidence that a Gensyn revision, image, GPU path, network, or scale is
supported. Never attach credentials, identity material, `.env` files, wallet or
account identifiers, or unsanitized logs.

## Known limits

- No supported GPU path or measured performance evidence.
- No automatic host-capacity, port-conflict, DNS, firewall, or multi-host check.
- No secret manager, rotation workflow, backup service, monitoring stack, or
  application-level health endpoint.
- No evidence for the mutable default image tag against current upstream.
- No live CI proof because external auth/network use would make the gate
  nondeterministic and could expose private material.

For current upstream behavior, use the official
[gensyn-ai/rl-swarm](https://github.com/gensyn-ai/rl-swarm) repository as the
authority.
