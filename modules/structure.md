---
icon: file-directory
order: 30
title: Structurer un module
---

# Structurer un module

!!!
Les exemples de cette page s'appuient sur le module `CustomEntra`, que vous construirez dans l'atelier [Module CustomEntra](module_entra.md) à partir des fonctions des ateliers *Create Users* et *Get Users*.
!!!

## L'arborescence standard

On sépare les fonctions **publiques** (exposées à l'utilisateur) des fonctions **privées** (helpers internes), à raison d'**un fichier par fonction** :

```
CustomEntra\
├── CustomEntra.psd1                        # Manifeste : métadonnées, version, exports
├── CustomEntra.psm1                        # Loader : charge les fichiers .ps1
├── Public\
│   ├── Get-CustomEntraUserReport.ps1
│   └── New-CustomEntraUser.ps1
├── Private\
│   └── Assert-CustomGraphConnection.ps1    # Helper : vérifie la session Graph
└── Tests\                                  # (Module 3 - Pester)
```

Un fichier par fonction :
{.list-icon}

- :icon-check-circle: des diffs Git lisibles ;
- :icon-check-circle: un fichier de test Pester par fonction ;
- :icon-check-circle: aucune fonction "perdue" au milieu d'un `.psm1` de 3000 lignes.

## Le fichier `.psm1` : le loader

Le `.psm1` ne contient plus de code métier : il se contente de *dot-sourcer* chaque fichier et d'exporter les fonctions publiques.

```powershell CustomEntra.psm1
# Chargement des fonctions privées puis publiques
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
$Public  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue)

foreach ($file in @($Private + $Public)) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Échec du chargement de $($file.FullName) : $_"
    }
}

# Seules les fonctions du dossier Public sont exposées
Export-ModuleMember -Function $Public.BaseName
```

!!!
`$PSScriptRoot` contient le dossier du fichier en cours d'exécution. Il rend le module indépendant de l'emplacement où il est installé.
!!!

!!!warning
Cette convention impose que **le nom du fichier soit identique au nom de la fonction** (`Get-CustomEntraUserReport.ps1` → `function Get-CustomEntraUserReport`).
!!!

## Le fichier `.psd1` : le manifeste

On ne l'écrit jamais à la main : on le génère avec `New-ModuleManifest`.

```powershell
$Manifest = @{
    Path              = '.\CustomEntra\CustomEntra.psd1'
    RootModule        = 'CustomEntra.psm1'
    ModuleVersion     = '1.0.0'
    Author            = 'Julien'
    CompanyName       = 'Synapsys'
    Description       = 'Gestion et reporting des utilisateurs Entra ID'
    PowerShellVersion = '5.1'
    RequiredModules   = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.Users', 'Microsoft.Graph.Identity.DirectoryManagement')
    FunctionsToExport = @('New-CustomEntraUser', 'Get-CustomEntraUserReport')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    Tags              = @('EntraID', 'Graph')
}
New-ModuleManifest @Manifest
```

Les clés à connaître :

`RootModule`
:   Le `.psm1` à charger.

`ModuleVersion`
:   La version du module, au format [SemVer](https://semver.org/lang/fr/) `Majeur.Mineur.Correctif`.

`GUID`
:   Identifiant unique généré automatiquement. **Ne jamais le modifier** après la première publication.

`FunctionsToExport`
:   La liste **explicite** des fonctions publiques.

`RequiredModules`
:   Les modules dont dépend le vôtre (ici les sous-modules Microsoft Graph utilisés par nos fonctions). Ils sont chargés automatiquement à l'import, et l'import échoue s'ils ne sont pas installés.

`PowerShellVersion` / `CompatiblePSEditions`
:   La version minimale et les éditions supportées (`Desktop` = 5.1, `Core` = 7+).

!!!warning Performance
Ne laissez jamais `FunctionsToExport = '*'`. Avec une liste explicite, PowerShell sait quelles commandes le module fournit **sans avoir à le charger**, ce qui rend l'auto-loading beaucoup plus rapide.
!!!

### Valider et faire évoluer le manifeste

```powershell
# Vérifier que le manifeste est valide
Test-ModuleManifest .\CustomEntra\CustomEntra.psd1

# Monter la version sans régénérer le fichier
Update-ModuleManifest -Path .\CustomEntra\CustomEntra.psd1 -ModuleVersion '1.1.0' -ReleaseNotes 'Ajout de Remove-CustomEntraUser'
```

## Portée des fonctions privées

Une fonction privée n'est **pas visible** depuis la session, mais reste utilisable par les fonctions du module :

```powershell
Import-Module .\CustomEntra -Force

Get-Command -Module CustomEntra                                  # Get-CustomEntraUserReport, New-CustomEntraUser
Assert-CustomGraphConnection -RequiredScope 'User.Read.All'      # Erreur : commande introuvable

# Astuce de debug : exécuter du code DANS la portée du module
& (Get-Module CustomEntra) { Assert-CustomGraphConnection -RequiredScope 'User.Read.All' -Verbose }
```
