# Roadmap

**Current release:** `v1.1.3`  
**Roadmap updated:** 2026-10-24  
**Project focus:** Reliable Let's Encrypt wildcard certificates through ArvanCloud DNS-01.

This roadmap is an ordered plan, not a promise of calendar dates. A version is ready when its acceptance criteria are met—not when a date arrives. The next release should not be published merely to make progress appear faster.

## Priorities

- **P0 — Security and release integrity:** prevent credential exposure, mixed-version installs, and accidental releases.
- **P1 — Correctness and tests:** prove DNS, issuance, renewal, and recovery behavior without production credentials.
- **P2 — Operability:** make installation health, repair, permissions, and failure recovery clear.
- **P3 — Maintainability and optional integrations:** reduce duplicated implementation and stabilize automation interfaces.

## Current baseline: v1.1.3

Released capabilities include the interactive menu, non-interactive CLI, ArvanCloud DNS-01 plugin, wildcard issuance, acme.sh renewal registration, certificate inspection, logs, background issuance, output-path reporting, and a SHA-256 release manifest.

The main gaps to close next are behavioral test coverage, release-workflow safety, deterministic component downloads, better cleanup after interruption, and a documented recovery path. New visual badges or unrelated features are not a priority until these gaps are addressed.

---

## v1.1.4 — Security and release discipline

**Type:** Patch release · **Priority:** P0

### Planned work

- Replace the abbreviated `LICENSE` file with the complete applicable GPL-3.0-or-later license text. Add accurate SPDX and third-party provenance information, including attribution for code derived from acme.sh. Ensure the repository metadata is recognized correctly by GitHub.
- Make publishing an explicit manual action from the intended release source. Remove automatic publishing on pushes to `release/v*` branches so an old branch commit cannot accidentally become a release.
- Validate that the selected source commit is the intended `main` release candidate; require an explicit `PUBLISH` confirmation and reject an already-used tag.
- Apply least-privilege GitHub Actions permissions per job. Pin third-party Actions to reviewed full commit SHAs rather than mutable major-version tags.
- Add signal/exit cleanup for temporary ArvanCloud authorization files so an interruption does not leave credentials behind in `/run`.
- Clarify certificate ownership, directory permissions, private-key access, custom `--install-dir` behavior, reload-command behavior, and the limits of the `--x-ui` option.
- Keep release inputs and documentation consistent with the next available version; do not leave a manual-dispatch default pointing at an already-published tag.

### Acceptance criteria

- GitHub recognizes the repository license and the full license text is present.
- Syntax checks and ShellCheck pass for all shell entrypoints and the DNS plugin.
- The release workflow cannot publish from an arbitrary `release/v*` branch push and cannot publish without explicit confirmation.
- Temporary authorization material is removed on normal exit and handled on common interruption paths.
- Documentation makes clear that the private key must remain restricted; permissions must not be loosened just to make a service read it.

---

## v1.2.0 — Behavioral tests and DNS API resilience

**Type:** Minor release · **Priority:** P1  
**Dependency:** v1.1.4 release safeguards

### Planned work

