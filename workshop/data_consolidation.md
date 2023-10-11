---
icon: beaker
order: 10
title: JSON Data Consolidation
---

1. Cloner le resository sur votre machine:
  
```bash
git clone https://github.com/SynapsysIT/Powershell-Niv.2-Resources.git
```

2. A partir du dossier `\Workshop\Data Consolidation\SampleData` et des fichiers qu'il contient. Coder une fonction qui renverra sous forme d'objet :

   - Le nombre de fichier traités
   - Le nombre d'items total
   - Le nombre total d'erreurs
   - La moyenne des warnings
   - Le premier job éxécuté
   - Le dernier job éxécuté


!!!warning
Cette fonction devra recevoir en paramètre un chemin d'accés vers les fichiers (à minima)
!!!


```powershell SOLUTION
Function Start-ConsolidateData
{
    <#
    .SYNOPSIS
        A short one-line action-based description, e.g. 'Tests if a function is valid'
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .PARAMETER SourceFolderPath
        Target Folder
    .EXAMPLE
        Start-ConsolidateData -SourceFolderPath C:\Logs
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateScript( { Test-Path $_ } )]
        [string]$SourceFolderPath
    )
        #GCI
        $Files = Get-ChildItem -Path $SourceFolderPath -File

        #Change Culture in script process to handle US Date Format
        [System.Threading.Thread]::CurrentThread.CurrentCulture = "en-US"


        #Convert From Json
        $Obj = foreach ($File in $Files)
        {
            try
            {
                Write-Verbose "Process file: $($File.Name)"
                $Converted = Get-Content -Path $File.PSPath | ConvertFrom-Json -ErrorAction Stop
                $Converted.RunDate  = Get-Date $Converted.RunDate

                Write-Output $Converted
            }
            catch
            {
                Write-Warning "Le fichier $($File.Name) n'est pas un fichier JSON valide."
            }

        }

        [PSCustomObject]@{
            TotalProcessedItems = ($Obj | Measure-Object -Property "Items processed" -Sum).Sum
            TotalFiles          = $Obj.count
            TotalErrors         = ($Obj | Measure-Object -Property Errors -Sum).Sum
            AverageWarnings     = "{0:n2}" -f ($Obj | Measure-Object -Property Warnings -Average).Average
            First               = ($Obj | Sort-Object -Property RunDate)[0]
            Last                = ($Obj | Sort-Object -Property RunDate)[-1]
        }
}
```