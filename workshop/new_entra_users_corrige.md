# Corrigé : Create Users

Énoncé : [Create Users](new_entra_users.md)

```powershell
function New-CustomEntraUser
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$DisplayName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$MailNickname,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$GivenName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Surname,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateLength(2, 2)]
        [string]$UsageLocation = 'FR',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$StreetAddress,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$PostalCode,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$City,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Country,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$MobilePhone
    )

    process
    {
        $Params = @{
            DisplayName       = $DisplayName
            UserPrincipalName = $UserPrincipalName
            MailNickname      = $MailNickname
            GivenName         = $GivenName
            Surname           = $Surname
            UsageLocation     = $UsageLocation
            StreetAddress     = $StreetAddress
            PostalCode        = $PostalCode
            City              = $City
            Country           = $Country
            MobilePhone       = $MobilePhone
        }

        # Retire les propriétés non renseignées : New-MgUser refuse les chaînes vides
        foreach ($Key in @($Params.Keys))
        {
            if (-not $Params[$Key]) { $Params.Remove($Key) }
        }

        $Params['AccountEnabled']  = $true
        $Params['PasswordProfile'] = @{
            Password                      = (-join ((33..126) | Get-Random -Count 16 | ForEach-Object { [char]$_ })) + 'Aa1!'
            ForceChangePasswordNextSignIn = $true
        }

        if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Create Entra ID user'))
        {
            New-MgUser @Params | Select-Object -Property Id, DisplayName, UserPrincipalName
        }
    }
}
```

!!!
`$PSCmdlet.ShouldProcess()` renvoie `$false` quand `-WhatIf` est utilisé : la création est simplement affichée, sans être exécutée.
!!!

### Utilisation

```powershell
# Test à blanc
Get-RandomUser -Count 10 -Domain 'SynapsysTest.onmicrosoft.com' | New-CustomEntraUser -WhatIf

# Création réelle, en conservant le résultat pour le nettoyage
$CreatedUsers = Get-RandomUser -Count 10 -Domain 'SynapsysTest.onmicrosoft.com' | New-CustomEntraUser

# Nettoyage en fin d'atelier
$CreatedUsers | ForEach-Object -Process { Remove-MgUser -UserId $_.Id }
```

```txt
What if: Performing the operation "Create Entra ID user" on target "enola.meyer@SynapsysTest.onmicrosoft.com".
What if: Performing the operation "Create Entra ID user" on target "jerome.legall-dupre@SynapsysTest.onmicrosoft.com".
...
```