- Introduce [Bats](https://bats-core.readthedocs.io/) tests with mocked `curl`/ArvanCloud responses and a fake acme.sh executable. Default CI must not require a real DNS account, production domain, or secret.
- Cover at least:
  - API authentication failure, forbidden access, replacement-key flow, and a zone that is not visible to the key.
  - Domain-zone pagination, malformed or incomplete JSON, empty results, HTTP errors, timeouts, and network failures.
  - TXT creation and cleanup, including the rule that cleanup removes only the matching ACME challenge record—not unrelated records with a similar name.
  - Existing-certificate behavior when acme.sh returns its “not renewed”/skip status, missing certificate files, and failed issuance.
  - Background issuance, output paths, file modes, interrupted operations, and partial installation recovery.
- Add bounded retry/backoff for transient network failures and appropriate retryable server/rate-limit responses. Keep retries finite, surface the final error clearly, and do not endlessly retry invalid credentials or missing zone permissions.
- Add workflow linting (for example, actionlint) alongside syntax checks, ShellCheck, plugin parity checks, and the new behavioral suite.
- Add an opt-in ACME staging test procedure. Any test that uses real ArvanCloud credentials must be manually enabled with dedicated test credentials and must never print secrets.

### Acceptance criteria

- The above cases run deterministically in CI with mocked responses and no live API credentials.
- Regression tests fail when DNS cleanup could delete a non-matching TXT record or when a network failure is reported as successful issuance.
- Retries have explicit limits and timeouts; authentication and authorization failures remain actionable.
- The supported shell/OS combinations are declared in the README and exercised by CI where practical.
- Staging validation is documented separately from ordinary CI and never targets a production certificate order by default.

---

## v1.3.0 — Deterministic installation and artifact integrity

**Type:** Minor release · **Priority:** P0/P1  
**Dependency:** v1.2.0 behavioral coverage

### Planned work

- Keep `latest` as a convenient bootstrap channel, but have that bootstrap download all companion components from the **same immutable version tag**. Do not fetch `install.sh`, `menu.sh`, and `core.sh` from a moving branch at different moments during one installation.
- Verify downloaded components against the matching release's `SHA256SUMS` manifest and fail closed if the manifest is missing or a checksum does not match.
- Make the installed version discoverable in CLI/menu diagnostics and logs without exposing credentials or unnecessary environment data.
- Ensure release assets, the changelog version, the core version constant, and the tag agree. Update the `latest` branch only after the release is successfully created.
- Document both installation modes: convenient moving-channel bootstrap and reproducible version-pinned installation. Explain that a checksum manifest detects mismatches/corruption but is not a cryptographic signature of the publisher.

### Acceptance criteria

- A bootstrap obtained from `latest` fetches all companion files from one release tag.
- A mismatched, missing, or modified component is rejected before it is installed or executed.
- A failed release does not advance `latest`.
- A user can identify the installed version and reproduce installation of a particular published version.

---

## v1.4.0 — Diagnostics, repair, and safe recovery

**Type:** Minor release · **Priority:** P2  
**Dependency:** v1.2.0 tests and v1.3.0 version-pinned downloads

### Planned work

- Improve `--check` into an actionable diagnostics report covering required commands, acme.sh installation, renewal scheduling, expected certificate files, expiry/validity, directory and key permissions, and obvious configuration inconsistencies.
- Add regression coverage for interrupted issuance and partially completed certificate installation.
- Design a conservative repair/recovery workflow that backs up the current state before changing it and reports exactly what it will modify.
- Document a safe uninstall procedure. Destructive actions must require explicit confirmation and default to preserving user-managed certificates, private keys, acme.sh account/configuration, logs, and DNS records. Never delete an entire DNS zone or unrelated records.
- Test and document the supported Debian/Ubuntu releases and privilege assumptions. Unsupported environments should fail with a clear message rather than partially installing.
- Evaluate a systemd timer only if there is a concrete need that acme.sh's existing renewal schedule cannot meet. Do not introduce a second renewal scheduler by default.

### Acceptance criteria

- Diagnostics distinguish a healthy setup from missing prerequisites, broken renewal scheduling, missing files, and permission issues.
- Recovery steps are documented and tested against partial-failure scenarios.
- Uninstall behavior is non-destructive by default and explicitly lists what would be removed before confirmation.
- acme.sh remains the single default renewal scheduler.

---

## v1.5.0 — Safer certificate deployment and monitoring

**Type:** Minor release · **Priority:** P2

### Planned work

- Harden certificate deployment so new files are staged and validated before replacing the currently working deployment; preserve a recoverable previous state when installation or a reload command fails.
- Validate certificate/key consistency and certificate validity before reporting deployment success.
- Improve renewal/deployment reporting so operators can distinguish “renewal not due,” “renewal failed,” “certificate installed,” and “service reload failed.”
- Make `--check` suitable for basic monitoring through documented, stable exit statuses. Add machine-readable output only if the current CLI needs it for a real integration.
- Expand deployment recipes for common services while keeping service-specific access instructions explicit. Do not weaken private-key permissions globally; explain how to grant the intended service access safely.
- Verify that reload hooks run only at the intended point in the successful install/renew flow and that failures are visible in logs and exit status.

### Acceptance criteria

- A failed deployment or reload does not silently leave the operator believing the new certificate is active.
- Tests cover mismatched key/certificate pairs, invalid certificates, failed reload commands, and recovery of the previous deployment.
- Monitoring exit statuses and log locations are documented and stable.

---

## v2.0.0 — Stable interfaces and simpler internals

**Type:** Major release · **Priority:** P3 · **Status:** Conditional; scope to be confirmed after v1.x

### Candidate work

- Establish a compatibility contract for CLI options, exit statuses, log locations, output paths, and any machine-readable output.
- Choose one authoritative source for the ArvanCloud DNS plugin. Either generate the embedded plugin block in `core.sh` from `src/dns_arvan.sh` during release/build, or ship a versioned plugin file as a runtime asset. Remove manual duplication only after compatibility tests cover both installation and renewal.
- Document supported Bash and OS versions, deprecation rules, and a tested upgrade path from the last v1.x release.
- Consider upstreaming the ArvanCloud DNS plugin to acme.sh as a separate collaboration effort. This depends on upstream acceptance and must not be treated as a release blocker or guaranteed outcome.

### Acceptance criteria

- Existing documented CLI behavior is either preserved or clearly marked as a breaking change.
- The plugin has one authoritative source and CI proves that packaged releases match it.
- A clean install and an upgrade from the latest supported v1.x release pass the full test suite.

---

## Release gate for every version

Before publishing any version:

- [ ] Update the version constant and add a complete `CHANGELOG.md` section.
- [ ] Pass syntax checks, ShellCheck, workflow linting, and all applicable behavioral tests.
- [ ] Verify plugin-source/package consistency and scan release files for credentials or private deployment identifiers.
- [ ] Review the installation, certificate path, permission, renewal, and recovery behavior changed by the release.
- [ ] Generate and verify `SHA256SUMS` for the published assets.
- [ ] Publish from the approved source commit with an explicit confirmation.
- [ ] Confirm the release assets and notes are correct before advancing `latest`.
- [ ] Perform a smoke test using a disposable domain or ACME staging where applicable; never use production certificates as the default test fixture.

## Explicit non-goals

- Adding unrelated DNS providers before the ArvanCloud implementation is well tested.
- Adding a second renewal scheduler by default.
- Automatically deleting user certificates, private keys, DNS zones, or unrelated DNS records during uninstall or recovery.
- Relaxing private-key permissions as a workaround for service configuration.
- Prioritizing extra badges or cosmetic README changes over security, tests, deterministic installs, and recovery.
