---
icon: file-directory
order: 30
title: Structurer un module
---

# Structurer un module

## L'arborescence standard

On sépare les fonctions **publiques** (exposées à l'utilisateur) des fonctions **privées** (helpers internes), à raison d'**un fichier par fonction** :

```
SynInventory\
├── SynInventory.psd1        # Manifeste : métadonnées, version, exports
├── SynInventory.psm1        # Loader : charge les fichiers .ps1
├── Public\
│   └── Get-SynComputerInfo.ps1
├── Private\
│   └── ConvertTo-GiB.ps1
└── Tests\                   # (Module 3 - Pester)
```

Un fichier par fonction :
{.list-icon}

- :icon-check-circle: des diffs Git lisibles ;
- :icon-check-circle: un fichier de test Pester par fonction ;
- :icon-check-circle: aucune fonction "perdue" au milieu d'un `.psm1` de 3000 lignes.

## Le fichier `.psm1` : le loader

Le `.psm1` ne contient plus de code métier : il se contente de *dot-sourcer* chaque fichier et d'exporter les fonctions publiques.

```powershell SynInventory.psm1
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
Cette convention impose que **le nom du fichier soit identique au nom de la fonction** (`Get-SynComputerInfo.ps1` → `function Get-SynComputerInfo`).
!!!

## Le fichier `.psd1` : le manifeste

On ne l'écrit jamais à la main : on le génère avec `New-ModuleManifest`.

```powershell
$manifest = @{
    Path              = '.\SynInventory\SynInventory.psd1'
    RootModule        = 'SynInventory.psm1'
    ModuleVersion     = '1.0.0'
    Author            = 'Julien'
    CompanyName       = 'Synapsys'
    Description       = "Inventaire matériel et système des machines Windows"
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-SynComputerInfo')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    Tags              = @('Inventory', 'CIM')
}
New-ModuleManifest @manifest
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
:   Les modules dont dépend le vôtre (ex: `@('ActiveDirectory')`). Ils sont chargés automatiquement à l'import.

`PowerShellVersion` / `CompatiblePSEditions`
:   La version minimale et les éditions supportées (`Desktop` = 5.1, `Core` = 7+).

!!!warning Performance
Ne laissez jamais `FunctionsToExport = '*'`. Avec une liste explicite, PowerShell sait quelles commandes le module fournit **sans avoir à le charger**, ce qui rend l'auto-loading beaucoup plus rapide.
!!!

### Valider et faire évoluer le manifeste

```powershell
# Vérifier que le manifeste est valide
Test-ModuleManifest .\SynInventory\SynInventory.psd1

# Monter la version sans régénérer le fichier
Update-ModuleManifest -Path .\SynInventory\SynInventory.psd1 -ModuleVersion '1.1.0' -ReleaseNotes 'Ajout de la propriété Uptime'
```

## Portée des fonctions privées

Une fonction privée n'est **pas visible** depuis la session, mais reste utilisable par les fonctions du module :

```powershell
Import-Module .\SynInventory -Force

Get-Command -Module SynInventory      # Get-SynComputerInfo uniquement
ConvertTo-GiB -Bytes 17179869184      # Erreur : commande introuvable

# Astuce de debug : exécuter du code DANS la portée du module
& (Get-Module SynInventory) { ConvertTo-GiB -Bytes 17179869184 }   # 16
```
