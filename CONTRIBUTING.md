# Contributing

Thanks for helping improve ArvanCloud Let's Encrypt.

## Before opening a pull request

1. Keep command-line output, variable names, and source comments in English.
2. Keep `core.sh` and `src/dns_arvan.sh` aligned: the core script embeds the DNS plugin for one-line installation, and CI checks their contents.
3. Run the local checks:
   - `bash -n install.sh`
   - `bash -n menu.sh`
   - `bash -n core.sh`
   - `sh -n src/dns_arvan.sh`
   - `shellcheck install.sh menu.sh core.sh src/dns_arvan.sh`
4. Use Conventional Commits (for example, `fix: handle paginated DNS records`) and semantic versioning for releases.
5. Never commit API keys, certificates, private keys, ACME account configuration, server logs, or production DNS-zone inventories.
6. Prefer mocked API tests or a dedicated DNS test zone. Never test changes against a production zone.

## Release convention

Release titles must contain only the version, such as `v1.2.0`. Put the project name and change summary in the release description. Update `CHANGELOG.md` before publishing.
