---
icon: sign-out
order: 9
title: Ouputs
---

# Renvoyer un objet en sortie

Dans la plupart des cas, votre script aura à renvoyer des données. Il convient alors de le faire dans la philophie de Powershell et de les renvoyer sous forme d'objets.

Nous utiliserons pour cela un `[pscustomobject]`

Prenon l'exemple d'un code qui récupère des informations sur des machines à l'aide des commandes **CimInstance** (Remplacant de WmiObject) :

```powershell
$OS = Get-CimInstance -ClassName Win32_OperatingSystem
$CPU = Get-CimInstance win32_processor 
$Volume = Get-Volume  -DriveLetter C
```

Nous aurons plusieurs variables, alimentés par différentes commandes dont nous souhaitons consolider la sortie en un objet :

+++ :icon-code: Code
```powershell
[PSCustomObject]@{
    ComputerName = $OS.CSName
    OSVersion = $OS.Caption,$OS.Version -join " "
    CPUClockSpeed = [math]::Round($CPU.MaxClockSpeed / 1024,2)
    FreeSpace = ($Volume.SizeRemaining / $Volume.Size).ToString("P")
}
```

+++ :icon-note: Output

```powershell
ComputerName OSVersion                                     CPUClockSpeed FreeSpace
------------ ---------                                     ------------- ---------
WKS01         Microsoft Windows 11 Professionnel 10.0.22621          3,61 2,85 %
```

+++

Dans le cas où notre code est éxécuté sur plusieurs cibles, nous créerons notre `[pscustomobject]` dans notre boucle ou dans le bloc `process` d'une fonction avancée pour consolider la sortie sous forme de collection.

```powershell
foreach ($Computer in $Computer_List)
{
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer
    $CPU = Get-CimInstance win32_processor -ComputerName $Computer
    $Volume = Get-Volume -CimSession $Computer -DriveLetter C

    [PSCustomObject]@{
        ComputerName  = $OS.CSName
        OSVersion     = $OS.Caption, $OS.Version -join ' '
        CPUName       = $CPU.Name
        CPUClockSpeed = [math]::Round($CPU.MaxClockSpeed / 1024, 2)
        FreeSpace     = ($Volume.SizeRemaining / $Volume.Size).ToString('P')
    }
}
```

Si la collection obtenue dans la boucle doit servir dans un traitement plus loin dans le code, la boucle elle même pourra être renvoyée dans une variable.

!!!warning
On voit souvent dans ce cas, la création d'une liste vide et son incrémentation dans la boucle. **Cette méthode est à proscrire** pour des raisons de performance et de lisibilité.
!!!


+++ :icon-code: Bonne Méthode

```powershell
$Result = foreach ($Computer in $Computer_List)
{
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer
    $CPU = Get-CimInstance win32_processor -ComputerName $Computer
    $Volume = Get-Volume -CimSession $Computer -DriveLetter C

    [PSCustomObject]@{
        ComputerName  = $OS.CSName
        OSVersion     = $OS.Caption, $OS.Version -join ' '
        CPUName       = $CPU.Name
        CPUClockSpeed = [math]::Round($CPU.MaxClockSpeed / 1024, 2)
        FreeSpace     = ($Volume.SizeRemaining / $Volume.Size).ToString('P')
    }
}


$Result | Convertto-Json | Out-File report.json
```

+++ :icon-x-circle-fill: A Proscrire
```powershell
$Result = @()

foreach ($Computer in $Computer_List)
{
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer
    $CPU = Get-CimInstance win32_processor -ComputerName $Computer
    $Volume = Get-Volume -CimSession $Computer -DriveLetter C

    $Result += [PSCustomObject]@{
        ComputerName  = $OS.CSName
        OSVersion     = $OS.Caption, $OS.Version -join ' '
        CPUName       = $CPU.Name
        CPUClockSpeed = [math]::Round($CPU.MaxClockSpeed / 1024, 2)
        FreeSpace     = ($Volume.SizeRemaining / $Volume.Size).ToString('P')
    }
}
```

+++

!!!
Il existe une autre syntaxe pour la création du `[pscustomobject]` :

```powershell
$Properties = @{
        ComputerName  = $OS.CSName
        OSVersion     = $OS.Caption, $OS.Version -join ' '
        CPUName       = $CPU.Name
        CPUClockSpeed = [math]::Round($CPU.MaxClockSpeed / 1024, 2)
        FreeSpace     = ($Volume.SizeRemaining / $Volume.Size).ToString('P')
    }

$Result = New-Object -TypeName PSObject -Property $Properties
Write-Output $Result
```

!!!