# Atelier : regrouper ses fonctions dans un module

**Objectif** : regrouper les fonctions des ateliers [Create Users](../workshop/new_entra_users.md) et [Get Users](../workshop/get_entra_users.md) dans un module `CustomEntra` versionné, doté d'une fonction **privée** partagée, puis le publier dans un dépôt interne.

!!!
`Get-RandomUser` (atelier [API Random User](../workshop/random_users.md)) **ne fait pas partie du module** : c'est un outil de labo qui génère des données de test, pas une fonction destinée à la production.
!!!

## Étape 1 - Structure

1. Créer l'arborescence d'un module `CustomEntra` avec les dossiers `Public` et `Private`.
2. Placer chaque fonction publique dans son propre fichier :
   - `Public\New-CustomEntraUser.ps1`
   - `Public\Get-CustomEntraUserReport.ps1`
3. Écrire le loader `CustomEntra.psm1`.

## Étape 2 - La fonction privée

Les deux fonctions publiques ont le même prérequis : une session Microsoft Graph ouverte, avec les bonnes permissions. Sans elle, l'utilisateur obtient une erreur Graph peu lisible... **au milieu du traitement**.

Coder une fonction **privée** `Assert-CustomGraphConnection` dans `Private\Assert-CustomGraphConnection.ps1` qui :

1. Reçoit la liste des permissions nécessaires (`-RequiredScope`).
2. Lève une erreur explicite (`throw`) si **aucune session Graph** n'est ouverte.
3. Lève une erreur explicite listant les **permissions manquantes**.
4. Accepte des **alternatives** pour une même permission : `'User.Read.All|User.ReadWrite.All'` signifie que l'une ou l'autre suffit.

Appeler ensuite cette fonction dans le bloc `begin` des deux fonctions publiques :

{.compact}
Fonction | Permissions requises
--- | ---
`New-CustomEntraUser` | `User.ReadWrite.All`
`Get-CustomEntraUserReport` | `User.Read.All`, `AuditLog.Read.All`, `LicenseAssignment.Read.All`

