---
icon: sign-in
order: 10
title: Paramètres
---

# Les paramètres

```powershell Ensemble des options et des attributs de paramètres possibles:
param (
    [Parameter(Mandatory = $Boolean,
        Position = Int,
        ParameterSetName = "String",
        ValueFromPipeline = $Boolean,
        ValueFromPipelineByPropertyName = $Boolean,
        ValueFromRemainingArguments = Boolean)]
    [Alias('String')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('String1', 'String2')]
    [ValidateCount(Int_min, Int_max)]
    [ValidateLength(Int_min, Int_max)]
    [ValidateRange(Int_min, Int_max)]
    [ValidatePattern('RegexPattern')]
    [ValidateScript({ Expression })]
    [AllowNull()]
    [AllowEmptyString()]
    [AllowEmptyCollection()]
    [Type[]]
    $Name
)
```

## Options de paramètres

### Mandatory

Cette option permet de rendre un paramètre **obligatoire**. Si ce paramètre est oublié à l'appel du script ou de la fonction, un prompt apparaitre pour founir une valeur.

### Position

Si un position est rensignée, le script ou la fonction pourront être appelés sans préciser le nom du paramètre. La valeur des paramètres seront attribués en fonction de l'ordre dans lequelles ils ont étés renseignés.

For example, the Get-ChildItem cmdlet has Path and Exclude parameters. The Position setting for Path is 0, which means that it is a positional parameter. The Position setting for Exclude is named.

Par exemple, la commande `Get-ChildItem` à un paramètre `Path` qui une position **0**. Cette commande s'exécutera donc de la même manière dans tous les cas suivant:

```powershell
Get-ChildItem -Path "C:\Temp"
Get-ChildItem "C:\Temp"
Get-ChildItem -Exclude "*.log" "C:\Temp"
```

Dans le dernier exemple, le paramètre `Exclude` sera ignoré dans la position, car nommé.

### Parameter Set Name

Les `ParameterSetName` permette de changer le comportement du code en fonction d'un groupe de paramètre utilisé.

Les règles suivantes s'applique au `ParameterSetName`:

- Seul un Set de paramètre peut être utilisé lors de l'appel de la fonction ou du script.
- Si aucun Set est précisé, le paramètre appartient à tous les Sets.
- Un paramètre peut appartenir à plusieurs Set
  
```powershell Exemple d'utilisation
function Convert-IPMask
{

    param (
        [Parameter(ParameterSetName = 'CIDR')]
        [int]$CIDR,

        [Parameter(ParameterSetName = 'IP')]
        [ipaddress]$Mask
    )
    
    switch ($PSCmdlet.ParameterSetName)
    {
        'CIDR'
        {
            $Binary = ('1' * $CIDR) + ('0' * (32 - $CIDR))
            $Mask = [IPAddress] ([Convert]::ToUInt64($Binary, 2))
            Write-Output $Mask.IPAddressToString
        }
        'IP'
        {
            [void]($Mask.IPAddressToString -match '(.*)\.(.*)\.(.*)\.(.*)')
            $Suffix = ''
            $Matches[1..4] | ForEach-Object {
                $Suffix += [Convert]::ToString([int] $_, 2) + ('0' * (8 - [Convert]::ToString([int] $_, 2).Length))
            }       
            Write-Output ($Suffix -split '[^1]')[0].Length
        }
    }
}
```

[!badge target="blank" text="about_Parameter_Sets"](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameter_sets?view=powershell-7.3)

### ValueFromPipeline

Ce boolean permet de définir que ce paramètre pourra prendre sa valeur depuis le pipeline [!badge variant="danger" text="|"]

+++ :icon-code: Code

