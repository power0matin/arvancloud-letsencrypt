# Manual ACME staging test

Use this procedure to validate ArvanCloud DNS-01 integration against the Let's Encrypt **staging** CA without replacing the certificate files used by a live service.

## Safety properties

- Use a dedicated test subdomain you control, for example `acme-test.example.com`; its parent DNS zone must be managed in the intended ArvanCloud account.
- The script requires root and prompts for the domain and API key. The API key prompt is hidden; do not place the key in command arguments, shell history, or a committed file.
- The test uses `letsencrypt_test`, a separate temporary acme.sh home, a separate config home, and a separate certificate home.
- It runs `--issue` only. It does **not** run `--install-cert`, restart a service, or write to `/root/cert/` or `/etc/ssl/acme/`.
- On exit or common signals, it removes the temporary home, including the staging account config, stored test token, and staging certificate. It does not delete a DNS zone or any unrelated DNS record.
- Staging certificates are not trusted for normal browser traffic. This procedure is an integration test, not a production deployment.

## Run the test

From the repository checkout, run:

```bash
sudo bash tests/staging/run-acme-staging.sh ./src/dns_arvan.sh
```

Enter a dedicated test subdomain when prompted, then enter an ArvanCloud API key with only the required read/list/create/delete permissions for the parent DNS zone.

The script copies the supplied plugin and the installed acme.sh script into an isolated temporary home and requests both the exact test hostname and its wildcard certificate through the staging CA. It does not modify the production acme.sh account/configuration directory.

## Optional GitHub Actions run

The repository also has a manual-only **ACME staging integration** workflow. To enable it, add these two repository secrets under **Settings → Secrets and variables → Actions**:

- `ARVAN_STAGING_DOMAIN`: a dedicated test subdomain beginning with `acme-test.`, for example `acme-test.example.com`. Its parent DNS zone must be managed by the intended ArvanCloud account.
- `ARVAN_STAGING_API_KEY`: a revocable, least-privilege API key with only the DNS permissions required for the test zone.

Then open **Actions → ACME staging integration → Run workflow**, choose the `main` branch, and explicitly choose `RUN_STAGING`. The workflow rejects other branches, missing secrets, a domain without the `acme-test.` prefix, or an absent confirmation.

The workflow checks out acme.sh at a pinned full commit SHA and runs the same isolated staging script. It does not install the staging certificate into a service path. The test API key is passed as an environment secret, never as a command-line argument, and the temporary acme.sh home is removed on exit. Do not use a production hostname or production API key.

The workflow is prepared but has **not** been run against a live ArvanCloud test zone yet. That final check requires the repository secrets above to be configured by the repository owner.

## Interpreting the result

A successful run confirms that the staging CA accepted the DNS-01 challenge and issued a staging certificate for the supplied names. A failure may indicate incorrect API permissions, a zone that is not visible to the key, DNS propagation delay, connectivity problems, or a staging CA issue; inspect the visible error before changing permissions.

Do not enable acme.sh debug output for this test or share unreviewed logs. Never use the production hostname as the test target, and do not manually remove TXT records while another issuance for the same challenge is running.

The API key is temporarily saved by acme.sh inside the isolated staging config because renewals normally need persisted DNS credentials. The script deletes that directory when it exits. Use a dedicated, revocable test key and revoke it after the test if it is no longer needed.
