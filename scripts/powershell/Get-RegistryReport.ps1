<#
.SYNOPSIS
Reports every image in the given ECR repositories with its size and scan result.
Exit code 0: all images scanned, no critical or high findings.
Exit code 1: a problem was found (finding, missing scan, suspiciously small image).
Exit code 2: the report could not be made (credentials, missing repository, API error).
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string[]]$Repositories,
    [string]$Region = 'eu-west-2',
    [long]$MinBytes = 1000000
)

$Repositories = $Repositories | ForEach-Object { $_ -split ',' } | Where-Object { $_ }

$ErrorActionPreference = 'Stop'
$problems = New-Object System.Collections.Generic.List[string]

try {
    foreach ($repository in $Repositories) {
        $images = aws ecr describe-images --repository-name $repository --region $Region --output json
        if ($LASTEXITCODE -ne 0) { throw "describe-images failed for $repository" }
        $details = ($images | ConvertFrom-Json).imageDetails | Sort-Object imagePushedAt

        if (-not $details) { Write-Output ("{0,-16} (no images)" -f $repository); continue }

        foreach ($image in $details) {
            $tags = if ($image.imageTags) { $image.imageTags -join ',' } else { '<untagged>' }
            $size = [long]$image.imageSizeInBytes
            $note = ''
            if ($size -lt $MinBytes) {
                $note = 'SUSPICIOUS: too small to be a real image'
                $problems.Add("${repository}:${tags} is only $size bytes")
            }

            $scanJson = aws ecr describe-image-scan-findings --repository-name $repository --image-id "imageDigest=$($image.imageDigest)" --region $Region --output json 2>&1
            if ($LASTEXITCODE -ne 0) {
                $status = if ("$scanJson" -match 'ScanNotFoundException') { 'NO_SCAN' } else { 'ERROR' }
                $counts = $null
            } else {
                $scan = $scanJson | ConvertFrom-Json
                $status = $scan.imageScanStatus.status
                $counts = $scan.imageScanFindings.findingSeverityCounts
            }

            $critical = if ($counts -and $counts.CRITICAL) { [int]$counts.CRITICAL } else { 0 }
            $high = if ($counts -and $counts.HIGH) { [int]$counts.HIGH } else { 0 }
            if ($status -ne 'COMPLETE') {
                $problems.Add("${repository}:${tags} has no completed scan ($status)")
            } elseif ($critical -or $high) {
                $problems.Add("${repository}:${tags} has CRITICAL=$critical HIGH=$high")
            }

            Write-Output ("{0,-16} {1,-24} {2,12} bytes  scan={3,-9} critical={4} high={5} {6}" -f $repository, $tags, $size, $status, $critical, $high, $note)
        }
    }
} catch {
    [Console]::Error.WriteLine("Could not make the report: $($_.Exception.Message)")
    exit 2
}

if ($problems.Count -gt 0) {
    Write-Output "`nProblems found:"
    $problems | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "`nAll images are scanned and clean."
exit 0