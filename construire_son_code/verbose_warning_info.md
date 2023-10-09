---
icon: log
order: 7
title: Verbose, Warning and Information Output
---

# Utiliser Verbose, Debug Output

## Connaitre les différents canaux de sorties

Il est utile de connaitre les 6 canaux de sorties de Powershell:

{.compact}
Canal   | Description
---    | ---
**1 - Success** | C'est le pipeline classique de toute commande en *succés*. Celui qui s'affiche dans la console ou est renvoyé dans une variable.
**2 - Error** |
**3 - Warning** |
**4 - Verbose** |
**5 - Debug** |
**6 - Informational** |

## Ajouter des sorties Verbose et Debug

La déclaration `[CmdletBinding()]` permet d'activer les *CommonsParameters* sur fonction ou votre script, dont `-Verbose` et `-Debug`.

Ces commandes ont pour but de faciliter le troubleshoot de votre code et de suivre son déroulement.

Les commandes [!badge target="blank" text="Write-Verbose"](https://go.microsoft.com/fwlink/?LinkID=2097043) et [!badge target="blank" text="Write-Debug"](https://go.microsoft.com/fwlink/?LinkID=2097132) permettront respectivement de définir vos messages et s'afficheront respectivement en présence des paramètres `-Verbose` et `-Debug` à l'appel de votre code.

+++ :icon-code: Code

```powershell #11,19,21,29
function Get-ComputerStatus
{
    [CmdletBinding()]
    param (
        [string[]]$ComputerName
    )
    begin
    {
        Write-Verbose "Start $($MyInvocation.MyCommand)"
    }
    process
    {    
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Querying $Computer"
            Write-Debug "[$Computer]Debug Message "
            <# Votre Code #>
        }
    }
    end
    {
        Write-Verbose "End $($MyInvocation.MyCommand)"
    }
}
```

+++ :icon-note: Run with Verbose

```txt
ﲵ  Get-ComputerStatus -ComputerName Computer01,Computer02 -Verbose
VERBOSE: Start Get-ComputerStatus
VERBOSE: Querying Computer01
VERBOSE: Querying Computer02
VERBOSE: End Get-ComputerStatus
```

+++ :icon-note: Run with Verbose + Debug

```txt
ﲵ Get-ComputerStatus -ComputerName Computer01,Computer02 -Verbose -Debug
VERBOSE: Start Get-ComputerStatus
VERBOSE: Querying Computer01
DEBUG: Debug Message
VERBOSE: Querying Computer02
DEBUG: Debug Message
VERBOSE: End Get-ComputerStatus
```

+++

L'activation de ces paramètre activeront le Verbose et le Debug sur l'ensemble des commandes les prenant en compte dans votre code:

+++ :icon-code: Code

```powershell #11,19,21,29
function Get-ComputerStatus
{

    [CmdletBinding()]
    param (
        [string[]]$ComputerName
    )
    
    begin
    {
        Write-Verbose "Start $($MyInvocation.MyCommand)"
    }
    
    process
    {    
        foreach ($Computer in $ComputerName)
        {

            Write-Verbose "Querying $Computer"

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

            Write-Debug 'Debug Message '

            <# Votre Code #>
        }
    
    
    end
    {
        Write-Verbose "End $($MyInvocation.MyCommand)"
    }
}
```

+++ :icon-note: Run with Verbose + Debug

```txt
ﲵ Get-ComputerStatus -ComputerName Computer01,Computer02 -Verbose

VERBOSE: Start Get-ComputerStatus
VERBOSE: Querying localhost
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''className' = Win32_OperatingSystem,'namespaceName' = root\cimv2'.
VERBOSE: Operation 'Enumerate CimInstances' complete.
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''className' = win32_processor,'namespaceName' = root\cimv2'.
VERBOSE: Operation 'Enumerate CimInstances' complete.

ComputerName  : Computer01
OSVersion     : Microsoft Windows 11 Professionnel 10.0.22621
CPUName       : Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
CPUClockSpeed : 3,61
FreeSpace     : 2,84 %

DEBUG: Debug Message
VERBOSE: Querying localhost
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''className' = Win32_OperatingSystem,'namespaceName' = root\cimv2'.
VERBOSE: Operation 'Enumerate CimInstances' complete.
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''className' = win32_processor,'namespaceName' = root\cimv2'.
VERBOSE: Operation 'Enumerate CimInstances' complete.

ComputerName  : Computer02
OSVersion     : Microsoft Windows 11 Professionnel 10.0.22621
CPUName       : Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
CPUClockSpeed : 3,61
FreeSpace     : 25,44 %

DEBUG: Debug Message
VERBOSE: End Get-ComputerStatus
```

+++

!!!
On peut désactiver la sortie Verbose ou Debug d'une commande en désactivant le paramètre de manière explicite: `-Verbose:$false`
!!!

## Warning Output

[!badge target="blank" text="Write-Warning"](https://go.microsoft.com/fwlink/?LinkID=2097044) fonctionne comme les commandes précédentes, à la différence que les messages de type Warning sont activés par defaut.


+++ :icon-code: Code

```powershell #17
function Get-ComputerStatus
{
    [CmdletBinding()]
    param (
        [string[]]$ComputerName
    )
    begin
    {
        Write-Verbose "Start $($MyInvocation.MyCommand)"
    }
    process
    {    
        foreach ($Computer in $ComputerName)
        {
            if (-not (Test-Connection $Computer -Quiet -Count 1))
            {
                Write-Warning "$Computer is not reachable. Skip !"
            }
            <# Votre Code #>
        }
    }
    end
    {
        Write-Verbose "End $($MyInvocation.MyCommand)"
    }
}
```

+++ :icon-note: Output

```txt
ﲵ Get-ComputerStatus -ComputerName Computer01,ComputerXX -Verbose -Debug
VERBOSE: Start Get-ComputerStatus
WARNING: ComputerXX is not reachable. Skip !
VERBOSE: End Get-ComputerStatus
```

+++


## Informational Output

[!badge target="blank" text="Write-Information"](https://go.microsoft.com/fwlink/?LinkId=2097040) permet d'écrire des messages d'information. Il permet de remplacer le classique `Write-Host` pour écrire des messages informatifs. Mais permet comme `Write-Verbose` et `Write-Debug` d'activer ou non son affichage à l'exécution de la commande.

`Write-Information` permet aussi de tagguer ces messages pour pouvoir filtrer ces messages

+++ :icon-code: Code

```powershell
Function Get-Example {
[CmdletBinding()]
Param()
Write-Information "First message" -tag status
Write-Information "Note that this had no parameters" -tag notice
Write-Information "Second message" -tag status
}
```

+++ :icon-note: Output

```powershell
ﲵ Get-Example -InformationAction SilentlyContinue -InformationVariable "Infos"

ﲵ $Infos

First message
Note that this had no parameters
Second message

ﲵ $Infos | Where-Object {$_.Tags -eq "notice"}

Note that this had no parameters
```

+++


### Output Préférence

Les outputs de type **Warning**, **Error**, ou **Information** peuvent etre paramétrés en entrée de la commande ou du script via les paramètres:

- `-WarningAction`
- `-ErrorAction`
- `-InformationAction`

ou via les variables automatiques respectives:

- `$WarningPreference`
- `$ErrorPreference`
- `$InformationPreference`

Ces paramètres et ces variables peuvent recevoir les valeurs suivantes:

Continue
:   Affiche les messages et continue l'exécution (Valeur par defaut)

SilentlyContinue
:   Cache les messages et continue l'exécution

Ignore
:   Supprime le message et continue l'éxécution. Dans le cas de `-ErrorActionPreference`, n'alimente pas la variable `$Error`

Inquire
:   Supprime le message et demande confirmation avant de continuer l'éxécution.

Stop
:   Affiche le message et stoppe l'éxécution. 


