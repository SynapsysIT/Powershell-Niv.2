---
icon: key
order: 10
title: Corrigé - Module CustomEntra
visibility: hidden
---

# Corrigé : Module CustomEntra

Énoncé : [Module CustomEntra](module_entra.md)

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
