#!/usr/bin/env bash
# Lists everything in the account that bills by the hour. Exit code 0 means none found,
# 1 means something is running, 2 means a check could not be made.
set -uo pipefail

PROFILE="${AWS_PROFILE:-stk-platform}"
REGION="${AWS_REGION:-eu-west-2}"
aws_cli() { aws --profile "$PROFILE" --region "$REGION" --output text "$@"; }

found=0
failed=0

check() {
  local label="$1"; shift
  local out
  if ! out="$("$@" 2>&1)"; then
    echo "ERROR   $label: could not check ($out)" >&2
    failed=1
    return
  fi
  if [[ -n "$out" && "$out" != "None" ]]; then
    echo "RUNNING $label: $out"
    found=1
  else
    echo "ok      $label"
  fi
}

check "NAT gateways" aws_cli ec2 describe-nat-gateways \
  --filter "Name=state,Values=available,pending" --query "NatGateways[].NatGatewayId"
check "Elastic IPs" aws_cli ec2 describe-addresses --query "Addresses[].PublicIp"
check "Load balancers" aws_cli elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"
check "RDS databases" aws_cli rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"
check "EC2 instances" aws_cli ec2 describe-instances \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId"
check "ECS clusters" aws_cli ecs list-clusters --query "clusterArns[]"

if (( failed )); then exit 2; fi
if (( found )); then
  echo "Something that bills by the hour is still running."
  exit 1
fi
echo "Nothing that bills by the hour is running."
