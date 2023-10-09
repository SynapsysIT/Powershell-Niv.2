---
icon: question
order: 6
title: Intégrer une aide
---

# Comment Based Help

On peut intégrer une aide dans sa fonction ou son script via un bloc de commentaire dédié:

+++ :icon-code: Code

```powershell
function Get-ComputerStatus
{
<#
.SYNOPSIS
    Get computer status information.
.DESCRIPTION
    This command query information on multiple computers (OSVersion, EspaceDisk, ...)
.NOTES
    Version: 1.0.0
    Updated On : 05/10/23
.LINK
    https://repository.conto.com/Powershell/Get-ComputerStatus
.EXAMPLE
    Get-ComputerStatus -ComputerName Computer01
    
    ComputerName  : Computer01
    OSVersion     : Microsoft Windows 11 Professionnel 10.0.22621
    CPUName       : Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
    CPUClockSpeed : 3,61
    FreeSpace     : 2,84 %
#>
    [CmdletBinding()]
    param (
        [string[]]$ComputerName
    )
    
   # Function Code
}
```

+++ :icon-note: Output Get-Help

```txt
ﲵ Get-Help Get-ComputerStatus

NAME
    Get-ComputerStatus

SYNOPSIS
    Get computer status information.


SYNTAX
    Get-ComputerStatus [[-ComputerName] <String[]>] [<CommonParameters>]


DESCRIPTION
    This command query information on multiple computers (OSVersion, EspaceDisk, ...)


RELATED LINKS
    https://repository.conto.com/Powershell/Get-ComputerStatus

REMARKS
    To see the examples, type: "Get-Help Get-ComputerStatus -Examples"
    For more information, type: "Get-Help Get-ComputerStatus -Detailed"
    For technical information, type: "Get-Help Get-ComputerStatus -Full"
    For online help, type: "Get-Help Get-ComputerStatus -Online"

```

+++ :icon-note: Output Get-Help -Full

```txt
ﲵ Get-Help Get-ComputerStatus -Full
NAME
    Get-ComputerStatus
    
SYNOPSIS
    Get computer status information.
    
    
SYNTAX
    Get-ComputerStatus [[-ComputerName] <String[]>] [<CommonParameters>]
    
    
DESCRIPTION
    This command query information on multiple computers (OSVersion, EspaceDisk, ...)
    

PARAMETERS
    -ComputerName <String[]>
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    
NOTES
    
    
        Version: 1.0.0
        Updated On : 05/10/23
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS > Get-ComputerStatus -ComputerName Computer01
    
    ComputerName  : Computer01
    OSVersion     : Microsoft Windows 11 Professionnel 10.0.22621
    CPUName       : Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
    CPUClockSpeed : 3,61
    FreeSpace     : 2,84 %
    
    
RELATED LINKS
    https://repository.conto.com/Powershell/Get-ComputerStatus

```