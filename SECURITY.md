# Security policy

`gensyn-docker-multi` is a local shell toolkit, not a hosted service. Reports
are accepted for the current default branch or an identified supported tag and
only for the repository-owned generator, watchdog, deterministic smoke checks,
and generated-Compose boundary. Upstream RL-Swarm behavior, third-party images,
operator-modified deployments, public-swarm operation, and infrastructure or
data you do not own are outside this policy.

Do not open a public issue for a suspected vulnerability. Email
`verter25@gmail.com` with subject `gensyn-docker-multi security report`. Include
the exact toolkit revision, prerequisites, a minimal synthetic reproduction,
impact, and suggested mitigation. Keep the first message minimal. Do not attach
credentials, `.env`, `swarm.pem`, login JSON, identity files, wallet/account
identifiers, generated private state, unsanitized logs, or an exploit against a
third-party system. A safer transfer path can be agreed before details are sent.

GitHub private vulnerability reporting is not assumed to be enabled. Use a
GitHub private advisory form only if the repository Security page visibly
offers **Report a vulnerability**. This maintainer-run utility has no security
SLA and cannot promise a response or remediation deadline. Reports will be
triaged against the explicit supported boundary above.

If a credential or identity secret is exposed, revoke or rotate it at its
provider. Removing a later Git commit does not retract copies already fetched.
