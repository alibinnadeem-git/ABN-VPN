# Oracle provisioning from GitHub Actions

ABN VPN v0.6 adds a manual GitHub Actions workflow that can create the Oracle Cloud VCN, public subnet, security list, and VPN VM with Terraform.

## Required repository secrets

Create these GitHub Actions repository secrets:

- `OCI_TENANCY_OCID`
- `OCI_USER_OCID`
- `OCI_FINGERPRINT`
- `OCI_PRIVATE_KEY`
- `OCI_COMPARTMENT_OCID`
- `OCI_REGION` — normally `us-sanjose-1`
- `VPN_NODE_HEARTBEAT_TOKEN` — same secret configured in the Netlify `abn-vpn` project
- `VPN_PROFILE_PASSPHRASE` — used only to encrypt the generated client profile artifact

Do not commit these values to the repository.

## Run

Open **Actions → Provision Oracle VPN Node → Run workflow**.

The workflow:

1. Generates an ephemeral SSH key on the GitHub runner.
2. Detects that runner's current public IPv4 address.
3. Runs Terraform with SSH restricted to that single /32 address.
4. Waits for the Oracle VM to become reachable.
5. Copies the reviewed WireGuard bootstrap scripts from this repository.
6. Creates the first iPhone peer without printing its private key to CI logs.
7. Installs the outbound Netlify heartbeat.
8. Runs the node verification script.
9. Encrypts the iPhone WireGuard profile and uploads only the encrypted file as a short-lived Actions artifact.
10. Removes TCP/22 from the OCI security list after provisioning while leaving UDP/51820 open.

The workflow is intentionally manual because it creates cloud infrastructure.

## Free-tier caveat

Oracle capacity and account eligibility determine whether an Always Free eligible shape can actually be created. The workflow defaults to `VM.Standard.A1.Flex` with 1 OCPU / 6 GB memory.