!!! Coup de pouce
`Get-MgContext` renvoie la session Graph en cours (ou `$null` si aucune session n'est ouverte). Sa propriété `Scopes` contient la liste des permissions du jeton.
!!!

## Étape 3 - Manifeste

1. Générer `CustomEntra.psd1` avec `New-ModuleManifest` en version `1.0.0`.
2. Déclarer les modules Graph nécessaires dans `RequiredModules` : `Microsoft.Graph.Authentication`, `Microsoft.Graph.Users` et `Microsoft.Graph.Identity.DirectoryManagement` (pour `Get-MgSubscribedSku`).
3. Vérifier le manifeste avec `Test-ModuleManifest`.
4. Importer le module et valider que :
   - seules `New-CustomEntraUser` et `Get-CustomEntraUserReport` sont visibles ;
   - `Assert-CustomGraphConnection` n'est **pas** accessible depuis la session ;
   - sans `Connect-MgGraph`, `Get-CustomEntraUserReport` renvoie votre message d'erreur explicite.

## Étape 4 - Publication

1. Créer un dossier `C:\PSRepo` et l'enregistrer comme dépôt `LocalRepo`.
2. Publier `CustomEntra` en `1.0.0`.
3. Installer le module depuis le dépôt, ouvrir une **nouvelle** console et enchaîner les ateliers **sans** `Import-Module` :

```powershell
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential -NoWelcome
Get-RandomUser -Count 5 -Domain 'SynapsysTest.onmicrosoft.com' | New-CustomEntraUser | Get-CustomEntraUserReport
```

## Étape 5 - Nouvelle version

1. Extraire la génération du mot de passe de `New-CustomEntraUser` dans une seconde fonction **privée** `New-CustomPassword` (paramètre `-Length`, 16 par défaut).
2. Déterminer le bon numéro de version selon SemVer et mettre à jour le manifeste.
3. Publier, puis mettre à jour le module installé.
4. Vérifier que les **deux** versions sont présentes dans le dépôt.

!!!warning Contraintes
- Un fichier par fonction, nommé comme la fonction.
- `FunctionsToExport` doit être explicite.
- Aucune valeur en dur liée à votre tenant (domaine, Tenant ID, secret...) dans le module.
!!!

==- Corrigé
### Arborescence

```
CustomEntra\
├── CustomEntra.psd1
├── CustomEntra.psm1
├── Public\
│   ├── Get-CustomEntraUserReport.ps1
│   └── New-CustomEntraUser.ps1
└── Private\
    └── Assert-CustomGraphConnection.ps1
```

### Private\Assert-CustomGraphConnection.ps1

```powershell
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
        if (-not ($Alternatives | Where-Object { $_ -in $Context.Scopes }))
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
```

### Appel dans les fonctions publiques

```powershell Public\New-CustomEntraUser.ps1
    begin
    {
        Assert-CustomGraphConnection -RequiredScope 'User.ReadWrite.All|Directory.ReadWrite.All'
    }
```

```powershell Public\Get-CustomEntraUserReport.ps1
    begin
    {
        Assert-CustomGraphConnection -RequiredScope 'User.Read.All|User.ReadWrite.All|Directory.Read.All', 'AuditLog.Read.All', 'LicenseAssignment.Read.All|Organization.Read.All|Directory.Read.All'

        $Properties = ...   # suite du bloc begin inchangée
    }
```

!!!
Les alternatives acceptent aussi les permissions **plus larges** (`User.ReadWrite.All`, `Directory.Read.All`...) : un tenant de formation dispose souvent de droits plus élevés que le strict minimum.
!!!

### CustomEntra.psm1

```powershell
# Chargement des fonctions privées puis publiques
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
$Public  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue)

foreach ($File in @($Private + $Public))
{
    try
    {
        . $File.FullName
    }
    catch
    {
        Write-Error "Échec du chargement de $($File.FullName) : $_"
    }
}

# Seules les fonctions du dossier Public sont exposées
Export-ModuleMember -Function $Public.BaseName
```

### Manifeste et validation

```powershell
$Manifest = @{
    Path              = '.\CustomEntra\CustomEntra.psd1'
    RootModule        = 'CustomEntra.psm1'
    ModuleVersion     = '1.0.0'
    Author            = 'Stagiaire'
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
Test-ModuleManifest .\CustomEntra\CustomEntra.psd1

Import-Module .\CustomEntra -Force
Get-Command -Module CustomEntra                                  # Get-CustomEntraUserReport, New-CustomEntraUser
Get-Command Assert-CustomGraphConnection -ErrorAction Ignore     # Rien
```

```txt
ﲵ Get-CustomEntraUserReport   # sans Connect-MgGraph
Exception: Aucune session Microsoft Graph. Exécutez Connect-MgGraph avant d'utiliser ce module.

ﲵ Get-CustomEntraUserReport   # connecté avec User.ReadWrite.All uniquement
Exception: Permission(s) Microsoft Graph manquante(s) : AuditLog.Read.All, LicenseAssignment.Read.All
```

### Publication

```powershell
New-Item -ItemType Directory -Path C:\PSRepo -Force
Register-PSResourceRepository -Name LocalRepo -Uri C:\PSRepo -Trusted

Publish-PSResource -Path .\CustomEntra -Repository LocalRepo
Install-PSResource -Name CustomEntra -Repository LocalRepo -Scope CurrentUser
```

### Version 1.0.1

Extraction d'une fonction **privée** : aucun changement visible pour l'utilisateur du module → **version correctif**.

```powershell Private\New-CustomPassword.ps1
function New-CustomPassword
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateRange(12, 64)]
        [int]$Length = 16
    )

    # Suffixe fixe pour garantir majuscule, minuscule, chiffre et caractère spécial
    (-join ((33..126) | Get-Random -Count ($Length - 4) | ForEach-Object -Process { [char]$_ })) + 'Aa1!'
}
```

```powershell Dans New-CustomEntraUser
$Params['PasswordProfile'] = @{
    Password                      = New-CustomPassword
    ForceChangePasswordNextSignIn = $true
}
```

```powershell
Update-ModuleManifest -Path .\CustomEntra\CustomEntra.psd1 -ModuleVersion '1.0.1' -ReleaseNotes 'Extraction de la génération du mot de passe (New-CustomPassword)'
Publish-PSResource -Path .\CustomEntra -Repository LocalRepo
Update-PSResource  -Name CustomEntra

Find-PSResource -Name CustomEntra -Repository LocalRepo -Version *   # 1.0.1 et 1.0.0
```

===
