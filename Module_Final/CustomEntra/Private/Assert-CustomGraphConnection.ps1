function Assert-CustomGraphConnection
{
    <#
    .SYNOPSIS
        Vérifie qu'une session Microsoft Graph est ouverte avec les permissions nécessaires.
    .PARAMETER RequiredScope
        Permissions requises. Chaque entrée peut lister des alternatives séparées par "|"
        (ex: 'User.Read.All|User.ReadWrite.All' : l'une ou l'autre suffit).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$RequiredScope
    )

    $Context = Get-MgContext
    if (-not $Context)
    {
        throw "Aucune session Microsoft Graph. Exécutez Connect-MgGraph avant d'utiliser ce module."
    }

    $Missing = foreach ($Scope in $RequiredScope)
    {
        $Alternatives = $Scope -split '\|'
        if (-not ($Alternatives | Where-Object -FilterScript { $_ -in $Context.Scopes }))
        {
            $Alternatives[0]
        }
    }

    if ($Missing)
    {
        throw "Permission(s) Microsoft Graph manquante(s) : $($Missing -join ', ')"
    }

    Write-Verbose "Session Graph OK ($($Context.AuthType)) - Tenant $($Context.TenantId)"
}
