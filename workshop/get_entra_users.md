---
icon: beaker
order: 10
title: Get Users
---

# Atelier : rapport d'activité des utilisateurs Entra ID

**Objectif** : coder une fonction `Get-CustomEntraUserReport` qui produit un rapport sur les utilisateurs du tenant, avec leur **dernière activité de connexion**, sous forme de `[PSCustomObject]`.

```powershell
Get-CustomEntraUserReport -InactiveDays 90 | Format-Table
```

!!!
Les utilisateurs créés dans l'atelier [Create Users](new_entra_users.md) ne se sont jamais connectés : ils doivent apparaître avec le statut `Never`.
!!!

## Consignes

Coder une fonction `Get-CustomEntraUserReport` qui :

1. Récupère **tous les utilisateurs** du tenant, ou seulement ceux reçus par le pipeline via leur `UserPrincipalName`.
2. Renvoie **un `[PSCustomObject]` par utilisateur** contenant au minimum les propriétés du tableau ci-dessous.
3. Calcule un **statut** à partir de la dernière connexion et d'un seuil passé en paramètre (`-InactiveDays`, 90 jours par défaut) :
   - `Never` : l'utilisateur ne s'est jamais connecté ;
   - `Inactive` : dernière connexion plus ancienne que le seuil ;
   - `Active` : sinon.

### Propriétés attendues

{.compact}
Propriété de sortie | Source Graph | Remarque
--- | --- | ---
`DisplayName` | `DisplayName` |
`UserPrincipalName` | `UserPrincipalName` |
`UserType` | `UserType` | `Member` ou `Guest`
`Enabled` | `AccountEnabled` |
`Department` | `Department` |
`Created` | `CreatedDateTime` |
`LastPasswordChange` | `LastPasswordChangeDateTime` |
`LastSignIn` | `SignInActivity.LastSignInDateTime` | Dernière connexion **interactive**
`LastNonInteractive` | `SignInActivity.LastNonInteractiveSignInDateTime` | Connexions faites par une application au nom de l'utilisateur
`DaysSinceLastSignIn` | *calculé* | Nombre de jours depuis la connexion la plus récente (interactive ou non)
`Status` | *calculé* | `Active` / `Inactive` / `Never`
`Licenses` | `AssignedLicenses` + `Get-MgSubscribedSku` | Noms des licences, séparés par une virgule

!!! Coup de pouce
- `Get-MgUser` ne renvoie qu'un **jeu réduit de propriétés** par défaut : `SignInActivity`, `AssignedLicenses`, `Department`... doivent être demandées explicitement avec `-Property`.
- `AssignedLicenses` ne contient que des **SkuId** (GUID). `Get-MgSubscribedSku` donne la correspondance `SkuId` → `SkuPartNumber` (ex: `SPE_E5`). Chargez-la **une seule fois**, dans le bloc `begin`, dans une hashtable.
- `SignInActivity` vaut `$null` pour un utilisateur qui ne s'est jamais connecté : votre code doit le gérer.
!!!


## Bonus

- Exporter le rapport en CSV exploitable dans Excel (`Export-Csv -Delimiter ';' -Encoding UTF8`).
- Ajouter le **nombre de groupes** dont l'utilisateur est membre (`Get-MgUserMemberOf`).
- Enchaîner les trois ateliers :
  ```powershell
  Get-RandomUser -Count 5 -Domain 'SynapsysTest.onmicrosoft.com' | New-CustomEntraUser | Get-CustomEntraUserReport
  ```

==- Corrigé
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
===
