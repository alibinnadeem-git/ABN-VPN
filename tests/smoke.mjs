import fs from 'node:fs';
const required = [
  'index.html', 'site/index.html', 'vercel.json', 'netlify.toml',
  'api/health.js', 'api/nodes.js', 'netlify/functions/health.mts', 'netlify/functions/node-heartbeat.mts',
  'infra/oracle-cloud/init-wireguard.sh', 'infra/oracle-cloud/add-client.sh',
  'infra/oracle-cloud/remove-client.sh', 'infra/oracle-cloud/bootstrap-first-node.sh',
  'infra/oracle-cloud/install-heartbeat.sh',
  'infra/oracle-cloud/verify-node.sh', 'docs/ORACLE_FREE_SETUP.md',
  'docs/CONNECT_NODE_TO_NETLIFY.md', 'docs/NODE_HEARTBEAT.md'
];
for (const p of required) {
  if (!fs.existsSync(new URL(`../${p}`, import.meta.url))) throw new Error(`Missing ${p}`);
}
const html = fs.readFileSync(new URL('../site/index.html', import.meta.url), 'utf8');
if (!html.includes('Netlify control plane')) throw new Error('Production page is not Netlify-branded');
if (html.includes('Control plane</div><div class="value">Vercel')) throw new Error('Stale Vercel production branding remains');
console.log(`Smoke test passed: ${required.length} required files found and production branding verified.`);