```powershell #5,8
function Convert-IPMask
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true,ParameterSetName = 'CIDR')]
        [int]$CIDR,

        [Parameter(ValueFromPipeline=$true,ParameterSetName = 'IP')]
        [ipaddress]$Mask
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'CIDR'
        {
            $Binary = ('1' * $CIDR) + ('0' * (32 - $CIDR))
            $Mask = [IPAddress] ([Convert]::ToUInt64($Binary, 2))
            Write-Output $Mask.IPAddressToString
        }
        'IP'
        {
            [void]($Mask.IPAddressToString -match '(.*)\.(.*)\.(.*)\.(.*)')
            $Suffix = ''
            $Matches[1..4] | ForEach-Object {
                $Suffix += [Convert]::ToString([int] $_, 2) + ('0' * (8 - [Convert]::ToString([int] $_, 2).Length))
            }       
            Write-Output ($Suffix -split '[^1]')[0].Length
        }
    }
}
```

+++ :icon-play: Exemple

```powershell
> 24 | Convert-IPMask
255.255.255.0

> "255.255.255.0" | Convert-IPMask
34
```

+++

+++ :icon-code: Code

```powershell #5
function Set-Machine
{
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerName
    )

    process
    {
        Write-Verbose "Process $ComputerName" -Verbose    
    }
    
}
```

+++ :icon-play: Exemple

```powershell
> "SERVER01","SERVER02","SERVER03" | Set-Machine

VERBOSE: Process SERVER01
VERBOSE: Process SERVER02
VERBOSE: Process SERVER03
```

```powershell
> Get-Content servers.txt | Set-Machine

VERBOSE: Process SERVER01
VERBOSE: Process SERVER02
VERBOSE: Process SERVER03
```

+++

### ValueFromPipelineByPropertyName

`ValueFromPipelineByPropertyName` permet de lier un paramètre à un une propriété de l'objet recu dans le pipeline **par leur nom**.

Les deux doivent avoir le même type. Ici dans l'exemple, la propriété `Name` d'un objet `service` est un `[string]` et peut donc être récupérer par le paramètre `$Name` de notre commande.

On peut utiliser les alias de paramètres pour faire correspondre notre paramètre à plusieurs nom de propriétés possible.

+++ :icon-code: Code

```powershell #5
function Test-Pipeline
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Name
    )

    begin {
        Write-Host "Services Status" -ForegroundColor Yellow
        Write-Host $input
    }

    process {
       switch ((Get-Service $Name -ErrorAction SilentlyContinue).Status) {
           "Running" { Write-Host 🟢 $Name }
           "Stopped" { Write-Host 🔴 $Name }
       }
    }

    end {
        Write-Host "Done !" -ForegroundColor Yellow
    }
}
```

+++ :icon-play: Exemple

```powershell
> Get-Service | Test-Pipeline
Services Status

🔴 AarSvc_56a53
🟢 AdobeARMservice
🟢 AESMService
🔴 AJRouter
🔴 ALG
🔴 AppIDSvc
🟢 Appinfo
🟢 AppMgmt
🔴 AppReadiness
🔴 AppVClient
🟢 AppXSvc
🔴 AssignedAccessManagerSvc
🟢 AudioEndpointBuilder
...
```

+++

### ValueFromRemainingArguments

`ValueFromRemainingArguments` permet de spécifier que ce paramètre acceptera tous les arguments restant qui seront passés à la ligne de commande de la ligne de commande.

+++ :icon-code: Code

```powershell
function Test-Function {
    [CmdletBinding()]
    param (

        [Parameter()]
        [string]$MainParameter,

        [Parameter(ValueFromRemainingArguments)]
        [array]$Arguments
    )
    
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        
        Write-Verbose "Remaining Arguments $i : $($Arguments[$i])"
    }

}
```

+++ :icon-play: Exemple

```powershell
> Test-Function -MainParameter "test" toto tata titi -Verbose

VERBOSE: Remaining Arguments 0 : toto
VERBOSE: Remaining Arguments 1 : tata
VERBOSE: Remaining Arguments 2 : titi
```

+++


## Attributs de paramètres

### Alias

L'attribut `alias` permet de spécifier un ou plusieurs nom alternatif pour un paramètres. Il peut être utilisé pour founir un nom court au paramètre ou pour faire le faire correspondre à plusieurs nom de propriétés possibles lorsqu'il est utilisé avec `ValueFromPipelineByPropertyName`.

