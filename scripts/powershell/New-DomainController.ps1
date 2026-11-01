param(
    [string]$DomainName = 'stk.local',
    [string]$NetbiosName = 'STK',
    [Parameter(Mandatory = $true)][string]$SafeModePassword
)
$ErrorActionPreference = 'Stop'
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
$secure = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
Install-ADDSForest -DomainName $DomainName -DomainNetbiosName $NetbiosName `
    -SafeModeAdministratorPassword $secure -InstallDns -Force -NoRebootOnCompletion:$false