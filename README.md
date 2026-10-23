<h1 align="center">ArvanCloud Let's Encrypt</h1>

<p align="center">
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml"><img src="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml/badge.svg?branch=main" alt="Shell checks"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/stargazers"><img src="https://img.shields.io/github/stars/power0matin/arvancloud-letsencrypt?style=flat-square&label=Stars" alt="GitHub stars"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0--or--later-blue?style=flat-square" alt="GPL-3.0-or-later license"/></a>
</p>

<p align="center">Issue and renew Let's Encrypt wildcard certificates using ArvanCloud DNS-01 validation.</p>

## Features

- Issues a certificate for both `example.com` and `*.example.com`.
- Creates and removes `_acme-challenge` TXT records through the ArvanCloud DNS API.
- Installs certificate files to a configurable directory and can run a reload command.
- Supports an optional x-ui-compatible certificate path and reload command.
- Registers certificates with acme.sh for scheduled renewal.
- Includes an interactive terminal menu plus non-interactive CLI commands.
- Requests the ArvanCloud API key without echoing the prompt input.
- Checks the selected zone without saving the full domains API response to disk or printing other visible zones to logs.
- Backs up an existing ArvanCloud DNS plugin before replacing it.

## Quick start

On a supported Debian/Ubuntu server, run this command as root. It opens the interactive menu:

```bash
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/v1.1.0/install.sh | sudo bash
```

To inspect the entrypoint before running it:

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/v1.1.0/install.sh
less install.sh
bash install.sh
```

The repository must be public for the raw GitHub URL to work for everyone. Review any remote installer before running it with root privileges. The installer downloads its menu and certificate core from this repository's `main` branch; use a tagged, version-pinned release when one is available.

## Release

The installer entrypoint and menu download matching components from the versioned `v1.1.0` tag instead of following the moving `main` branch.

After confirming that the repository is public and the release candidate has passed CI, run the **Publish GitHub Release** workflow from the Actions tab. Set the tag to `v1.1.0` and select `PUBLISH` in the confirmation field. The workflow refuses to create a release while repository visibility is private, when the tag already exists, or when the changelog has no matching version section.

## Interactive menu

The menu offers:

1. Issue and install a wildcard certificate.
2. List certificates registered with acme.sh.
3. Inspect a certificate's subject, issuer, validity dates, SANs, and hostname coverage.
4. Run acme.sh's normal renewal check.
5. View recent logs.
6. Check local prerequisites and renewal setup.

The menu reads user input from `/dev/tty`, so it works when the installer is piped directly from `curl`.

## Requirements

- Debian or Ubuntu with root access.
- A domain whose authoritative DNS is managed by ArvanCloud.
- An ArvanCloud access key with permission to list the intended zone and create, list, and delete DNS records.
- Outbound HTTPS access to ArvanCloud and the ACME certificate authority.

Wildcard certificates use DNS-01 validation, so port 80 is not required. Missing system prerequisites are installed with `apt-get`. acme.sh is installed from its upstream installer if it is not already present.

## Non-interactive usage

Issue a certificate for a domain you control:

```bash
sudo bash install.sh --domain example.com
```

Choose an output directory and reload Nginx when installation succeeds:

```bash
sudo bash install.sh \
  --domain example.com \
  --install-dir /etc/ssl/acme/example.com \
  --reload-cmd 'systemctl reload nginx'
```

Use the x-ui-compatible paths and reload command:

```bash
sudo bash install.sh --domain example.com --x-ui
```

Continue issuance in the background after an SSH disconnect:

```bash
sudo bash install.sh --domain example.com --background
```

The ArvanCloud key is requested in a hidden prompt. For unattended use, provide `ARVAN_ACCESS_KEY` through a protected secret manager instead of putting the value in shell history or a command line. Never commit credentials to this repository.

### Management commands

```bash
sudo bash install.sh --list
sudo bash install.sh --info example.com
sudo bash install.sh --renew
sudo bash install.sh --logs
sudo bash install.sh --check
sudo bash install.sh --help
```

``--renew`` runs the normal acme.sh renewal check; it does not force every certificate to renew. Use ``--force`` only for an intentional new certificate order. ``--debug`` can produce detailed logs, so review those logs before sharing them.

## Certificate output

Generic mode defaults to ``/etc/ssl/acme/DOMAIN/``:

| File | Purpose |
| --- | --- |
| ``cert.pem`` | Leaf certificate |
| ``chain.pem`` | Intermediate chain |
| ``fullchain.pem`` | Leaf certificate plus intermediate chain |
| ``privkey.pem`` | Private key; mode ``600`` |

With ``--x-ui``, the default output directory is ``/root/cert/DOMAIN/``. Existing x-ui configuration or its database is not modified. Configure the service to use the corresponding output paths.

## Credential and log handling

- Use an API key with only the permissions needed for the intended DNS zone.
- The tool accepts a raw key or an ``Apikey ...`` value.
- acme.sh stores DNS credentials in its account configuration for renewals. Keep ``/root/.acme.sh/`` and ``account.conf`` private.
- Logs are stored in ``/var/log/arvancloud-letsencrypt/``; the directory is mode ``700`` and new log files use the root-only umask ``077``.
- The installer does not save the complete DNS-zone API response in a persistent file or include a list of visible domains in logs.
- Never post access keys, private keys, ACME account configuration, or unreviewed debug logs in issues.

## Renewal

The tool registers the certificate with acme.sh and ensures an acme.sh cron job exists. The scheduled job checks registered certificates and renews them when necessary. Verify registration with:

```bash
sudo bash install.sh --list
sudo bash install.sh --info example.com
sudo crontab -l | grep -F -- '--cron'
```

A normal renewal check can skip a certificate whose renewal window has not started; that is expected and does not by itself mean setup failed.

## Troubleshooting

**HTTP 401 / unauthenticated** — Confirm the key is valid and has access to the intended DNS zone. Revoke and replace a key if it has been exposed.

**The domain is not visible to the key** — Confirm the domain is delegated to ArvanCloud DNS and that the key's account can access that zone.

**Certificate issuance fails** — Check ``/var/log/arvancloud-letsencrypt/acme-issue.log``. Inspect the error before sharing it because debug output can contain operational details.

**SSH disconnects during issuance** — Use ``--background`` and follow the issuance log with ``sudo tail -f /var/log/arvancloud-letsencrypt/acme-issue.log``.

**A TXT record remains after an interrupted job** — Confirm that no issuance for the domain is still running before removing a stale ``_acme-challenge`` record manually.

## Development and tests

```bash
bash -n install.sh
bash -n menu.sh
bash -n core.sh
sh -n src/dns_arvan.sh
shellcheck install.sh menu.sh core.sh src/dns_arvan.sh
```

Use a dedicated test zone and a separate least-privilege key. Never test changes against a production DNS zone.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
