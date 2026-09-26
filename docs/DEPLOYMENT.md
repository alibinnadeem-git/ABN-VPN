# ABN VPN deployment matrix

## Control plane

The repository supports both Vercel and Netlify.

### Netlify
- Publish directory: `site`
- Functions directory: `netlify/functions`
- Routes: `/api/health`, `/api/nodes`, `/api/node-health`

### Vercel
- Static root: `index.html`
- Functions: `api/*.js`

## Data plane

The actual VPN tunnel runs on persistent Linux compute. The zero-cost-first target is an Oracle Cloud Always Free eligible VM in `us-sanjose-1`, subject to Oracle account eligibility and capacity.

After the VM is created, run `infra/oracle-cloud/init-wireguard.sh` as root, then create a client with `add-client.sh`.

Set these control-plane environment variables after the VPN node is live:

- `VPN_NODES_JSON`: public-safe node inventory only. Never place private keys here.
- `VPN_NODE_HEALTH_URL`: optional HTTPS health endpoint for the node.
- `VPN_NODE_HEALTH_TOKEN`: optional bearer token for that health endpoint.
