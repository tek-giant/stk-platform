<#
.SYNOPSIS
Creates an OU, security groups and users in the domain. Safe to run twice: existing objects are skipped.
Passwords are generated and written to -PasswordFile, never printed or stored in the repository.
#>
param(
    [string]$DomainDn = 'DC=stk,DC=local',
    [string]$OuName = 'StockPlatform',
    [string]$PasswordFile = 'C:\Windows\Temp\stk-user-passwords.csv'
)
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$ouDn = "OU=$OuName,$DomainDn"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDn'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $OuName -Path $DomainDn -ProtectedFromAccidentalDeletion $true
    Write-Output "Created OU $ouDn"
}

$groups = 'stk-admins', 'stk-developers', 'stk-readonly'
foreach ($group in $groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path $ouDn
        Write-Output "Created group $group"
    }
}

$users = @(
    @{ Name = 'alice.admin';  Group = 'stk-admins' },
    @{ Name = 'bob.dev';      Group = 'stk-developers' },
    @{ Name = 'carol.viewer'; Group = 'stk-readonly' }
)

function New-RandomPassword {
    $chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!#%*-_=+'.ToCharArray()
    -join (1..20 | ForEach-Object { $chars[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($chars.Length)] })
}

$issued = @()
foreach ($u in $users) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Name)'" -ErrorAction SilentlyContinue)) {
        $plain = New-RandomPassword
        New-ADUser -Name $u.Name -SamAccountName $u.Name -Path $ouDn -Enabled $true `
            -AccountPassword (ConvertTo-SecureString $plain -AsPlainText -Force)
        $issued += [pscustomobject]@{ User = $u.Name; Password = $plain }
        Write-Output "Created user $($u.Name)"
    }
    Add-ADGroupMember -Identity $u.Group -Members $u.Name
}

if ($issued.Count -gt 0) {
    $issued | Export-Csv -Path $PasswordFile -NoTypeInformation
    Write-Output "Passwords for new users written to $PasswordFile"
}
Write-Output "Done: $($users.Count) users, $($groups.Count) groups in $ouDn"
