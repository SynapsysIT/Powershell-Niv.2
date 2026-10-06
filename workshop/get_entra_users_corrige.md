# Corrigé : Get Users

Énoncé : [Get Users](get_entra_users.md)

```powershell
function Get-CustomEntraUserReport
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$UserPrincipalName,

        [ValidateRange(1, 365)]
        [int]$InactiveDays = 90
    )

    begin
    {
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
```

```txt
ﲵ Get-CustomEntraUserReport | Format-Table DisplayName, UserType, Enabled, LastSignIn, DaysSinceLastSignIn, Status, Licenses

DisplayName  UserType Enabled LastSignIn          DaysSinceLastSignIn Status   Licenses
-----------  -------- ------- ----------          ------------------- ------   --------
Julien Admin Member      True 05/10/2026 09:14:02                   0 Active   SPE_E5
Enola Meyer  Member      True                                         Never
Old Guest    Guest       True 19/03/2026 16:41:27                 200 Inactive
```

!!!
Grâce à `ValueFromPipelineByPropertyName` sur `UserPrincipalName`, la fonction accepte directement la sortie de `New-CustomEntraUser` : le bloc `process` s'exécute une fois par utilisateur reçu. Sans entrée pipeline, il s'exécute une seule fois et interroge tout le tenant.
!!!
