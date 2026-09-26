# Security policy

## Secrets that must never be committed

- WireGuard private keys
- Client `.conf` files
- OCI API private keys / credentials
- Vercel tokens
- Database service-role keys

## Minimum deployment controls

- SSH key authentication
- Restrict TCP/22 at the OCI NSG/security list
- Expose only UDP/51820 for WireGuard
- Apply OS security updates
- Keep client private keys on the client device
- Revoke lost devices by removing their WireGuard peer public key
