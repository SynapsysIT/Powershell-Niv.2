# Créer ses modules

Une fonction bien construite n'a de valeur que si elle est **réutilisable** et **distribuable**. Copier-coller une fonction d'un script à l'autre, ou la charger avec un dot-sourcing `. .\MesFonctions.ps1`, pose vite problème :

- plusieurs versions de la même fonction circulent ;
- aucune gestion des dépendances ;
- tout est exposé, y compris les fonctions "internes" ;
- rien ne dit quelle version tourne sur quel serveur.

Le **module** répond à ces problèmes : c'est l'unité de packaging, de versioning et de distribution de PowerShell.

## Les types de modules

Script module (`.psm1`)
:   Un fichier de code PowerShell. **C'est le type que nous allons créer.**

Manifest module (`.psd1`)
:   Un fichier de métadonnées (version, auteur, dépendances, fonctions exportées...) qui décrit le module. Il pointe vers le `.psm1` via la clé `RootModule`.

Binary module (`.dll`)
:   Un module compilé en C#. Hors du périmètre de cette formation.

!!!
Un module "professionnel" est toujours composé **au minimum** d'un `.psm1` **et** d'un `.psd1`.
!!!

## Où PowerShell cherche-t-il les modules ?

Les chemins sont listés dans la variable d'environnement `PSModulePath` :

```powershell
$env:PSModulePath -split [IO.Path]::PathSeparator
```

| Scope | Windows PowerShell 5.1 | PowerShell 7 |
|---|---|---|
| Utilisateur | `$HOME\Documents\WindowsPowerShell\Modules` | `$HOME\Documents\PowerShell\Modules` |
| Machine | `$env:ProgramFiles\WindowsPowerShell\Modules` | `$env:ProgramFiles\PowerShell\Modules` |

Un module placé dans l'un de ces chemins, dans un dossier **portant le même nom que le module**, est :

- découvert par `Get-Module -ListAvailable` ;
- **chargé automatiquement** dès qu'on appelle une de ses fonctions (*module auto-loading*).

```
Modules\
└── SynInventory\          <-- nom du dossier = nom du module
    └── 1.0.0\             <-- (optionnel) un sous-dossier par version
        ├── SynInventory.psd1
        └── SynInventory.psm1
```

## Commandes essentielles

```powershell
Get-Module                                  # Modules chargés dans la session
Get-Module -ListAvailable                   # Modules disponibles sur la machine
Import-Module .\SynInventory -Force -Verbose # (Re)charger un module en développement
Remove-Module SynInventory                  # Décharger un module
Get-Command -Module SynInventory            # Commandes exportées par un module
```

!!!warning
Pendant le développement, pensez à `Import-Module -Force` après chaque modification : sans `-Force`, PowerShell conserve la version déjà chargée en mémoire.
!!!
