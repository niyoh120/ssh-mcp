# ssh-mcp (image)

Automated container image for [tufantunc/ssh-mcp](https://github.com/tufantunc/ssh-mcp),
which publishes no image of its own. Built from the official npm package
(whose tarball carries the compiled `build/` tree) on a daily schedule and
published to:

```
ghcr.io/niyoh120/ssh-mcp:<version>   # pinned
ghcr.io/niyoh120/ssh-mcp:latest
```

Platforms: `linux/amd64`, `linux/arm64`.

## Automation

- **build workflow** (`.github/workflows/build.yml`): daily cron resolves the npm
  `latest` dist-tag, skips if that tag already exists on GHCR, otherwise builds
  and pushes both tags, then commits the bumped `SSH_MCP_VERSION` pin.
  Manual `workflow_dispatch` accepts a version input to force-build any release.
- **dependabot**: monthly digest refresh of the pinned `node:22-slim` base and
  monthly major-version bumps for the pinned Actions.

## Image layout

- runs as non-root `appuser` (65532), `HEALTHCHECK` on `/health`
- `deploy/entrypoint.sh` copies `/mnt/ssh-mcp/config.toml` and
  `/mnt/ssh-mcp/keys/*` into the app home with the strict 0600/0700 modes the
  server's config loader enforces, then starts the HTTP transport on :3000
- runtime inputs: `SSH_MCP_HTTP_TOKEN` env var (bearer auth), the config file
  storage, one file storage per SSH private key under `keys/`

## Production deployment

Coolify app `ssh-mcp` on eq12, domain `https://ssh-mcp.niyoh.top`. Upgrading
the deployment = `coolify app update <uuid> --docker-tag <ver>` + deploy
(manual on purpose).
