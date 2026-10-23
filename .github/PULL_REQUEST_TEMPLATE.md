## Summary

Describe the change and why it is needed.

## Validation

- [ ] `bash -n install.sh menu.sh core.sh`
- [ ] `sh -n src/dns_arvan.sh`
- [ ] `shellcheck install.sh menu.sh core.sh src/dns_arvan.sh`
- [ ] The embedded plugin in `core.sh` matches `src/dns_arvan.sh`.
- [ ] Documentation and changelog are updated where relevant.

## Safety

- [ ] No API keys, private keys, certificates, logs, or private production identifiers are included.
- [ ] No tests were run against a production DNS zone.
