# ABN VPN node heartbeat

ABN VPN v0.5 monitors the WireGuard node with an **outbound heartbeat**. The Oracle VM does not need an HTTP health port exposed to the internet.

## Netlify

Set one secret environment variable:

- `VPN_NODE_HEARTBEAT_TOKEN` — a long random token. Never commit it.

The node POSTs to:

- `POST /api/node-heartbeat`

Netlify stores only public-safe aggregate status in site-scoped Netlify Blobs:

- node ID
- server-side received timestamp
- WireGuard interface name
- total peer count
- peers with a recent handshake
- agent version

No WireGuard private key, peer public key, client address, browsing history, DNS query, or destination metadata is stored.

## Oracle node

After WireGuard is installed, run:

```bash
sudo ./install-heartbeat.sh https://abn-vpn.netlify.app "$TOKEN" us-sanjose-1
```

This creates a systemd timer that sends a heartbeat about once per minute.

## Health interpretation

- Online: heartbeat <= 180 seconds old
- Degraded: heartbeat 181–600 seconds old
- Offline: heartbeat > 600 seconds old
- Setup required: no heartbeat has ever been stored
