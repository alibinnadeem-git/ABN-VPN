function safeNodes(raw) {
  if (!raw) return [{ id: 'us-sanjose-1', name: 'US West — San Jose', region: 'us-sanjose-1', provider: 'Oracle Cloud', status: 'setup-required' }];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.map(({ id, name, region, provider, status, endpoint }) => ({ id, name, region, provider, status, endpoint }));
  } catch {
    return [];
  }
}

export default function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({ nodes: safeNodes(process.env.VPN_NODES_JSON) });
}
