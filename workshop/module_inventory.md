---
icon: beaker
order: 7
title: Module SynInventory
---

# Atelier : packager son code en module

**Objectif** : transformer la fonction de l'atelier [Computer Info](computer_info.md) en un module versionné, documenté et publié dans un dépôt interne.

!!!
Ce module servira de fil rouge : il sera testé avec Pester et optimisé dans le module suivant.
!!!

## Étape 1 - Structure

1. Créer l'arborescence d'un module `SynInventory` avec les dossiers `Public` et `Private`.
2. Placer votre fonction de l'atelier *Computer Info* dans `Public\Get-SynComputerInfo.ps1`.
3. Extraire la conversion octets → Go dans une fonction **privée** `ConvertTo-GiB` (arrondie à 2 décimales).
4. Écrire le loader `SynInventory.psm1`.

## Étape 2 - Manifeste

1. Générer `SynInventory.psd1` avec `New-ModuleManifest` en version `1.0.0`.
2. Vérifier le manifeste avec `Test-ModuleManifest`.
3. Importer le module et valider que :
   - seule `Get-SynComputerInfo` est visible ;
   - `ConvertTo-GiB` n'est **pas** accessible depuis la session ;
   - `Get-Help Get-SynComputerInfo -Examples` renvoie vos exemples.

## Étape 3 - Publication

1. Créer un dossier `C:\PSRepo` et l'enregistrer comme dépôt `LocalRepo`.
2. Publier `SynInventory` en `1.0.0`.
3. Installer le module depuis le dépôt, ouvrir une **nouvelle** console et appeler `Get-SynComputerInfo` **sans** `Import-Module`.

## Étape 4 - Nouvelle version

1. Ajouter une propriété `Uptime` (durée depuis le dernier démarrage) à l'objet renvoyé.
2. Déterminer le bon numéro de version selon SemVer et mettre à jour le manifeste.
3. Publier, puis mettre à jour le module installé.
4. Vérifier que les **deux** versions sont présentes dans le dépôt.

!!!warning Contraintes
- La fonction publique conserve l'entrée pipeline (`Get-ADComputer | Get-SynComputerInfo`).
- Aucune valeur en dur liée à votre poste (chemin, nom de machine...) dans le module.
- `FunctionsToExport` doit être explicite.
!!!

## Bonus

- Ajouter un fichier `en-US\about_SynInventory.help.txt`.
- Générer la documentation Markdown du module avec PlatyPS.
- Ajouter un `CHANGELOG.md`.

==- Corrigé
### Arborescence

```
SynInventory\
├── SynInventory.psd1
├── SynInventory.psm1
├── Public\
│   └── Get-SynComputerInfo.ps1
└── Private\
    └── ConvertTo-GiB.ps1
```

### Private\ConvertTo-GiB.ps1

```powershell
function ConvertTo-GiB {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [uint64]$Bytes
    )
    process {
        [math]::Round($Bytes / 1GB, 2)
    }
}
```

### Public\Get-SynComputerInfo.ps1

```powershell
function Get-SynComputerInfo {
    <#
    .SYNOPSIS
        Renvoie les informations matérielles et système d'une ou plusieurs machines.
    .DESCRIPTION
        Interroge les classes CIM Win32_OperatingSystem, Win32_ComputerSystem et
        Win32_LogicalDisk pour renvoyer un objet d'inventaire par machine.
    .PARAMETER ComputerName
        Nom(s) de la ou des machines cibles. Accepte l'entrée pipeline (ex: Get-ADComputer).
    .EXAMPLE
        Get-SynComputerInfo -ComputerName SRV01, SRV02
    .EXAMPLE
        Get-ADComputer -Filter 'OperatingSystem -like "*Server*"' | Get-SynComputerInfo
    #>
    [CmdletBinding()]
    [OutputType('Syn.ComputerInfo')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'DNSHostName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Interrogation de $computer"
            try {
                $session = New-CimSession -ComputerName $computer -ErrorAction Stop

                $os   = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem -ErrorAction Stop
                $cs   = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem  -ErrorAction Stop
                $disk = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop

                [PSCustomObject]@{
                    PSTypeName   = 'Syn.ComputerInfo'
                    ComputerName = $cs.Name
                    OS           = $os.Caption
                    Version      = $os.Version
                    Build        = $os.BuildNumber
                    CPUCores     = $cs.NumberOfLogicalProcessors
                    RAMGiB       = ConvertTo-GiB -Bytes $cs.TotalPhysicalMemory
                    FreeCGiB     = ConvertTo-GiB -Bytes $disk.FreeSpace
                }
            }
            catch {
                Write-Error -Message "Impossible d'interroger $computer : $($_.Exception.Message)" -TargetObject $computer
            }
            finally {
                if ($session) { Remove-CimSession -CimSession $session; $session = $null }
            }
        }
    }
}
```

### SynInventory.psm1

```powershell
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
$Public  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue)

foreach ($file in @($Private + $Public)) {
    try { . $file.FullName }
    catch { Write-Error "Échec du chargement de $($file.FullName) : $_" }
}

Export-ModuleMember -Function $Public.BaseName
```

### Manifeste et validation

```powershell
$manifest = @{
    Path              = '.\SynInventory\SynInventory.psd1'
    RootModule        = 'SynInventory.psm1'
    ModuleVersion     = '1.0.0'
    Author            = 'Stagiaire'
    CompanyName       = 'Synapsys'
    Description       = 'Inventaire matériel et système des machines Windows'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-SynComputerInfo')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    Tags              = @('Inventory', 'CIM')
}
New-ModuleManifest @manifest
Test-ModuleManifest .\SynInventory\SynInventory.psd1

Import-Module .\SynInventory -Force
Get-Command -Module SynInventory                 # Get-SynComputerInfo uniquement
Get-Command ConvertTo-GiB -ErrorAction Ignore    # Rien
```

### Publication

```powershell
New-Item -ItemType Directory -Path C:\PSRepo -Force
Register-PSResourceRepository -Name LocalRepo -Uri C:\PSRepo -Trusted

Publish-PSResource -Path .\SynInventory -Repository LocalRepo
Install-PSResource -Name SynInventory -Repository LocalRepo -Scope CurrentUser
```

### Version 1.1.0

Ajout d'une propriété → nouvelle fonctionnalité compatible → **version mineure**.

```powershell Dans l'objet renvoyé par Get-SynComputerInfo
Uptime = (Get-Date) - $os.LastBootUpTime
```

```powershell
Update-ModuleManifest -Path .\SynInventory\SynInventory.psd1 -ModuleVersion '1.1.0' -ReleaseNotes 'Ajout de la propriété Uptime'
Publish-PSResource -Path .\SynInventory -Repository LocalRepo
Update-PSResource  -Name SynInventory

Find-PSResource -Name SynInventory -Repository LocalRepo -Version *   # 1.1.0 et 1.0.0
```
===
