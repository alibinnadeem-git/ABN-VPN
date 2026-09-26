# ABN VPN

Zero-cost-first VPN MVP:

- **Production control plane:** Netlify
- **Secondary deployment target:** Vercel
- **VPN data plane:** WireGuard
- **First node:** Oracle Cloud Always Free, preferably `us-sanjose-1`
- **Repository:** this project

## What works

- Static Netlify production dashboard with Vercel-compatible fallback.
- Serverless health and node-inventory APIs.
- Signed outbound-only node heartbeat to Netlify.
- Netlify Blobs-backed node health state.
- Secure-by-default `.gitignore` for VPN secrets.
- Ubuntu WireGuard bootstrap.
- Persistent client creation with mobile QR output.
- Persistent client revocation.
- Oracle Cloud setup and verification scripts.

## Production control plane

Production runs on Netlify using `site/` and `netlify/functions/`.

Public node inventory:

```text
VPN_NODES_JSON=[{"id":"us-sanjose-1","name":"US West — San Jose","region":"us-sanjose-1","provider":"Oracle Cloud","status":"setup-required"}]
```

Never store WireGuard private keys in Netlify, Vercel, GitHub, or client-side code.

## First-node bootstrap

```bash
sudo ./infra/oracle-cloud/bootstrap-first-node.sh PUBLIC_IP_OR_DNS ali-iphone 10.77.0.2/32
sudo ./infra/oracle-cloud/verify-node.sh
```

Then install the outbound heartbeat:

```bash
sudo ./infra/oracle-cloud/install-heartbeat.sh https://abn-vpn.netlify.app "$TOKEN" us-sanjose-1
```

See `docs/ORACLE_FREE_SETUP.md`, `docs/CONNECT_NODE_TO_NETLIFY.md`, and `docs/NODE_HEARTBEAT.md`.

## Validation

```bash
npm test
bash -n infra/oracle-cloud/init-wireguard.sh
bash -n infra/oracle-cloud/add-client.sh
bash -n infra/oracle-cloud/remove-client.sh
bash -n infra/oracle-cloud/bootstrap-first-node.sh
bash -n infra/oracle-cloud/install-heartbeat.sh
bash -n infra/oracle-cloud/verify-node.sh
```

## v0.5

- Peers persist across reboot.
- Revocation removes runtime and persistent state.
- IPv4 full-tunnel is explicit.
- Firewall forwarding is constrained to WireGuard/public-interface paths.
- Node status uses outbound HTTPS heartbeats instead of another inbound VM port.
- Heartbeats expose aggregate operational status only.
