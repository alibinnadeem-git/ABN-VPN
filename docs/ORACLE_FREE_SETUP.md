# Oracle Cloud Always Free setup

## Recommended first node

- Provider: Oracle Cloud Infrastructure (OCI)
- Home region: **US West (San Jose) — `us-sanjose-1`**
- Shape: Prefer an **Always Free eligible Ampere A1 Flex** instance when capacity is available.
- OS: Ubuntu 22.04 or 24.04 LTS, Always Free eligible.
- Public IPv4: enabled.
- Ingress: SSH/22 restricted to your admin IP when practical; WireGuard UDP/51820 open to clients.

> Oracle requires Always Free compute to be created in the tenancy's home region. Choose the home region carefully during signup.

## OCI console steps

1. Create an OCI account and choose **San Jose (`us-sanjose-1`) as the home region** if the console offers it for the account.
2. Create a VCN with a public subnet, internet gateway, route table, and a security list/NSG.
3. Create an Always Free eligible compute instance in the public subnet.
4. Assign a public IPv4 address.
5. Add ingress rules:
   - TCP 22 from your admin IP/CIDR.
   - UDP 51820 from `0.0.0.0/0` for the VPN tunnel.
6. Copy this repo's `infra/oracle-cloud/*.sh` files to the VM.
7. Run:

```bash
sudo chmod +x *.sh
sudo ./init-wireguard.sh
sudo ./add-client.sh ali-iphone 10.77.0.2/32 <SERVER_PUBLIC_IP_OR_DNS>
```

8. Scan the printed QR code in the official WireGuard app.
9. Test your public IP before/after connecting.

## Important free-tier caveats

Oracle states that idle Always Free compute instances may be reclaimed. Always Free capacity can also be temporarily unavailable in a region. Keep backups of your WireGuard configuration and server public key so the node can be recreated.

## Security

- Never commit `/etc/wireguard/server.key` or client `.conf` files.
- Do not expose SSH to the whole internet if you can restrict it.
- Use SSH keys, disable password authentication after validating key access, and patch the VM regularly.


## Recommended v0.4 activation

After copying `infra/oracle-cloud/` to the VM:

```bash
cd infra/oracle-cloud
sudo ./bootstrap-first-node.sh PUBLIC_IP_OR_DNS ali-iphone 10.77.0.2/32
sudo ./verify-node.sh
```

The first command initializes WireGuard, creates a persistent peer for the first iPhone, prints the QR code, and prints the public-safe `VPN_NODES_JSON` value for Netlify. The client is IPv4 full-tunnel in v0.4; IPv6 is deliberately left outside the tunnel until end-to-end IPv6 routing is explicitly configured.
