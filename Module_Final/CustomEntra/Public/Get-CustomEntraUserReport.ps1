function Get-CustomEntraUserReport
{
    <#
    .SYNOPSIS
        Rapport d'activité de connexion des utilisateurs Entra ID.
    .DESCRIPTION
        Renvoie un objet par utilisateur avec sa dernière connexion (interactive et non
        interactive), un statut Active / Inactive / Never et ses licences.
        Sans entrée pipeline, tout le tenant est analysé.
    .PARAMETER UserPrincipalName
        UPN des utilisateurs à analyser. Accepte l'entrée pipeline par nom de propriété.
    .PARAMETER InactiveDays
        Nombre de jours sans connexion au-delà duquel un utilisateur est "Inactive" (90 par défaut).
    .EXAMPLE
        Get-CustomEntraUserReport -InactiveDays 60 | Where-Object -Property Status -NE 'Active'
    .EXAMPLE
        $CreatedUsers | Get-CustomEntraUserReport
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES
        Permissions Microsoft Graph : User.Read.All, AuditLog.Read.All, LicenseAssignment.Read.All
        SignInActivity nécessite une licence Entra ID P1.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$UserPrincipalName,

        [ValidateRange(1, 365)]
        [int]$InactiveDays = 90
    )

    begin
    {
        Assert-CustomGraphConnection -RequiredScope 'User.Read.All|User.ReadWrite.All|Directory.Read.All', 'AuditLog.Read.All', 'LicenseAssignment.Read.All|Organization.Read.All|Directory.Read.All'

        $Properties = 'Id', 'DisplayName', 'UserPrincipalName', 'UserType', 'AccountEnabled',
                      'Department', 'CreatedDateTime', 'LastPasswordChangeDateTime',
                      'AssignedLicenses', 'SignInActivity'

        # Table de correspondance SkuId -> nom de licence, chargée une seule fois
        $Skus = @{}
        Get-MgSubscribedSku -All | ForEach-Object -Process { $Skus[$_.SkuId] = $_.SkuPartNumber }

        $Now = Get-Date
    }

    process
    {
        if ($UserPrincipalName)
        {
            $Users = foreach ($Upn in $UserPrincipalName) { Get-MgUser -UserId $Upn -Property $Properties }
        }
        else
        {
            $Users = Get-MgUser -All -Property $Properties
        }

        foreach ($User in $Users)
        {
            Write-Verbose "Processing $($User.UserPrincipalName)"

            # Dernière activité = la plus récente des connexions interactives et non interactives
            $LastActivity = @(
                $User.SignInActivity.LastSignInDateTime
                $User.SignInActivity.LastNonInteractiveSignInDateTime
            ) | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1

            if (-not $LastActivity)
            {
                $DaysSinceLastSignIn = $null
                $Status              = 'Never'
            }
            else
            {
                $DaysSinceLastSignIn = ($Now - $LastActivity).Days
                $Status              = if ($DaysSinceLastSignIn -ge $InactiveDays) { 'Inactive' } else { 'Active' }
            }

            [PSCustomObject]@{
                DisplayName          = $User.DisplayName
                UserPrincipalName    = $User.UserPrincipalName
                UserType             = $User.UserType
                Enabled              = $User.AccountEnabled
                Department           = $User.Department
                Created              = $User.CreatedDateTime
                LastPasswordChange   = $User.LastPasswordChangeDateTime
                LastSignIn           = $User.SignInActivity.LastSignInDateTime
                LastNonInteractive   = $User.SignInActivity.LastNonInteractiveSignInDateTime
                DaysSinceLastSignIn  = $DaysSinceLastSignIn
                Status               = $Status
                Licenses             = ($User.AssignedLicenses | ForEach-Object -Process { $Skus[[string]$_.SkuId] }) -join ', '
            }
        }
    }
}
