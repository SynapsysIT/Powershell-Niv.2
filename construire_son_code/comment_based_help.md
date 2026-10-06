# Intégrer une aide (Comment Based Help)

On peut intégrer une aide dans sa fonction ou son script via un bloc de commentaire dédié. Elle sera ensuite consultable avec `Get-Help`, exactement comme pour une commande native.

Le bloc d'aide se place :

- **au début du corps de la fonction** (juste après l'accolade ouvrante), comme dans l'exemple ci-dessous ;
- ou **juste avant le mot-clé `function`**, sans plus d'une ligne vide entre les deux ;
- ou **en tout début de script** pour l'aide d'un fichier `.ps1`.

## Les mots-clés principaux

{.compact}
Mot-clé | Contenu
--- | ---
`.SYNOPSIS` | Description courte, sur une ligne
`.DESCRIPTION` | Description détaillée
`.PARAMETER <Nom>` | Description d'un paramètre (un bloc par paramètre)
`.EXAMPLE` | Un exemple d'utilisation : la première ligne est la commande, la suite est le commentaire ou la sortie attendue (un bloc par exemple)
`.INPUTS` | Types acceptés en entrée par le pipeline
`.OUTPUTS` | Types renvoyés par la fonction
`.NOTES` | Informations complémentaires (version, auteur, prérequis...)
`.LINK` | Liens vers une documentation ou une commande liée (un bloc par lien)

## Exemple

+++ :icon-code: Code

```powershell
function Get-EntraAppSecretExpiry
{
<#
.SYNOPSIS
    Lists App Registration client secrets that expire soon.
.DESCRIPTION
    Queries Entra ID App Registrations through Microsoft Graph and returns
    every client secret expiring within the next X days (expired secrets included).
    Without -ApplicationId, all App Registrations of the tenant are checked.
.PARAMETER ApplicationId
    Object ID of one or more App Registrations (not the Application/Client ID).
    Accepts pipeline input by property name (Id), e.g. from Get-MgApplication.
.PARAMETER DaysBefore
    Number of days before expiration to report a secret. Default: 30.
.EXAMPLE
    Get-EntraAppSecretExpiry -DaysBefore 60

    Application                       AppId                                Secret    Expires             DaysLeft
    -----------                       -----                                ------    -------             --------
    Test-CMG-ClientApp-ManualCreation b310bed6-accf-4d76-a45c-2c72d40124a2 Formation 15/11/2026 09:12:45       39
    App-Portail-RH                    4f8a2d1c-6b3e-4c9a-a7d5-1e2f3b4c5d6e Prod      03/10/2026 17:30:00       -3
.EXAMPLE
    Get-MgApplication -Filter "startswith(displayName,'Test')" | Get-EntraAppSecretExpiry

    Checks only the App Registrations whose name starts with "Test".
.INPUTS
    System.String[]
    Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication (via the Id property)
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Version    : 1.0.0
    Updated On : 2026-10-06
    Requires   : Microsoft.Graph.Applications - Application.Read.All
.LINK
    https://learn.microsoft.com/graph/api/resources/passwordcredential
.LINK
    Get-MgApplication
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string[]]$ApplicationId,

        [ValidateRange(1, 365)]
        [int]$DaysBefore = 30
    )

    process
    {
        $Properties = 'Id', 'DisplayName', 'AppId', 'PasswordCredentials'

        if ($ApplicationId)
        {
            $Apps = foreach ($Id in $ApplicationId) { Get-MgApplication -ApplicationId $Id -Property $Properties }
        }
        else
        {
            $Apps = Get-MgApplication -All -Property $Properties
        }

        $Limit = (Get-Date).AddDays($DaysBefore)

        foreach ($App in $Apps)
        {
            foreach ($Secret in ($App.PasswordCredentials | Where-Object EndDateTime -lt $Limit))
            {
                [PSCustomObject]@{
                    Application = $App.DisplayName
                    AppId       = $App.AppId
                    Secret      = $Secret.DisplayName
                    Expires     = $Secret.EndDateTime
                    DaysLeft    = ($Secret.EndDateTime - (Get-Date)).Days
                }
            }
        }
    }
}
```

+++ :icon-note: Output Get-Help

```txt
ﲵ Get-Help Get-EntraAppSecretExpiry

NAME
    Get-EntraAppSecretExpiry

SYNOPSIS
    Lists App Registration client secrets that expire soon.

SYNTAX
    Get-EntraAppSecretExpiry [[-ApplicationId] <String[]>] [[-DaysBefore] <Int32>] [<CommonParameters>]

DESCRIPTION
    Queries Entra ID App Registrations through Microsoft Graph and returns
    every client secret expiring within the next X days (expired secrets included).
    Without -ApplicationId, all App Registrations of the tenant are checked.

RELATED LINKS
    https://learn.microsoft.com/graph/api/resources/passwordcredential
    Get-MgApplication

REMARKS
    To see the examples, type: "Get-Help Get-EntraAppSecretExpiry -Examples"
    For more information, type: "Get-Help Get-EntraAppSecretExpiry -Detailed"
    For technical information, type: "Get-Help Get-EntraAppSecretExpiry -Full"
    For online help, type: "Get-Help Get-EntraAppSecretExpiry -Online"
```

+++ :icon-note: Output Get-Help -Full

```txt
ﲵ Get-Help Get-EntraAppSecretExpiry -Full

NAME
    Get-EntraAppSecretExpiry

SYNOPSIS
    Lists App Registration client secrets that expire soon.

SYNTAX
    Get-EntraAppSecretExpiry [[-ApplicationId] <String[]>] [[-DaysBefore] <Int32>] [<CommonParameters>]

DESCRIPTION
    Queries Entra ID App Registrations through Microsoft Graph and returns
    every client secret expiring within the next X days (expired secrets included).
    Without -ApplicationId, all App Registrations of the tenant are checked.

PARAMETERS
    -ApplicationId <String[]>
        Object ID of one or more App Registrations (not the Application/Client ID).
        Accepts pipeline input by property name (Id), e.g. from Get-MgApplication.

        Required?                    false
        Position?                    1
        Default value
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false

    -DaysBefore <Int32>
        Number of days before expiration to report a secret. Default: 30.

        Required?                    false
        Position?                    2
        Default value                30
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

INPUTS
    System.String[]
    Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication (via the Id property)

OUTPUTS
    System.Management.Automation.PSCustomObject

NOTES

        Version    : 1.0.0
        Updated On : 2026-10-06
        Requires   : Microsoft.Graph.Applications - Application.Read.All

    -------------------------- EXAMPLE 1 --------------------------

    PS > Get-EntraAppSecretExpiry -DaysBefore 60

    Application                       AppId                                Secret    Expires             DaysLeft
    -----------                       -----                                ------    -------             --------
    Test-CMG-ClientApp-ManualCreation b310bed6-accf-4d76-a45c-2c72d40124a2 Formation 15/11/2026 09:12:45       39
    App-Portail-RH                    4f8a2d1c-6b3e-4c9a-a7d5-1e2f3b4c5d6e Prod      03/10/2026 17:30:00       -3

    -------------------------- EXAMPLE 2 --------------------------

    PS > Get-MgApplication -Filter "startswith(displayName,'Test')" | Get-EntraAppSecretExpiry

    Checks only the App Registrations whose name starts with "Test".

RELATED LINKS
    https://learn.microsoft.com/graph/api/resources/passwordcredential
    Get-MgApplication
```

+++ :icon-note: Output Get-Help -Parameter

```txt
ﲵ Get-Help Get-EntraAppSecretExpiry -Parameter ApplicationId

-ApplicationId <String[]>
    Object ID of one or more App Registrations (not the Application/Client ID).
    Accepts pipeline input by property name (Id), e.g. from Get-MgApplication.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true (ByPropertyName)
    Accept wildcard characters?  false
```

+++

!!!
`Get-Help -Online` ouvre le **premier** `.LINK`, à condition que ce soit une URL. Les `.LINK` suivants peuvent référencer d'autres commandes par leur nom.
!!!

!!!warning
Un mot-clé mal orthographié (`.PARAMETRE`, `.EXEMPLE`...) rend **tout le bloc d'aide invalide** : `Get-Help` affiche alors uniquement la syntaxe, sans aucun message d'erreur.
!!!

#### Voir plus sur learn.microsoft.com

[!badge target="blank" text="about_Comment_Based_Help"](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
