export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  const url = process.env.VPN_NODE_HEALTH_URL;
  const token = process.env.VPN_NODE_HEALTH_TOKEN;

  if (!url) {
    return res.status(200).json({ ok: false, configured: false, status: 'setup-required' });
  }

  try {
    const response = await fetch(url, {
      headers: token ? { Authorization: `Bearer ${token}` } : undefined,
      signal: AbortSignal.timeout(4000),
    });
    const body = await response.text();
    return res.status(200).json({
      ok: response.ok,
      configured: true,
      status: response.ok ? 'online' : 'degraded',
      upstreamStatus: response.status,
      detail: body.slice(0, 500),
    });
  } catch {
    return res.status(200).json({ ok: false, configured: true, status: 'offline' });
  }
}
