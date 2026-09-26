import type { Config, Context } from "@netlify/functions";
import { getStore } from "@netlify/blobs";

const DEFAULT_NODE_ID = "us-sanjose-1";

export default async (req: Request, _context: Context) => {
  const requestUrl = new URL(req.url);
  const nodeId = (requestUrl.searchParams.get("node") || DEFAULT_NODE_ID).toLowerCase();
  if (!/^[a-z0-9._-]{1,64}$/.test(nodeId)) {
    return Response.json({ ok: false, configured: false, status: "invalid-node" }, { status: 400 });
  }

  const store = getStore({ name: "vpn-node-heartbeats", consistency: "strong" });
  const heartbeat = await store.get(nodeId, { type: "json" }) as any | null;

  if (heartbeat?.receivedAt) {
    const ageSeconds = Math.max(0, Math.round((Date.now() - new Date(heartbeat.receivedAt).getTime()) / 1000));
    const status = ageSeconds <= 180 ? "online" : ageSeconds <= 600 ? "degraded" : "offline";
    return Response.json({
      ok: status === "online",
      configured: true,
      status,
      nodeId,
      lastSeen: heartbeat.receivedAt,
      heartbeatAgeSeconds: ageSeconds,
      interface: heartbeat.interface,
      peerCount: heartbeat.peerCount,
      activePeerCount: heartbeat.activePeerCount,
      version: heartbeat.version,
      monitoring: "outbound-heartbeat",
    }, { status: 200, headers: { "Cache-Control": "no-store" } });
  }

  // Backwards-compatible fallback for an explicitly configured direct health URL.
  const url = Netlify.env.get("VPN_NODE_HEALTH_URL");
  const token = Netlify.env.get("VPN_NODE_HEALTH_TOKEN");
  if (url) {
    try {
      const response = await fetch(url, {
        headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        signal: AbortSignal.timeout(4000),
      });
      return Response.json({
        ok: response.ok,
        configured: true,
        status: response.ok ? "online" : "degraded",
        upstreamStatus: response.status,
        monitoring: "direct-health-url",
      }, { status: 200, headers: { "Cache-Control": "no-store" } });
    } catch {
      return Response.json({
        ok: false,
        configured: true,
        status: "offline",
        monitoring: "direct-health-url",
      }, { status: 200, headers: { "Cache-Control": "no-store" } });
    }
  }

  return Response.json({
    ok: false,
    configured: false,
    status: "setup-required",
    nodeId,
    monitoring: "outbound-heartbeat",
  }, { status: 200, headers: { "Cache-Control": "no-store" } });
};

export const config: Config = { path: "/api/node-health" };
