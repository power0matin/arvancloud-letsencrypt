# Contributing

1. Keep commands, variable names, and source comments in English.
2. Keep `core.sh` and `src/dns_arvan.sh` behavior aligned because the core embeds the plugin for one-line installation.
3. Run `bash -n install.sh menu.sh core.sh`, `sh -n src/dns_arvan.sh`, and `shellcheck install.sh menu.sh core.sh src/dns_arvan.sh` before opening a pull request.
4. Use semantic versioning for releases and Conventional Commits (for example, `fix: handle paginated DNS records`).
5. Never commit access keys, certificates, private keys, ACME account configuration, server logs, or production domain inventories.
6. Prefer mocked tests or a dedicated DNS test zone. Never test changes against a production zone.
