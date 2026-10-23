# Security Policy

## Reporting a vulnerability

Do not open a public issue for credentials, tokens, private keys, or security vulnerabilities.

Use a private GitHub security advisory or contact the repository maintainer directly.

Never paste `Arvan_Token`, private keys, `/root/.acme.sh/account.conf`, or full debug logs into a public issue.

## Credential handling

- Use a least-privilege Arvan access key limited to the required DNS zone.
- Prefer the secure interactive prompt over putting the key in shell history.
- The key is stored by acme.sh in `account.conf`; keep that file mode `600`.
- Rotate the key immediately if it appears in a terminal recording, process dump, CI log, or public repository.
