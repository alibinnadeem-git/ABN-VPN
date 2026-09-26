import type { Config, Context } from "@netlify/functions";

export default async (_req: Request, _context: Context) => {
  return Response.json({
    ok: true,
    service: "ABN VPN Control Plane",
    deployment: "netlify",
    dataPlane: "wireguard",
    timestamp: new Date().toISOString(),
  }, {
    headers: { "Cache-Control": "no-store" },
  });
};

export const config: Config = { path: "/api/health" };
