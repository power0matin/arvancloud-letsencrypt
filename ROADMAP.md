# Roadmap

The project prioritizes reliability, safe credential handling, and predictable renewals.

- Add mocked ArvanCloud API tests for authentication failures, zone pagination, TXT creation, and TXT cleanup.
- Add recovery tests for interrupted issuance and partial certificate installation.
- Consider an optional systemd timer while preserving compatibility with the existing acme.sh renewal schedule.
- Add a documented, conservative uninstall/recovery workflow that avoids deleting user-managed certificates or DNS records.
