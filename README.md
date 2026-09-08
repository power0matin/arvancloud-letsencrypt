# arvancloud-letsencrypt

One-line Let's Encrypt wildcard certificates for domains managed by Arvan Cloud DNS.

This repository packages the recovery and automation workflow used for a production `3x-ui` deployment: Arvan DNS-01 validation, `acme.sh`, wildcard SANs, certificate installation, optional `x-ui restart`, SSH-safe background jobs, and automatic renewal.

The recommended repository name is `arvancloud-letsencrypt`: it is short, descriptive, provider-specific, and does not incorrectly imply that the project only works with x-ui.

## What it does

- Issues `DOMAIN` and `*.DOMAIN` with Let's Encrypt DNS-01.
- Uses an Arvan Cloud access key through the `Arvan_Token` variable expected by acme.sh.
- Installs a compatibility DNS plugin that discovers zones from the Arvan domains list endpoint.
- Normalizes the Arvan `Authorization: Apikey <key>` header.
- Stores the credential through acme.sh with restrictive permissions.
- Installs `cert.pem`, `chain.pem`, `fullchain.pem`, and `privkey.pem`.
- Adds the acme.sh renewal cron job when one does not already exist.
- Supports x-ui's existing paths and reload command with `--x-ui`.
- Supports a background mode that survives a normal SSH disconnect.
- Is idempotent: repeated runs back up the existing plugin and avoid duplicate cron jobs.

## Requirements

- Ubuntu or Debian
- Root access
- A domain already delegated to Arvan Cloud DNS
- An Arvan access key with permission to list the DNS zone and create, list, and delete DNS records
- Outbound HTTPS access to Arvan Cloud and Let's Encrypt

Port 80 is not required. Wildcard certificates use DNS-01 and do not use HTTP-01.

## Quick start

The canonical repository is `power0matin/arvancloud-letsencrypt`.

```bash
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain hypersentry.top --x-ui --background
```

The script prompts for the Arvan access key without displaying it. It then returns to the shell and continues in the background. Follow the job with:

```bash
tail -f /var/log/arvancloud-letsencrypt/acme-issue.log
```

For a foreground run:

```bash
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain hypersentry.top --x-ui
```

For a general web server or reverse proxy, omit `--x-ui` and provide an output directory and reload command:

```bash
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain example.com --install-dir /etc/ssl/acme/example.com --reload-cmd 'systemctl reload nginx' --background
```

## Arvan Cloud setup

1. Add the domain to Arvan Cloud DNS and make sure its nameservers are active.
2. Create an access key in the Arvan panel.
3. Grant only the required DNS permissions for the target zone.
4. Run the quick-start command and paste the key at the hidden prompt.

Do not put a real access key directly in a command or commit it to Git. If an environment variable is required for automation, use a protected secret store:

```bash
export ARVAN_ACCESS_KEY='Apikey REPLACE_WITH_A_SECRET'
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain example.com --background
unset ARVAN_ACCESS_KEY
```

The script accepts either the raw key or the complete `Apikey <key>` value. It adds the prefix when necessary.

## x-ui mode

For the current 3x-ui layout, use:

```bash
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain hypersentry.top --x-ui --background
```

This maps the certificate files as follows:

| File | Path |
| --- | --- |
| Certificate | `/root/cert/hypersentry.top/cert.pem` |
| Chain | `/root/cert/hypersentry.top/chain.pem` |
| Full chain | `/root/cert/hypersentry.top/fullchain.pem` |
| Private key | `/root/cert/hypersentry.top/privkey.pem` |
| Reload command | `x-ui restart` |

The x-ui database does not need to be modified if it already points to `/root/cert/hypersentry.top/fullchain.pem` and `/root/cert/hypersentry.top/privkey.pem`.

## Options

```text
--domain DOMAIN
--email EMAIL
--install-dir DIR
--reload-cmd COMMAND
--x-ui
--background
--force
--dns-sleep SECONDS
--debug
```

Examples:

```bash
# Create a certificate in the default generic directory.
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain example.com

# Force a fresh order after correcting DNS permissions.
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain example.com --force --debug

# Use a custom application reload command.
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | bash -s -- --domain example.com --install-dir /opt/app/tls --reload-cmd '/opt/app/bin/reload-tls'
```

## Files and paths on the server

| Purpose | Default path |
| --- | --- |
| acme.sh home | `/root/.acme.sh` |
| acme.sh binary | `/root/.acme.sh/acme.sh` |
| Arvan DNS plugin | `/root/.acme.sh/dnsapi/dns_arvan.sh` |
| ACME account configuration | `/root/.acme.sh/account.conf` |
| Installer log | `/var/log/arvancloud-letsencrypt/install.log` |
| Issuance log | `/var/log/arvancloud-letsencrypt/acme-issue.log` |
| Arvan preflight response | `/var/log/arvancloud-letsencrypt/arvan-domains.json` |

