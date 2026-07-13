# Migrated operations notes

This document preserves the useful boundary of two smaller repositories before
they are archived. It does not copy their outdated launch commands into the
supported path.

## Provenance

| Source repository | Source revision | Preserved concept | New location |
|---|---|---|---|
| `ashishki/gensyn-node-watchdog` | `831bbf1fd0b6ff52c46943f829ccd1af94aaff70` | bounded restart loop, per-node runtime log, optional detached execution | `scripts/watchdog.sh` |
| `ashishki/gensyn_node_octa` | `fd54f8e3c5a9cc92199a3544faa1b452d55962e1` | credential/identity backup and restore checklist, hosted-machine caveats | this document |

Both sources are owned by this repository's owner. The supervisor was rewritten
to avoid hard-coded `/root` paths, process-name killing, interpolated shell
commands, and assumptions about a specific upstream launcher.

## Local supervisor

Run the actual launcher as an argument array; do not put credentials in the
command line:

```bash
scripts/watchdog.sh \
  --node-dir /srv/rl-swarm \
  --log /var/log/rl-swarm/watchdog.log \
  --restart-delay 30 \
  -- ./run_rl_swarm.sh
```

The supervisor restarts only after a non-zero exit. It forwards `TERM`/`INT`,
creates a mode-`0600` log, and can be bounded with `--max-runs` for tests. Use a
real service manager for boot persistence and policy; this script is not a
health monitor or availability guarantee.

## Identity and login-file handling

The sensitive files are `swarm.pem`, `userApiKey.json`, and `userData.json`.
They must stay outside Git and must not be pasted into issues or evidence packs.

1. Stop the node before copying identity state.
2. Create a private destination with `install -d -m 700 /secure/path/gensyn`.
3. Copy each expected file explicitly and apply mode `0600`.
4. Record checksums in a private location; never commit them if they reveal
   private paths or identifiers.
5. Restore into a stopped instance, reapply ownership/modes, then verify the
   expected identity before starting the node.
6. If a key is exposed, rotate/revoke it through the responsible provider; a
   Git history edit is not credential revocation.

Marketplace URLs, prices, GPU availability, upstream commands, and browser file
transfer features change independently. Verify them against current official
provider and Gensyn documentation before changing a host.
