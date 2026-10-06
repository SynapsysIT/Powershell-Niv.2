<#
    Démo de fin de formation : enchaînement des ateliers avec le module CustomEntra.
    Prérequis : modules Microsoft.Graph installés, App Registration avec les permissions
    User.ReadWrite.All, AuditLog.Read.All et LicenseAssignment.Read.All.
#>

$TenantId = '<tenant-id>'
$ClientId = '<client-id>'
$Domain   = 'SynapsysTest.onmicrosoft.com'

# 1. Connexion à Microsoft Graph
$Secret     = Read-Host -Prompt 'Client secret (Value)' -AsSecureString
$Credential = [pscredential]::new($ClientId, $Secret)
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential -NoWelcome

# 2. Chargement du module et de l'outil de génération d'identités (hors module)
Import-Module -Name "$PSScriptRoot\CustomEntra\CustomEntra.psd1" -Force
. "$PSScriptRoot\Get-RandomUser.ps1"

# 3. Test à blanc
Get-RandomUser -Count 5 -Domain $Domain | New-CustomEntraUser -WhatIf

# 4. Création, rapport, nettoyage
$CreatedUsers = Get-RandomUser -Count 5 -Domain $Domain | New-CustomEntraUser
$CreatedUsers | Get-CustomEntraUserReport | Format-Table -Property DisplayName, UserPrincipalName, Status, Licenses
$CreatedUsers | Remove-CustomEntraUser -Confirm:$false

Disconnect-MgGraph | Out-Null
