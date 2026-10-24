# Changelog

## [Unreleased]

## [1.1.4]

### Security and release integrity

- Replace the abbreviated license summary with the complete GPL-3.0-or-later text, SPDX identifiers, and third-party provenance for the adapted ArvanCloud DNS plugin. GitHub recognizes the repository license as `GPL-3.0`.
- Require explicit manual release publishing from the current `main` commit; split read-only validation from the publisher job, use least-privilege token permissions, pin `actions/checkout` to a reviewed full commit SHA, and reject unverifiable or already-existing tags/releases.
- Pin `install.sh`, `menu.sh`, and `core.sh` to the same immutable release tag; verify every downloaded script against that release's SHA-256 manifest before execution.
- Clean up temporary ArvanCloud authorization files on normal exits and common signals; verify the temporary files use restrictive permissions.
- Document certificate directory/private-key permissions, service access implications, and the safe use of custom output directories.
- Add a guarded manual ACME staging integration workflow that requires explicit confirmation and dedicated repository secrets, uses a pinned upstream acme.sh commit, and keeps staging files isolated from production paths. A live staging issuance is still required before this release is considered fully validated.

### DNS and certificate reliability

- Retry read-only ArvanCloud DNS GET transport failures and HTTP 429/5xx responses at most three total attempts with bounded backoff; do not retry authorization failures or repeat DNS mutations.
- Preserve exact TXT-record cleanup behavior so only the matching ACME challenge record is deleted.
- Make the replacement-key flow retry only for credential/zone-access failures, reject empty or multi-line keys, and stop rather than reprompt on network/unexpected API errors.
- Preserve worker failure exit codes and ensure failed issuance/install operations are not logged as completed.
- Verify certificate installation output, file presence and permissions, and OpenSSL parsing before reporting success.

### Testing and CI

- Add 57 deterministic mocked Bats cases across nine files covering DNS API behavior, authentication/zone access, cleanup on EXIT/HUP/INT/TERM, replacement keys, issuance/install failures, foreground/background worker lifecycle, checksum verification, and staging input guards.
- Run CI on Ubuntu 22.04/24.04 and Debian 12/13; include Bash/sh syntax checks, ShellCheck, actionlint, DNS plugin parity, installer safety checks, and the complete mocked Bats suite.
- Extend release preflight to run the complete behavioral test suite and workflow linting before publishing.

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
