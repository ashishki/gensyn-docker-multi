# Contributing

Contributions should stay inside the repository's bounded purpose: generating
reviewable local Compose configuration, maintaining deterministic shell checks,
and documenting operator-visible limitations. Open an issue before adding a new
orchestration layer, monitoring stack, GPU path, or upstream compatibility mode.
Use the structured
[reproducible-defect form](https://github.com/ashishki/gensyn-docker-multi/issues/new?template=reproducible-script-defect.yml)
or the narrower
[tested-version request](https://github.com/ashishki/gensyn-docker-multi/issues/new?template=tested-version-request.yml);
blank issues are disabled so the exact revision and evidence boundary are not
lost.
Suspected vulnerabilities use the private path in [`SECURITY.md`](../SECURITY.md),
not either public issue form.


## Local checks

The credential-free reviewer path is:

```bash
bash -n prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh docker/entrypoint.sh
shellcheck prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh docker/entrypoint.sh
scripts/smoke.sh
```

If Docker Compose v2 is available, also parse a generated configuration without
starting containers:

```bash
tmp_dir="$(mktemp -d)"
cd "$tmp_dir"
GENSYN_IMAGE='example.invalid/gensyn@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
  /path/to/gensyn-docker-multi/prepare-nodes.sh 2
docker compose -f docker-compose.yml config --quiet
```

## Evidence and privacy

- Use synthetic fixtures for CI. Do not attach API keys, identity files, `.env`,
  private logs, wallet identifiers, or provider account details.
- Describe exactly what was run. A generated-config test is not a live node or
  availability test.
- Do not claim platform, GPU, scale, or upstream compatibility without a dated,
  reproducible artifact and clear environment boundary.
- Changes to defaults must update `docs/SUPPORT_MATRIX.md` and the smoke test.

Keep commits focused and explain breaking behavior in the pull request. A pull
request is reviewed on its evidence and scope; no merge time or acceptance is
guaranteed.
