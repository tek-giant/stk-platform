#!/usr/bin/env bash
# Gives the local Jenkins container a 30 minute Vault token that can read one secret.
# The root token is read from a file outside the repository and never leaves this machine.
set -euo pipefail

CONTAINER="stk-jenkins"
VAULT_CONTAINER="stk-vault"
TARGET="/var/jenkins_home/vault-token.env"
INIT_FILE="${HOME}/.stk-vault-init.json"

if [[ "${1:-}" == "clear" ]]; then
  docker exec "$CONTAINER" rm -f "$TARGET"
  echo "Removed the Vault token file from $CONTAINER"
  exit 0
fi

for c in "$CONTAINER" "$VAULT_CONTAINER"; do
  docker inspect "$c" >/dev/null 2>&1 || { echo "Container $c is not running." >&2; exit 1; }
done

if docker exec "$VAULT_CONTAINER" vault status 2>/dev/null | grep -q "Sealed *true"; then
  echo "Vault is sealed. Unseal it first." >&2
  exit 1
fi

root="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['root_token'])" "$INIT_FILE")"
token="$(docker exec -e VAULT_TOKEN="$root" "$VAULT_CONTAINER" vault token create -policy=stk-jenkins -ttl=30m -format=json \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['auth']['client_token'])")"
unset root

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
chmod 600 "$tmp"
{
  echo "export VAULT_ADDR=http://host.docker.internal:8200"
  echo "export VAULT_TOKEN=$token"
} > "$tmp"
unset token

docker cp "$tmp" "$CONTAINER:$TARGET"
docker exec "$CONTAINER" chmod 600 "$TARGET"
echo "Vault token file written to $CONTAINER. It expires in 30 minutes."
