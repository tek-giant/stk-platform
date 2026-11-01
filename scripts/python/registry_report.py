#!/usr/bin/env python3
"""Reports every image in the given ECR repositories with its size and scan result.

Exit code 0: every image was scanned and has no critical or high findings.
Exit code 1: a problem was found (a finding, a missing or failed scan, a suspiciously small image).
Exit code 2: the report could not be made (credentials, missing repository, API error).
"""
import argparse
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError

MIN_PLAUSIBLE_BYTES = 1_000_000  # a real image is tens of megabytes; a failed push leaves ~1.5 KB


def inspect_repository(ecr, repository, min_bytes):
    problems = []
    images = []
    paginator = ecr.get_paginator("describe_images")
    for page in paginator.paginate(repositoryName=repository):
        images.extend(page["imageDetails"])

    for image in sorted(images, key=lambda i: i["imagePushedAt"]):
        tags = ",".join(image.get("imageTags", ["<untagged>"]))
        size = image.get("imageSizeInBytes", 0)
        digest = image["imageDigest"]
        note = ""

        if size < min_bytes:
            note = "SUSPICIOUS: too small to be a real image"
            problems.append(f"{repository}:{tags} is only {size} bytes")

        try:
            scan = ecr.describe_image_scan_findings(
                repositoryName=repository, imageId={"imageDigest": digest}
            )
            status = scan["imageScanStatus"]["status"]
            counts = scan.get("imageScanFindings", {}).get("findingSeverityCounts", {})
        except ClientError as error:
            code = error.response["Error"]["Code"]
            status = "NO_SCAN" if code == "ScanNotFoundException" else f"ERROR:{code}"
            counts = {}

        if status != "COMPLETE":
            problems.append(f"{repository}:{tags} has no completed scan ({status})")
        elif counts.get("CRITICAL", 0) or counts.get("HIGH", 0):
            problems.append(f"{repository}:{tags} has findings {counts}")

        print(f"{repository:16} {tags:24} {size:>12} bytes  scan={status:9} findings={counts or 'none'} {note}")

    if not images:
        print(f"{repository:16} (no images)")
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repositories", nargs="+", help="ECR repository names, e.g. stk/stock-api")
    parser.add_argument("--profile", default=None)
    parser.add_argument("--region", default="eu-west-2")
    parser.add_argument("--min-bytes", type=int, default=MIN_PLAUSIBLE_BYTES)
    args = parser.parse_args()

    try:
        session = boto3.Session(profile_name=args.profile, region_name=args.region)
        ecr = session.client("ecr")
        problems = []
        for repository in args.repositories:
            problems.extend(inspect_repository(ecr, repository, args.min_bytes))
    except (BotoCoreError, ClientError) as error:
        print(f"Could not make the report: {error}", file=sys.stderr)
        return 2

    if problems:
        print("\nProblems found:")
        for problem in problems:
            print(f"  - {problem}")
        return 1
    print("\nAll images are scanned and clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())