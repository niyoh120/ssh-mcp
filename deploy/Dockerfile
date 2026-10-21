# syntax=docker/dockerfile:1
#
# Thin deployment image over the official npm package `ssh-mcp`.
#
# The upstream repo publishes no container image, but its changesets flow
# ships an npm package per release whose tarball carries the compiled
# build/ tree, so the image installs the pinned version instead of
# compiling sources. Upgrading = bump SSH_MCP_VERSION (the GitHub
# workflow in this repo does that automatically on new releases).
#
# `--ignore-scripts` keeps the build toolchain-free: ssh2 falls back to
# its pure-JS crypto path, same as the upstream Dockerfile's builder.
# Nothing secret is baked in: config.toml and the SSH keys are attached
# at deploy time through Coolify file storages (see entrypoint.sh).
#
# The base digest is the multi-platform OCI index from the upstream
# Dockerfile (amd64 + arm64); dependabot refreshes it monthly.

ARG NODE_IMAGE=node:22-slim@sha256:43ac6c60b8f89723f746e8a92ce91abd5017e627ce1ddfe4238355d3a30b772c
FROM ${NODE_IMAGE}
WORKDIR /app

ARG SSH_MCP_VERSION=2.20.1

RUN groupadd -r -g 65532 appgroup && useradd -r -u 65532 -g appgroup appuser

RUN npm install --omit=dev --ignore-scripts --no-audit --no-fund "ssh-mcp@${SSH_MCP_VERSION}" \
 && npm cache clean --force

COPY deploy/entrypoint.sh /usr/local/bin/ssh-mcp-entrypoint

ENV HOME=/home/appuser
ENV NODE_ENV=production
ENV PATH="/app/node_modules/.bin:${PATH}"

# 0700 on the config dir: ssh-mcp refuses to load a config whose directory is
# group- or world-readable, so the directory it lands in must already be tight.
# /mnt/ssh-mcp is where Coolify's file storages are mounted; it stays world
# readable because bind-mounted files are, and we only ever read from it.
RUN mkdir -p /home/appuser/.config/ssh-mcp /home/appuser/.ssh /mnt/ssh-mcp/keys \
 && chmod 700 /home/appuser/.config /home/appuser/.config/ssh-mcp /home/appuser/.ssh \
 && chmod 755 /usr/local/bin/ssh-mcp-entrypoint \
 && chown -R appuser:appgroup /home/appuser /app

USER appuser
EXPOSE 3000

# /health is served before the bearer-auth and Host-guard paths, so a plain
# loopback probe is enough. Coolify's platform health check is disabled for
# this app (the image has no curl/wget); this one only drives `docker ps`.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["/usr/local/bin/ssh-mcp-entrypoint"]
