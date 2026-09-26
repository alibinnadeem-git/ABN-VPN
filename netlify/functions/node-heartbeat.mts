import type { Config, Context } from "@netlify/functions";
import { getStore } from "@netlify/blobs";
import { timingSafeEqual } from "node:crypto";

function authorized(req: Request, expected?: string) {
  if (!expected) return false;
  const auth = req.headers.get("authorization") || "";
  const provided = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  const a = Buffer.from(provided);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

function safeNodeId(value: unknown) {
  const id = String(value || "").trim().toLowerCase();
  return /^[a-z0-9._-]{1,64}$/.test(id) ? id : null;
}

export default async (req: Request, _context: Context) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: { Allow: "POST" } });
  }

  const token = Netlify.env.get("VPN_NODE_HEARTBEAT_TOKEN");
  if (!authorized(req, token)) {
    return Response.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ ok: false, error: "invalid-json" }, { status: 400 });
  }

  const nodeId = safeNodeId(body?.nodeId);
  if (!nodeId) {
    return Response.json({ ok: false, error: "invalid-node-id" }, { status: 400 });
  }

  const peerCount = Math.max(0, Math.min(100000, Number(body?.peerCount) || 0));
  const activePeerCount = Math.max(0, Math.min(peerCount, Number(body?.activePeerCount) || 0));
  const iface = String(body?.interface || "wg0").slice(0, 32);
  const version = String(body?.version || "unknown").slice(0, 64);
  const receivedAt = new Date().toISOString();

  const record = {
    nodeId,
    receivedAt,
    interface: iface,
    peerCount,
    activePeerCount,
    version,
  };

  const store = getStore({ name: "vpn-node-heartbeats", consistency: "strong" });
  await store.setJSON(nodeId, record);

  return Response.json({ ok: true, nodeId, receivedAt }, {
    headers: { "Cache-Control": "no-store" },
  });
};

export const config: Config = { path: "/api/node-heartbeat" };
