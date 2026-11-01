#!/usr/bin/env bash
# Gives the local Jenkins container a one-hour AWS credential from the stk-ci-pipeline role.
# Nothing permanent is stored: the credential expires on its own, and "clear" removes the file.
set -euo pipefail

PROFILE="${AWS_PROFILE_NAME:-stk-platform}"
REGION="eu-west-2"
ROLE_NAME="stk-ci-pipeline"
CONTAINER="stk-jenkins"
TARGET="/var/jenkins_home/aws-session.env"

if [[ "${1:-}" == "clear" ]]; then
  docker exec "$CONTAINER" rm -f "$TARGET"
  echo "Removed the session file from $CONTAINER"
  exit 0
fi

if ! account=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text 2>/dev/null); then
  echo "Not logged in. Run: aws sso login --profile $PROFILE" >&2
  exit 1
fi

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "Container $CONTAINER is not running." >&2
  exit 1
fi

read -r key secret token expires < <(
  aws sts assume-role \
    --role-arn "arn:aws:iam::${account}:role/${ROLE_NAME}" \
    --role-session-name "jenkins-$(date +%Y%m%d%H%M%S)" \
    --duration-seconds 3600 \
    --profile "$PROFILE" \
    --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken,Credentials.Expiration]" \
    --output text
)

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
chmod 600 "$tmp"
{
  echo "export AWS_ACCESS_KEY_ID=$key"
  echo "export AWS_SECRET_ACCESS_KEY=$secret"
  echo "export AWS_SESSION_TOKEN=$token"
  echo "export AWS_DEFAULT_REGION=$REGION"
  echo "export AWS_SESSION_EXPIRES=$expires"
} > "$tmp"

docker cp "$tmp" "$CONTAINER:$TARGET"
docker exec "$CONTAINER" chmod 600 "$TARGET"
echo "Session file written to $CONTAINER. It expires at $expires."
