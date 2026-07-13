# Support matrix

This repository is a local, operator-reviewed infrastructure experiment. It is
not a hosted service, an uptime commitment, or an authoritative upstream Gensyn
installation guide.

| Surface | Verified boundary | Not claimed |
|---|---|---|
| Compose generator | Bash syntax/static analysis and a two-node generated-config smoke test on Ubuntu GitHub Actions | A running public swarm, GPU performance, or multi-host scheduling |
| Image | Default compatibility reference `ghcr.io/ashishki/gensyn-node:cpu-2.7.8`; callers may set `GENSYN_IMAGE` to an inspected digest | That a mutable tag still matches current upstream protocols |
| CPU allocation | Deterministic, non-overlapping `cpuset` ranges in generated YAML | Automatic host-capacity discovery or resource admission |
| Credentials and identity | Private host directories (`0700`), identity directory mount, and documented `0600` file handling | Secret distribution, rotation, recovery guarantees, or managed backup |
| Watchdog | Local subprocess restart on non-zero exit, signal forwarding, bounded deterministic smoke test | Application-level health, GPU correctness, or recovery from a corrupt state |
| OCTA notes | Preserved operator checklist and key-handling concepts with source provenance | Current marketplace pricing, hardware availability, or official platform support |

The bundled Dockerfile pins the upstream `rl-swarm` source revision to
`385e0b3`. Its package downloads and apt repositories are not locked into a
reproducible supply-chain manifest, so rebuilding it can change over time. Treat
the image and upstream protocol as review-required inputs.

## Locally checked combinations

| Host/tool | Automated check |
|---|---|
| Ubuntu GitHub Actions runner | `bash -n`, ShellCheck, generator/watchdog smoke |
| Docker Compose on GitHub Actions | Parse and normalize the generated two-node configuration; containers are not started |

No claim is made for Debian, CentOS, cloud VMs, OCTA, NVIDIA GPUs, or 100-node
operation until a dated, reproducible evidence artifact is added.
