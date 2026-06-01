# Stability

apfel-tag follows semantic versioning.

- **CLI surface** (flags, exit codes, plain/JSON output shape) is the stability
  contract. Breaking changes to it require a major version bump.
- `ApfelTagCore` is an internal library; its API may change in minor releases
  until 1.0.0.
- Tag *content* is produced by Apple's on-device model and is not guaranteed to
  be stable across OS updates.
