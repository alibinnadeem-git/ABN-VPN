# Connect the Oracle WireGuard node to Netlify

After the Oracle VM is live and WireGuard is initialized, register only public-safe node metadata in the ABN VPN control plane.

## 1. Register node inventory

In Netlify project `abn-vpn`, create the environment variable `VPN_NODES_JSON` with a value like:

```json
[{"id":"us-sanjose-1","name":"US West — San Jose","region":"us-sanjose-1","provider":"Oracle Cloud","status":"online","endpoint":"203.0.113.10:51820"}]
```

Replace the example IP with the VM public IPv4 address or DNS name.

## 2. Health telemetry

`VPN_NODE_HEALTH_URL` and `VPN_NODE_HEALTH_TOKEN` are optional in v0.3. Leave them unset until an authenticated HTTPS node-health endpoint exists. The dashboard will correctly show the node as requiring health integration rather than exposing an insecure plaintext endpoint.

## 3. Redeploy

Environment variable changes should be followed by a fresh production deployment so the control plane can read the current values.

## Security rule

Never upload or store these in Netlify, GitHub, logs, or the dashboard:

- `/etc/wireguard/server.key`
- client private keys
- complete client `.conf` files
- QR codes containing client private keys

Those secrets stay only on the VPN server and the enrolled client device.
