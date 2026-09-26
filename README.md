# ABN VPN

Zero-cost-first VPN MVP:

- **Production control plane:** Netlify
- **Secondary deployment target:** Vercel
- **VPN data plane:** WireGuard
- **First node:** Oracle Cloud Always Free, preferably `us-sanjose-1`
- **Repository:** this project

## What works in v0.1

- Static Netlify production dashboard (Vercel-compatible fallback retained).
- Serverless health and node-inventory APIs.
- Secure-by-default `.gitignore` for VPN secrets.
- Ubuntu WireGuard bootstrap script.
- Client creation script with mobile QR output.
- Client revocation script.
- Oracle Cloud setup guide.

## Deploy the production control plane

Production currently runs on Netlify using `site/` and `netlify/functions/`. The repository remains Vercel-compatible through the root `index.html` and `api/` directory.

Optional environment variable:

```text
VPN_NODES_JSON=[{"id":"us-sanjose-1","name":"US West — San Jose","region":"us-sanjose-1","provider":"Oracle Cloud","status":"online","endpoint":"vpn.example.com:51820"}]
```

This variable contains public node metadata only. Never place WireGuard private keys in Netlify or Vercel environment variables.

## Create the VPN node

See [`docs/ORACLE_FREE_SETUP.md`](docs/ORACLE_FREE_SETUP.md).

## Validation

```bash
npm test
bash -n infra/oracle-cloud/init-wireguard.sh
bash -n infra/oracle-cloud/add-client.sh
bash -n infra/oracle-cloud/remove-client.sh
```

## Current boundary

The v0.1 control plane displays node metadata but does not remotely mutate WireGuard peers. Peer provisioning is intentionally local to the VPN node until an authenticated node-agent channel is added in Phase 2.


## Deployment targets

- Netlify: immediate serverless control-plane deployment using `site/` + `netlify/functions/`.
- Vercel: supported through the root `index.html` + `api/` functions.
- Oracle Cloud: WireGuard data plane; requires a user-owned Oracle Cloud tenancy and an Always Free eligible VM.

See `docs/DEPLOYMENT.md`.


## First-node one-command bootstrap

```bash
sudo ./infra/oracle-cloud/bootstrap-first-node.sh PUBLIC_IP_OR_DNS ali-iphone 10.77.0.2/32
sudo ./infra/oracle-cloud/verify-node.sh
```

Then follow [`docs/CONNECT_NODE_TO_NETLIFY.md`](docs/CONNECT_NODE_TO_NETLIFY.md).


## v0.4 reliability fixes

- Client peers are persisted under `/etc/wireguard/peers/` and survive server reboot.
- Client revocation removes both runtime and persistent peer state.
- IPv4 full-tunnel is explicit; IPv6 is intentionally not captured until an IPv6 tunnel/NAT policy is implemented.
- UFW forwarding rules are added specifically between `wg0` and the public interface.
- `verify-node.sh` checks runtime peer count against persistent peer fragments.

## v0.5 monitoring model

The preferred production health path is now **outbound-only** from the WireGuard VM. The node sends a signed heartbeat to Netlify every minute; Netlify Blobs stores only aggregate/public-safe status. No additional inbound health port is opened on Oracle.

Required Netlify secret:

- `VPN_NODE_HEARTBEAT_TOKEN`

Install on the Oracle node after WireGuard is active:

```bash
sudo ./infra/oracle-cloud/install-heartbeat.sh https://abn-vpn.netlify.app "$TOKEN" us-sanjose-1
```

See `docs/NODE_HEARTBEAT.md`.
