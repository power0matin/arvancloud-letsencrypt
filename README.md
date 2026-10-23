<h1 align="center">ArvanCloud Let's Encrypt</h1>

<!-- repo-badges:start -->
<p align="center">
  <a href="https://hits.sh/github.com/power0matin/arvancloud-letsencrypt/"><img src="https://hits.sh/github.com/power0matin/arvancloud-letsencrypt.svg?style=flat-square&amp;label=Views&amp;labelColor=18181B&amp;color=0EA5E9&amp;logo=github" alt="Repository Views"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/stargazers"><img src="https://img.shields.io/github/stars/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Stars&amp;labelColor=18181B&amp;color=F59E0B&amp;logo=github&amp;logoColor=white" alt="GitHub Stars"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/forks"><img src="https://img.shields.io/github/forks/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Forks&amp;labelColor=18181B&amp;color=6366F1&amp;logo=github&amp;logoColor=white" alt="GitHub Forks"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/issues"><img src="https://img.shields.io/github/issues/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Issues&amp;labelColor=18181B&amp;color=22C55E&amp;logo=github&amp;logoColor=white" alt="GitHub Issues"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=License&amp;labelColor=18181B&amp;color=EF4444&amp;logo=github&amp;logoColor=white" alt="GitHub License"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/releases"><img src="https://img.shields.io/github/v/release/power0matin/arvancloud-letsencrypt?style=flat-square&amp;label=Latest%20release&amp;labelColor=18181B&amp;color=0EA5E9" alt="Latest stable release"/></a>
  <a href="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml"><img src="https://github.com/power0matin/arvancloud-letsencrypt/actions/workflows/lint.yml/badge.svg?branch=main" alt="Shell checks"/></a>
</p>
<!-- repo-badges:end -->

<p align="center">Issue and renew Let's Encrypt wildcard certificates using ArvanCloud DNS-01 validation.</p>

<p align="center"><a href="./README.fa.md">راهنمای فارسی (HTML، راست‌چین)</a></p>

<p align="center">
  <a href="#features">Features</a> · <a href="#quick-start">Quick start</a> · <a href="#interactive-menu">Menu</a> · <a href="#non-interactive-usage">CLI</a> · <a href="#troubleshooting">Troubleshooting</a> · <a href="CHANGELOG.md">Changelog</a> · <a href="LICENSE">License</a>
</p>

## Features

- Issues a certificate for both `example.com` and `*.example.com`.
- Creates and removes `_acme-challenge` TXT records through the ArvanCloud DNS API.
- Installs certificate files to a configurable directory and can run a reload command.
- Supports an optional x-ui-compatible certificate path and reload command.
- Registers certificates with acme.sh for scheduled renewal.
- Includes an interactive terminal menu plus non-interactive CLI commands.
- Clears the terminal between menu views and allows a corrected ArvanCloud API key to be entered without repeating the domain and certificate options.
- Requests the ArvanCloud API key without echoing the prompt input.
- Checks the selected zone without saving the full domains API response to disk or printing other visible zones to logs.
- Backs up an existing ArvanCloud DNS plugin before replacing it.

## Quick start

On a supported Debian/Ubuntu server, run this command as root. It opens the interactive menu:

```bash
curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/latest/install.sh | sudo bash
```

