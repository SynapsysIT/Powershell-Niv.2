---
icon: beaker
order: 12
title: API Random User
---

# Atelier : consommer une API REST

**Objectif** : récupérer des identités fictives depuis une API REST publique et les transformer en objets PowerShell prêts à être envoyés dans le pipeline.

!!!
Les objets produits ici serviront d'entrée à l'atelier suivant, [Create Users](new_entra_users.md), qui créera ces utilisateurs dans Entra ID.
!!!

L'API utilisée : [https://randomuser.me/api/?results=10&nat=FR](https://randomuser.me/api/?results=10&nat=FR)

## Consignes

Coder une fonction `Get-RandomUser` qui :

1. Interroge l'API pour récupérer un nombre d'utilisateurs français passé en paramètre (`-Count`, 10 par défaut).
2. Renvoie **un `[PSCustomObject]` par utilisateur**, dont les noms de propriétés correspondent **exactement** à ceux du tableau ci-dessous (ce sont les noms des paramètres de `New-MgUser`).
3. Construit l'UPN à partir du prénom, du nom et d'un domaine passé en paramètre (`-Domain`).

!!! Coup de pouce
L'appel à l'API se fait avec [!badge target="blank" text="Invoke-RestMethod"](https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/invoke-restmethod). Contrairement à `Invoke-WebRequest`, il **convertit automatiquement** la réponse JSON en objets PowerShell : pas besoin de `ConvertFrom-Json`.

Les utilisateurs se trouvent dans la propriété `results` de la réponse. Pour explorer la structure d'un utilisateur :

```powershell
$Response = Invoke-RestMethod -Uri 'https://randomuser.me/api/?results=1&nat=FR'
$Response.results[0] | ConvertTo-Json -Depth 5
```
!!!

### Propriétés attendues

{.compact}
Propriété de sortie | Source dans le JSON | Remarque
--- | --- | ---
`DisplayName` | `name.first` + `name.last` | « Prénom Nom »
`GivenName` | `name.first` |
`Surname` | `name.last` |
`MailNickname` | `name.first` + `name.last` | `prenom.nom`, en minuscules, **sans accent, espace ni apostrophe**
`UserPrincipalName` | `MailNickname` + `-Domain` | `prenom.nom@domaine`
`UsageLocation` | `nat` | Code pays sur 2 lettres (`FR`)
`StreetAddress` | `location.street.number` + `location.street.name` |
`PostalCode` | `location.postcode` | À convertir en `[string]`
`City` | `location.city` |
`Country` | `location.country` |
`MobilePhone` | `cell` |

!!!warning
Un UPN ne peut contenir ni accent, ni espace, ni apostrophe : `Jérôme Le Gall` doit donner `jerome.legall`. Cherchez du côté de la méthode `.Normalize()` des chaînes et de la classe RegEx `\p{Mn}`.
!!!

## Bonus

- Formater le numéro de mobile au format international : `06-69-61-79-12` → `+33 6 69 61 79 12`.
- Ajouter un paramètre `-Nationality` (avec `ValidateSet`) pour interroger d'autres nationalités que `FR`.

==- Corrigé
```powershell
function Get-RandomUser
{
    [CmdletBinding()]
    param (
        [ValidateRange(1, 100)]
        [int]$Count = 10,

        [Parameter(Mandatory)]
        [string]$Domain
    )

    $Response = Invoke-RestMethod -Uri "https://randomuser.me/api/?results=$Count&nat=FR" -Method Get

    foreach ($User in $Response.results)
    {
        # Les UPN n'acceptent ni accents, ni espaces, ni apostrophes
        $Nickname = "$($User.name.first).$($User.name.last)".Normalize([Text.NormalizationForm]::FormD)
        $Nickname = ($Nickname -replace '\p{Mn}', '' -replace "[^a-zA-Z0-9.\-]", '').ToLower()

        [PSCustomObject]@{
            DisplayName       = "$($User.name.first) $($User.name.last)"
            GivenName         = $User.name.first
            Surname           = $User.name.last
            MailNickname      = $Nickname
            UserPrincipalName = "$Nickname@$Domain"
            UsageLocation     = $User.nat
            StreetAddress     = "$($User.location.street.number) $($User.location.street.name)"
            PostalCode        = [string]$User.location.postcode
            City              = $User.location.city
            Country           = $User.location.country
            MobilePhone       = $User.cell
        }
    }
}
```

```txt
ﲵ Get-RandomUser -Count 2 -Domain 'SynapsysTest.onmicrosoft.com'

DisplayName       : Enola Meyer
GivenName         : Enola
Surname           : Meyer
MailNickname      : enola.meyer
UserPrincipalName : enola.meyer@SynapsysTest.onmicrosoft.com
UsageLocation     : FR
StreetAddress     : 8342 Avenue Jean-Jaurès
PostalCode        : 18137
City              : Montpellier
Country           : France
MobilePhone       : 06-69-61-79-12

DisplayName       : Jérôme Le Gall-Dupré
GivenName         : Jérôme
Surname           : Le Gall-Dupré
MailNickname      : jerome.legall-dupre
UserPrincipalName : jerome.legall-dupre@SynapsysTest.onmicrosoft.com
UsageLocation     : FR
StreetAddress     : 12 Rue de l'Église
PostalCode        : 42000
City              : Saint-Étienne
Country           : France
MobilePhone       : 07-12-34-56-78
```
===
