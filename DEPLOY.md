# Running and publishing SeeYourTravel

## Local
```
cp web/Web.config.example web/Web.config   # set the DB password
make up                                    # http://localhost:8088 (only reachable from this machine)
```
Without `GoogleClientId` in `web/Web.config`, local visitors are signed in automatically as the owner. This mode is
**never** used for requests that arrive through a proxy/tunnel (they are guests), so the site can't be opened up by accident.

## Public HTTPS via Cloudflare Tunnel
Cloudflare terminates HTTPS; `cloudflared` reaches the app over the private docker network, so no port is opened.

1. Cloudflare Zero Trust -> Networks -> Tunnels -> your tunnel -> **Public hostname**:
   `seeyourtravel.app` -> Service type **HTTP** -> URL `syt-web:8080`.
2. Copy the tunnel token into `.env` (see `.env.example`): `CF_TUNNEL_TOKEN=...`
3. `make up` (starts the tunnel too), `make tunnel-logs` to check. Containers restart automatically after a reboot.
4. In Cloudflare: SSL/TLS mode **Full**, enable **Always Use HTTPS**.
5. Google Cloud Console -> OAuth client: add `https://seeyourtravel.app` to *Authorized JavaScript origins*.
6. In `web/Web.config` set `GoogleClientId` (admins: `GoogleAdmins`).

The app adds `Strict-Transport-Security` and secure cookies when it sees HTTPS (`X-Forwarded-Proto` / `CF-Visitor`).
