# Pull request

## Boundary changed

Describe the exact generator, watchdog, container, or documentation behavior.
State any explicit non-goals.

## Verification

- [ ] `bash -n prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh docker/entrypoint.sh`
- [ ] `shellcheck prepare-nodes.sh scripts/watchdog.sh scripts/smoke.sh docker/entrypoint.sh`
- [ ] `scripts/smoke.sh`
- [ ] Generated Compose parsing, if configuration changed
- [ ] `docs/SUPPORT_MATRIX.md` updated, if a support claim changed

Paste only sanitized command summaries. Distinguish generation/parsing from a
real container or network run.

## Safety review

- [ ] No credential, identity file, `.env`, private path, or unsanitized log is included
- [ ] No production, uptime, scale, GPU, or upstream-compatibility claim exceeds evidence
- [ ] Breaking defaults and migration steps are explicit
- [ ] External source material has a revision and provenance note
