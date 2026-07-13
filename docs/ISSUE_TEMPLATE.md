# Issue template

## Observed behavior

Describe the smallest reproducible problem and the expected local behavior.

## Reproduction

```text
repository revision:
operating system:
Bash version:
Docker/Compose version, if relevant:
exact credential-free command:
sanitized output:
```

## Evidence boundary

- Was this only configuration generation, Compose parsing, an actual container
  start, or an external-network run?
- Did you reproduce from a clean checkout?
- Does the problem affect private identity/login material?

Do not post secrets, `.env` files, `swarm.pem`, login JSON, wallet/account
identifiers, or unsanitized logs. If a credential was exposed, rotate/revoke it
through its provider before discussing a code change.

Feature requests must explain the concrete operator problem and why it belongs
in this small toolkit rather than upstream Gensyn or an external service manager.
