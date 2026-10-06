function New-CustomEntraUser
{
    <#
    .SYNOPSIS
        Crée des utilisateurs Entra ID à partir d'objets reçus par le pipeline.
    .DESCRIPTION
        Chaque propriété de l'objet reçu alimente le paramètre du même nom
        (ValueFromPipelineByPropertyName). Un mot de passe aléatoire est généré
        et son changement est imposé à la première connexion.
    .PARAMETER DisplayName
        Nom affiché de l'utilisateur.
    .PARAMETER UserPrincipalName
        UPN de l'utilisateur (prenom.nom@domaine).
    .PARAMETER MailNickname
        Alias de messagerie (partie gauche de l'UPN).
    .EXAMPLE
        Get-RandomUser -Count 5 -Domain 'contoso.onmicrosoft.com' | New-CustomEntraUser -WhatIf
    .EXAMPLE
        $CreatedUsers = Import-Csv -Path .\users.csv | New-CustomEntraUser
    .OUTPUTS
        System.Management.Automation.PSCustomObject (Id, DisplayName, UserPrincipalName)
    .NOTES
        Permission Microsoft Graph : User.ReadWrite.All
    #>
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

    begin
    {
        Assert-CustomGraphConnection -RequiredScope 'User.ReadWrite.All|Directory.ReadWrite.All'
    }

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
            Password                      = New-CustomPassword
            ForceChangePasswordNextSignIn = $true
        }

        if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Create Entra ID user'))
        {
            New-MgUser @Params | Select-Object -Property Id, DisplayName, UserPrincipalName
        }
    }
}
