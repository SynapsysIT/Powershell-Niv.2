function New-CustomPassword
{
    <#
    .SYNOPSIS
        Génère un mot de passe aléatoire conforme à la politique Entra ID.
    .PARAMETER Length
        Longueur du mot de passe (12 à 64 caractères, 16 par défaut).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateRange(12, 64)]
        [int]$Length = 16
    )

    # Suffixe fixe pour garantir majuscule, minuscule, chiffre et caractère spécial
    (-join ((33..126) | Get-Random -Count ($Length - 4) | ForEach-Object -Process { [char]$_ })) + 'Aa1!'
}
