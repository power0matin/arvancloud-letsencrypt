# Changelog

## [Unreleased]

- Expand the Persian README into complete project documentation with installation, CLI, renewal, security, and troubleshooting guidance.
- Add automated CI validation that the embedded ArvanCloud DNS plugin matches its source file.
- Add structured issue and pull-request templates to improve public bug reports while discouraging secret disclosure.
- Standardize future release titles to the version only, with the project name in the release description.
- Use `/root/cert/<domain>/` as the default certificate output directory in both CLI and interactive installs.
- Print the resolved output directory and absolute certificate file paths after successful installation; also show the target path before a background job starts.
- Prefer the new certificate path in the information command while preserving `/etc/ssl/acme/<domain>/` as a legacy lookup fallback.


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
