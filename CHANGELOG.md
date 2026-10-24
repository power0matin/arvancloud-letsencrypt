# Changelog

## [Unreleased]

- Validate Debian 12 and Debian 13 in a dedicated workflow, separate from the Ubuntu matrix.
- Add Debian 12 (Bookworm) and Debian 13 (Trixie) container jobs for shell syntax, plugin parity, actionlint, ShellCheck, and the full mocked Bats suite.
- Run the full behavioral suite on Ubuntu 22.04 and 24.04 LTS; document that Debian is a target environment but is not yet in hosted CI.
- Update the roadmap to record 50 mocked Bats cases and the remaining manual staging, Debian CI, and detached-worker release gates.

- Add a manual ACME staging runner that isolates the ACME account/configuration and certificate output, hides the ArvanCloud key prompt, and never deploys a staging certificate to production paths.

- Resolve companion scripts from the same immutable release tag and verify downloaded components against that release's SHA-256 manifest before execution.

- Add Bats-based mocked tests for ArvanCloud zone discovery, TXT creation and cleanup, malformed responses, credential absence, and API failures.
- Add mocked issuance tests for acme.sh exit-code 2, failed issuance/install, partial certificate output, file modes, and reload-command argument handling.
- Cover ArvanCloud access verification for valid, unauthorized, forbidden, inaccessible-zone, paginated, malformed, server-error, and transport-error responses; assert temporary auth-file cleanup on each path.
- Exercise the replacement-key flow: retry after 401/403 or a zone-visibility error, cancel on empty input, reject multiline values, and stop without reprompting on network/API errors.
- Cover foreground/background worker logging, persistence of issuance output, and failure behavior so an unsuccessful job is not logged as completed.
- Fix worker status propagation: failed issuance/install now returns the failure code and records a failure marker instead of a false completion message.
- Test temporary authorization-file cleanup through EXIT, HUP, INT, and TERM traps.
- Add detached-worker lifecycle tests that close the parent shell and verify the worker logs completion/failure with the correct status.
- Test version-pinned checksum verification for valid, mismatched, missing, duplicate, and unavailable manifests/components.
- Retry transient DNS API GET transport failures and HTTP 429/5xx responses at most three times with bounded backoff; do not retry authorization failures or repeat DNS mutations.

## [1.1.4]

- Replace the abbreviated license summary with the complete GPL-3.0-or-later text and document the upstream ArvanCloud DNS plugin provenance.
- Require an explicitly confirmed manual release from the current main commit; separate read-only validation from the publisher job and pin checkout to a reviewed full commit SHA.
- Clean up the temporary ArvanCloud authorization configuration on normal exits and common signals.
- Document the restrictive certificate directory/private-key permissions and their implications for services running as non-root.

## [1.1.3] - 2026-10-24

- Show certificate output paths in the interactive terminal while continuing to append issuance output to the ACME log.
- Keep background issuance logs available and print the destination directory before starting the background job.


## [1.1.2] - 2026-10-24

- Set `/root/cert/<domain>/` as the default certificate output path for interactive and CLI installation.
- Print the absolute output directory and paths to the certificate, chain, full chain, and private key after successful installation.
- Show the configured destination before running certificate issuance in the background.
- Prefer `/root/cert/<domain>/` during certificate inspection while retaining `/etc/ssl/acme/<domain>/` as a legacy lookup fallback.
- Expand the Persian README into full project documentation and improve English README navigation and release guidance.
- Check the embedded ArvanCloud DNS plugin against its source file in CI.
- Add structured issue and pull-request templates, and document safe contribution and release practices.

## [1.1.1] - 2026-10-23

- Clear the terminal before displaying the interactive menu and after returning from an action.
- Retry ArvanCloud API-key verification in place after HTTP 401/403 or when the selected DNS zone is not visible, without asking the user to re-enter the domain and certificate options.
- Read the initial and replacement API keys through a hidden prompt attached directly to the terminal.
- Pin the installer and menu to the versioned `v1.1.1` release.
- Documented the menu redraw and API-key retry behavior in both README guides.

## [1.1.0] - 2026-10-23

- Added an interactive terminal menu for common certificate-management tasks.
- Added CLI actions for listing, inspecting, renewing, viewing logs, and checking local setup.
- Improved DNS-name validation and bounded the DNS propagation wait option.
- Stopped persisting the full ArvanCloud domains API response or printing the visible zone inventory to logs.
- Improved pagination and response validation when locating zones and removing ACME TXT records.
- Preserved acme.sh exit-code 2 semantics: when issuance is skipped because a certificate is still valid, reuse is allowed only if the expected certificate file exists.
- Removed current README references to the example production deployment and personal contact details.
- Added a SHA-256 checksum manifest to the GitHub release assets.

## [1.0.0] - 2026-09-08

- Added a one-line installation flow for ArvanCloud DNS wildcard certificates.
- Added an `Arvan_Token`-compatible DNS plugin.
- Added root-zone discovery through the ArvanCloud domains list endpoint.
- Added automatic certificate installation, optional x-ui reload, and acme.sh cron setup.
- Added SSH-safe background issuance and local logs.