```powershell #2
    param (
        [Alias("Hostname","Name")]
        [string]$ComputerName
    )
```

### ValidateNotNull

L'attribut `ValidateNotNull` spécifie que la valeur du paramètre ne peut pas être `$null`

### ValidateNotNullOrEmpty

L’attribut `ValidateNotNullOrEmpty` spécifie que la valeur affectée ne peut pas être l’une des valeurs suivantes :

- `$null`
- une chaine vide `""`
- un tableau ou une liste vide `@()`

### ValidateSet

L'attribut ValidateSet spécifie un ensemble de valeurs valide pour ce paramètre et permet l'auto-complétion lors de la saisie de la valeur.

```powershell #3
    param (
        [Parameter()]
        [ValidateSet('WindowsServer2016', 'WindowsServer2016','WindowsServer2022')]
        [string]$OperatingSystem
    )
```

!!!warning
Cette validation se fera à chaque assignation de cette variable :

```powershell
function Test-Function {
    param (
        [Parameter()]
        [ValidateSet('WindowsServer2016', 'WindowsServer2016','WindowsServer2022')]
        [string]$OperatingSystem
    )

    $OperatingSystem = "Linux"
}
```

Cette exemple renverra l'erreur suivante:

```txt
The variable cannot be validated because the value Linux is not a valid value for the OperatingSystem variable.
```

!!!

### ValidateCount

L'attribut `ValidateCount` spécifie le nombre de valeur minimal et maximal autorisé pour un paramètre

```powershell
[ValidateCount(Int_min, Int_max)]
```

### ValidateLength

Dans le cas d'un paramètre de type `[string]`. L'attribut `ValidateLength` spécifie le nombre de caractère minimal et maximal pour la valeur du paramètre.

```powershell
[ValidateLength(Int_min, Int_max)]
```


### ValidateRange

Dans le cas d'un paramètre de type `[int]` ou `[double]`. L'attribut `ValidateRange` spécifie la valeur minimale et maximal que ce paramètre peut recevoir comme valeur.

```powershell
[ValidateRange(Int_min, Int_max)]
```

### ValidatePattern

L'attribut `ValidatePattern` permet d'utiliser une expression régulière (RegEx) pour valider la valeur d'un paramètre.

Dans cet exemple, on validera que la valeur du paramètre `-Telephone` soit un numéro de téléphone français valide :

```powershell #4
function Test-Function {
    param (
        [Parameter()]
        [ValidatePattern("^(0033|0|\+33)[1-9]([-. ]?[0-9]{2}){4}$")]
        [string]$Telephone
    )
}
```


### ValidateScript

L'attribut `ValidatePattern`  permettra de fournir un bloc de code qui sera exécuté pour valider la valeur du paramètre. Ce bout de code devra renvoyé une variable de type `[bool]` (`$true` | `$false` ).

Dans ce bloc de script, [!badge variant="danger" text="$_"] fera référence à la valeur du paramètre spécifié.

Dans cet exemple, on validera que le chemin renseigné en valeur du paramètre `-Path` existe :

```powershell #4
function Test-Function {
    param (
        [Parameter()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path
    )
}
```

### AllowNull

L'attribut `AllowNull` permet à la valeur d'un paramètre **obligatoire** d'être `$null`

### AllowEmptyString

L'attribut `AllowEmptyString` permet à la valeur d'un paramètre **obligatoire** de type `[string]` d'être vide `""`

### AllowEmptyCollection

L'attribut `AllowEmptyCollection` permet à la valeur d'un paramètre **obligatoire** d'être une collection vide `@()`


___
#### Voir plus sur learn.microsoft.com

[!badge target="blank" text="Attributs des applets de commandes"](https://learn.microsoft.com/fr-fr/powershell/scripting/developer/cmdlet/cmdlet-attributes?view=powershell-7.3) - 
[!badge target="blank" text="about_Functions_Argument_Completion"](https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/about/about_functions_argument_completion?view=powershell-7.3) - [!badge target="blank" text="about_Functions_Advanced_Parameters"](https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.3)