To inspect the entrypoint before running it:

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/latest/install.sh
less install.sh
bash install.sh
```

Review any remote installer before running it with root privileges. The `latest` branch is the moving installation channel; after a successful release, the release workflow advances it to the published source commit. For a fixed version, replace `latest` with a version tag such as `v1.1.1`.

## Release

The installer and menu load matching components from the moving `latest` branch. The release workflow advances that branch after publishing a release; use a version tag instead of `latest` when you need reproducible, version-pinned installation.

To publish the next version, update `core.sh` and `CHANGELOG.md`, let CI pass, then open **Actions → Publish GitHub Release**. Enter the new semantic version tag (for example, `v1.1.2`) and choose `PUBLISH` in the confirmation field.

Release titles contain **only the version** (for example, `v1.1.2`). The project name and changelog notes belong in the release description. The workflow refuses to publish if the repository is not public, the tag or release already exists, or the matching changelog section is missing.
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

## ArvanCloud API key setup

Use an **ArvanCloud Machine User API key** and explicitly grant it access to the DNS zone. A key that authenticates successfully but cannot list the requested zone will fail with a message such as `The ArvanCloud key can reach the API but cannot see the requested DNS zone.`

- **Open the Machine User page:** [ArvanCloud panel — IAM / Machine Users](https://panel.arvancloud.ir/profile/iam/machine-users).
- **Official guide:** [Create and obtain an API key](https://docs.arvancloud.ir/fa/developer-tools/api/api-key/).
- **Access policies guide:** [ArvanCloud IAM access policies](https://docs.arvancloud.ir/fa/accounts/iam/policies/).

### Create the key and grant DNS access

1. Sign in to the ArvanCloud panel, open **Settings → IAM → Machine Users**, and create a Machine User.
2. Copy the generated API key and store it securely. ArvanCloud only shows the key when it is created; it cannot be retrieved later.
3. Open **Settings → IAM → Access Policies** (or the resource-access management page). Add the Machine User to an access policy on the workspace or the relevant resource, then assign a role that allows it to view the intended CDN/DNS zone and manage DNS records.
4. Make sure the policy covers the zone `example.com` in the **same ArvanCloud account/workspace** as the key. The tool needs to discover the zone and create, list, and delete the ACME `TXT` record. Prefer the narrowest resource-level permissions available; do not grant broad administrator access unless your own policy requires it.
5. Run the installer again and enter the complete API key at the hidden prompt. The prompt accepts either the raw key or the complete `Apikey ...` value.

If the key still cannot see the zone, confirm that `example.com` has been added to ArvanCloud DNS in that same account and that the access policy has been saved and applied. The installer intentionally does not print or save the account's full zone list.

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

`--renew` runs the normal acme.sh renewal check; it does not force every certificate to renew. Use `--force` only for an intentional new certificate order. `--debug` can produce detailed logs, so review those logs before sharing them.

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

**The domain is not visible to the key** — Open [Machine Users](https://panel.arvancloud.ir/profile/iam/machine-users), then review the [IAM access policies](https://docs.arvancloud.ir/fa/accounts/iam/policies/). Grant the key access to the `example.com` DNS zone and to DNS record operations in the same account/workspace. Also confirm that the zone is actually present in that account.

After this check fails, the installer asks for a replacement key in a hidden prompt. Correct the key or its IAM policy, then paste the corrected key; the domain and other options are kept. Press Enter without a key to cancel.

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


## Contact

**Matin Shahabadi**

- Website: [matinshahabadi.ir](https://matinshahabadi.ir)
- Email: [me@matinshahabadi.ir](mailto:me@matinshahabadi.ir)
- GitHub: [power0matin](https://github.com/power0matin)
- LinkedIn: [matin-shahabadi](https://www.linkedin.com/in/matin-shahabadi)

<p align="center">
  <b>If this helped you, consider giving it a star!</b><br>
  <sub>Your support keeps the project alive and helps others find it.</sub>
</p>

<!-- Star history widget -->
<p align="center">
  <a href="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history?repo_id=1361637812" target="_blank" style="display: block" align="center">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=1361637812&amp;image_size=auto&amp;color_scheme=dark" width="721" height="auto">
      <img alt="Star History of power0matin/arvancloud-letsencrypt" src="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=1361637812&amp;image_size=auto&amp;color_scheme=light" width="721" height="auto">
    </picture>
  </a>
</p>
<!-- Made with [OSS Insight](https://ossinsight.io/) -->

<p align="center">
  Created by <a href="https://github.com/power0matin">power0matin</a>
</p>
