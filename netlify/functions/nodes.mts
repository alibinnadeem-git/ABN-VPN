import type { Config, Context } from "@netlify/functions";

type NodeRecord = {
  id?: string;
  name?: string;
  region?: string;
  provider?: string;
  status?: string;
  endpoint?: string;
};

function safeNodes(raw?: string): NodeRecord[] {
  if (!raw) {
    return [{
      id: "us-sanjose-1",
      name: "US West — San Jose",
      region: "us-sanjose-1",
      provider: "Oracle Cloud",
      status: "setup-required",
    }];
  }

  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.map(({ id, name, region, provider, status, endpoint }) => ({
      id, name, region, provider, status, endpoint,
    }));
  } catch {
    return [];
  }
}

export default async (_req: Request, _context: Context) => {
  const nodes = safeNodes(Netlify.env.get("VPN_NODES_JSON"));
  return Response.json({ nodes }, {
    headers: { "Cache-Control": "no-store" },
  });
};

export const config: Config = { path: "/api/nodes" };
