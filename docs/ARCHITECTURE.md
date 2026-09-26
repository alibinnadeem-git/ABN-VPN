# Architecture

```text
Clients (iOS/macOS/Windows/Linux)
        |
        | WireGuard UDP/51820
        v
Oracle Cloud Always Free VM
San Jose / us-sanjose-1
        |
        v
Internet

Management/UI path:
GitHub/package -> Netlify production -> static dashboard + serverless APIs
                  \-> Vercel-compatible secondary target
```

The Netlify production application is a control plane (with Vercel compatibility retained). It does not terminate the VPN tunnel. WireGuard requires persistent networking and therefore runs on the OCI VM.

## Phase 2

Add authenticated device enrollment, Supabase/Neon persistence, node health telemetry, automated peer provisioning, and multiple regions. Private keys must remain on the VPN node or device; the web control plane should never store client/server private keys in plaintext.
