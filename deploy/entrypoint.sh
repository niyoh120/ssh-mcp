#!/bin/sh
# Start script for the Coolify deployment of ssh-mcp.
#
# Why config and keys are copied instead of used in place:
# ssh-mcp refuses to load a config that is group/world readable (mode & 0o077
# must be zero) and refuses a config *directory* that is not 0700. Coolify's
# file storages are written with `tee` + `chmod +x`, i.e. 0755, so a config
# mounted straight onto ~/.config/ssh-mcp/config.toml fails that check and the
# server exits. Copying it to a path this user owns lets us set 0600 on a file
# we created, which no root or privileged helper is needed for.
#
# Runtime inputs (all optional to the image, required to work):
#   /mnt/ssh-mcp/config.toml      file storage -> host inventory + policy
#   /mnt/ssh-mcp/keys/<name>      file storage -> one per SSH private key
#   SSH_MCP_HTTP_TOKEN            env var      -> bearer token for the HTTP transport
set -eu

MNT=/mnt/ssh-mcp
CONF_DIR="$HOME/.config/ssh-mcp"
SSH_DIR="$HOME/.ssh"
ALLOWED_HOSTS="ssh-mcp.niyoh.top,127.0.0.1:3000,localhost:3000"

mkdir -p "$CONF_DIR" "$SSH_DIR"
chmod 700 "$CONF_DIR" "$SSH_DIR"

if [ ! -f "$MNT/config.toml" ]; then
	echo "ssh-mcp: no config at $MNT/config.toml — attach the config.toml file storage" >&2
	exit 2
fi
cp -f "$MNT/config.toml" "$CONF_DIR/config.toml"
chmod 600 "$CONF_DIR/config.toml"

# Every file under /mnt/ssh-mcp/keys becomes ~/.ssh/<name>, so the name you give
# the file storage is the name you put in keyRef. 0600 is for OpenSSH's benefit,
# not the library's: ssh2 reads a key at any mode.
if [ -d "$MNT/keys" ]; then
	for f in "$MNT"/keys/*; do
		[ -f "$f" ] || continue
		name=$(basename "$f")
		cp -f "$f" "$SSH_DIR/$name"
		chmod 600 "$SSH_DIR/$name"
		echo "ssh-mcp: installed key $name"
	done
fi

if [ -z "${SSH_MCP_HTTP_TOKEN:-}" ]; then
	echo "ssh-mcp: SSH_MCP_HTTP_TOKEN is not set — refusing to start an unauthenticated listener" >&2
	exit 2
fi

echo "ssh-mcp: starting HTTP transport on 0.0.0.0:3000"
exec node /app/node_modules/ssh-mcp/build/index.js \
	--transport=http \
	--httpHost=0.0.0.0 \
	--httpPort=3000 \
	--allowedHosts="$ALLOWED_HOSTS" \
	--bearerToken="$SSH_MCP_HTTP_TOKEN"
