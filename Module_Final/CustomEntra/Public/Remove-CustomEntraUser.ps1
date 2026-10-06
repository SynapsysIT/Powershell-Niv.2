function Remove-CustomEntraUser
{
    <#
    .SYNOPSIS
        Supprime des utilisateurs Entra ID (nettoyage des comptes de test).
    .DESCRIPTION
        Accepte en entrée la sortie de New-CustomEntraUser ou de Get-CustomEntraUserReport.
        Une confirmation est demandée pour chaque suppression, sauf avec -Confirm:$false.
    .PARAMETER UserPrincipalName
        UPN (ou Id) des utilisateurs à supprimer. Accepte l'entrée pipeline par nom de propriété.
    .EXAMPLE
        $CreatedUsers | Remove-CustomEntraUser -WhatIf
    .EXAMPLE
        $CreatedUsers | Remove-CustomEntraUser -Confirm:$false
    .NOTES
        Permission Microsoft Graph : User.ReadWrite.All
        Les utilisateurs supprimés restent restaurables 30 jours (Utilisateurs supprimés).
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string[]]$UserPrincipalName
    )

    begin
    {
        Assert-CustomGraphConnection -RequiredScope 'User.ReadWrite.All|Directory.ReadWrite.All'
    }

    process
    {
        foreach ($User in $UserPrincipalName)
        {
            if ($PSCmdlet.ShouldProcess($User, 'Remove Entra ID user'))
            {
                Remove-MgUser -UserId $User
                Write-Verbose "$User supprimé"
            }
        }
    }
}