The access key is saved by acme.sh in `account.conf`; keep that file mode `600` and the acme.sh directory private.

## Renewal model

The important renewal property is that issuance creates a real acme.sh renewal configuration such as:

```text
/root/.acme.sh/example.com_ecc/example.com.conf
```

That configuration records the domain, wildcard SAN, DNS plugin, key type, install paths, and reload command. The cron job then runs acme.sh for every registered certificate:

```cron
27 0,6,12,18 * * * /root/.acme.sh/acme.sh --cron
```

The script does not add a domain-specific cron command. This is intentional: the domain is registered by `--issue`, and the existing acme.sh cron discovers it through its renewal configuration.

Verify the registration with:

```bash
/root/.acme.sh/acme.sh --list
/root/.acme.sh/acme.sh --info -d example.com
crontab -l | grep -F -- '--cron'
```

An ordinary cron test may report that renewal was skipped because the next renewal time is in the future. That is a successful registration, not an error. Use `--force` only for an intentional manual test.

## Verification

```bash
openssl x509 -in /etc/ssl/acme/example.com/fullchain.pem -noout -subject -issuer -dates -ext subjectAltName

printf '' | openssl s_client -connect 127.0.0.1:443 -servername example.com 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates -ext subjectAltName

sha256sum /root/.acme.sh/example.com_ecc/fullchain.cer /etc/ssl/acme/example.com/fullchain.pem
```

For x-ui, replace the paths and port as needed:

```bash
printf '' | openssl s_client -connect 127.0.0.1:2585 -servername hypersentry.top 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

## Troubleshooting

### `401 Unauthenticated`

The key is invalid, revoked, or does not use the expected Arvan authorization format. The installer accepts both forms:

```text
RAW_KEY
Apikey RAW_KEY
```

It sends `Authorization: Apikey RAW_KEY` to Arvan.

### HTTP 200 but `total: 0`

The key can reach the API but cannot see the target zone. Update the Arvan key policy or create a key in the account that owns the domain. The installer stops before ACME issuance in this case.

### `invalid domain` from dns_arvan

The older acme.sh Arvan plugin queried `/domains/<candidate>` while the working API flow uses the domains list endpoint. This repository installs the patched plugin and uses `jq` to find the zone ID. It also handles the `Apikey` authorization prefix.

### SSH disconnects during issuance

Use `--background` and follow the log:

```bash
tail -f /var/log/arvancloud-letsencrypt/acme-issue.log
```

The background process does not read from SSH stdin and ignores `SIGHUP`.

### ACME reports a future renewal time

That is normal after a successful issuance. Check that the certificate exists, `--list` contains the domain, and `--info` shows the install paths and reload command.

### TXT record remains in Arvan

The plugin removes the ACME TXT records after validation. If a job is interrupted, remove only the stale `_acme-challenge` TXT values after confirming that no issuance for the same domain is still running.

## Design notes

The repository deliberately uses DNS-01 rather than HTTP-01:

- Wildcard identifiers require DNS-01.
- It does not require port 80.
- It works when x-ray or another service owns port 80.
- Arvan creates and removes the `_acme-challenge` TXT records through its API.

The installer makes backups of an existing `dns_arvan.sh` before replacing it. It does not modify x-ui's SQLite database and does not delete existing certificates.

## Manual TXT fallback

API automation is the supported path. If API access is unavailable, use an ACME client with manual DNS mode and create the TXT record shown by the client at:

```text
_acme-challenge.example.com
```

Manual mode is not suitable for unattended renewal because every renewal requires a new TXT value and human confirmation.

## Repository layout

```text
.
├── install.sh
├── src/
│   └── dns_arvan.sh
├── .github/workflows/lint.yml
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── ROADMAP.md
├── SECURITY.md
└── README.md
```

`install.sh` contains the same plugin source as `src/dns_arvan.sh` so it can be executed directly from a GitHub raw URL without first cloning the repository.

## Local development

```bash
git clone https://github.com/power0matin/arvancloud-letsencrypt.git
cd arvancloud-letsencrypt
chmod +x install.sh src/dns_arvan.sh
bash -n install.sh
sh -n src/dns_arvan.sh
```

Do not run the installer against a production zone while developing. Test with a dedicated Arvan DNS zone and a separate access key.

## Sources

- [acme.sh](https://github.com/acmesh-official/acme.sh)
- [acme.sh DNS API documentation](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)
- [upstream Arvan DNS plugin](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_arvan.sh)
- [Let's Encrypt DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
