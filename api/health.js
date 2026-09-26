export default function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({
    ok: true,
    service: 'ABN VPN Control Plane',
    deployment: 'vercel',
    dataPlane: 'wireguard',
    timestamp: new Date().toISOString()
  });
}
