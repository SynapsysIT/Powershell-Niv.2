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

La déclaration `[CmdletBinding()]` permet d'activer les *CommonsParameters* sur votre fonction ou votre script, dont `-Verbose` et `-Debug`.

Ces commandes ont pour but de faciliter le troubleshoot de votre code et de suivre son déroulement.

Les commandes [!badge target="blank" text="Write-Verbose"](https://go.microsoft.com/fwlink/?LinkID=2097043) et [!badge target="blank" text="Write-Debug"](https://go.microsoft.com/fwlink/?LinkID=2097132) permettront respectivement de définir vos messages et s'afficheront respectivement en présence des paramètres `-Verbose` et `-Debug` à l'appel de votre code.

+++ :icon-code: Code

```powershell #9,15,16,17,28
function Get-EntraUserStatus
{
    [CmdletBinding()]
    param (
        [string[]]$UserPrincipalName
    )
    begin
    {
        Write-Verbose "Start $($MyInvocation.MyCommand)"
    }
    process
    {
        foreach ($User in $UserPrincipalName)
        {
            Write-Verbose "Querying $User"
            $EntraUser = Get-MgUser -UserId $User -Property Id, DisplayName, AccountEnabled
            Write-Debug "[$User] Object Id : $($EntraUser.Id)"

            [PSCustomObject]@{
                UserPrincipalName = $User
                DisplayName       = $EntraUser.DisplayName
                Enabled           = $EntraUser.AccountEnabled
            }
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
ﲵ Get-EntraUserStatus -UserPrincipalName lskywalker@SynapsysTest.onmicrosoft.com,lorgana@SynapsysTest.onmicrosoft.com -Verbose
VERBOSE: Start Get-EntraUserStatus
VERBOSE: Querying lskywalker@SynapsysTest.onmicrosoft.com

UserPrincipalName                       DisplayName    Enabled
-----------------                       -----------    -------
lskywalker@SynapsysTest.onmicrosoft.com Luke Skywalker    True
VERBOSE: Querying lorgana@SynapsysTest.onmicrosoft.com
lorgana@SynapsysTest.onmicrosoft.com    Leia Organa      False
VERBOSE: End Get-EntraUserStatus
```

+++ :icon-note: Run with Verbose + Debug

```txt
ﲵ Get-EntraUserStatus -UserPrincipalName lskywalker@SynapsysTest.onmicrosoft.com,lorgana@SynapsysTest.onmicrosoft.com -Verbose -Debug
VERBOSE: Start Get-EntraUserStatus
VERBOSE: Querying lskywalker@SynapsysTest.onmicrosoft.com
DEBUG: [lskywalker@SynapsysTest.onmicrosoft.com] Object Id : 3f2a6c1e-8b4d-4e7a-9c21-5d8e7f1a2b3c

UserPrincipalName                       DisplayName    Enabled
-----------------                       -----------    -------
lskywalker@SynapsysTest.onmicrosoft.com Luke Skywalker    True
VERBOSE: Querying lorgana@SynapsysTest.onmicrosoft.com
DEBUG: [lorgana@SynapsysTest.onmicrosoft.com] Object Id : 9b7e4d2a-1c3f-4a6b-8e5d-2f1a7c9b4e6d
lorgana@SynapsysTest.onmicrosoft.com    Leia Organa      False
VERBOSE: End Get-EntraUserStatus
```

+++

!!!warning Windows PowerShell 5.1
Sous Windows PowerShell 5.1, `-Debug` passe `$DebugPreference` à `Inquire` : l'exécution s'arrête et demande confirmation à **chaque** `Write-Debug`. Depuis PowerShell 7, la valeur est `Continue`.
!!!

L'activation de ces paramètres activera le Verbose et le Debug sur les commandes **de votre code** qui les prennent en compte. Avec le SDK Microsoft Graph, `-Debug` affiche le détail de **chaque requête HTTP** envoyée à l'API : un outil précieux pour comprendre ce que fait réellement une cmdlet `*-Mg*`.

!!!warning Les préférences ne traversent pas les modules
`-Debug` sur une fonction ne fait que passer `$DebugPreference` à `Continue` **dans sa portée**. Les cmdlets `*-Mg*` sont exposées par un module, qui lit ses propres variables de préférence : elles **n'héritent pas** du `-Debug` de votre fonction. De plus, le SDK Graph n'affiche les requêtes HTTP que si `-Debug` est **explicitement passé** à la cmdlet.

Il faut donc transmettre le paramètre explicitement, ici à l'aide d'un splat conditionnel.
!!!

+++ :icon-code: Code

```powershell #12,13,27,28
function Get-EntraUserStatus
{
    [CmdletBinding()]
    param (
        [string[]]$UserPrincipalName
    )
    begin
    {
        Write-Verbose "Start $($MyInvocation.MyCommand)"

        # Transmet -Debug aux cmdlets Graph uniquement s'il a été passé à la fonction
        $GraphCommon = @{}
        if ($PSBoundParameters.ContainsKey('Debug')) { $GraphCommon['Debug'] = $true }
    }
    process
    {
        foreach ($User in $UserPrincipalName)
        {
            Write-Verbose "Querying $User"

            $Params = @{
                UserId   = $User
                Property = 'DisplayName', 'UserPrincipalName', 'AccountEnabled', 'Department', 'CreatedDateTime'
            }
            Write-Debug "[$User] Properties : $($Params.Property -join ', ')"

            $EntraUser = Get-MgUser @Params @GraphCommon
            $Licenses  = Get-MgUserLicenseDetail -UserId $User @GraphCommon

            [PSCustomObject]@{
                DisplayName       = $EntraUser.DisplayName
                UserPrincipalName = $EntraUser.UserPrincipalName
                Enabled           = $EntraUser.AccountEnabled
                Department        = $EntraUser.Department
                Created           = $EntraUser.CreatedDateTime
                Licenses          = $Licenses.SkuPartNumber -join ', '
            }
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
ﲵ Get-EntraUserStatus -UserPrincipalName lskywalker@SynapsysTest.onmicrosoft.com -Verbose
VERBOSE: Start Get-EntraUserStatus
VERBOSE: Querying lskywalker@SynapsysTest.onmicrosoft.com

DisplayName       : Luke Skywalker
UserPrincipalName : lskywalker@SynapsysTest.onmicrosoft.com
Enabled           : True
Department        : Jedi
Created           : 02/10/2026 07:30:12
Licenses          : DEVELOPERPACK_E5

VERBOSE: End Get-EntraUserStatus
```

+++ :icon-note: Run with Debug

```txt
ﲵ Get-EntraUserStatus -UserPrincipalName lskywalker@SynapsysTest.onmicrosoft.com -Debug
DEBUG: [lskywalker@SynapsysTest.onmicrosoft.com] Properties : DisplayName, UserPrincipalName, AccountEnabled, Department, CreatedDateTime
DEBUG: ============================ HTTP REQUEST ============================
HTTP Method:
GET
Absolute Uri:
https://graph.microsoft.com/v1.0/users/lskywalker@SynapsysTest.onmicrosoft.com?$select=DisplayName,UserPrincipalName,AccountEnabled,Department,CreatedDateTime
...
DEBUG: ============================ HTTP RESPONSE ============================
Status Code:
OK
...
```

+++

!!!
On peut désactiver la sortie Verbose ou Debug d'une commande en désactivant le paramètre de manière explicite : `Get-MgUser @Params -Debug:$false`
!!!

## Warning Output

[!badge target="blank" text="Write-Warning"](https://go.microsoft.com/fwlink/?LinkID=2097044) fonctionne comme les commandes précédentes, à la différence que les messages de type Warning sont activés par défaut.

+++ :icon-code: Code

```powershell #19,24,30
function Get-EntraUserStatus
{
    [CmdletBinding()]
    param (
        [string[]]$UserPrincipalName
    )
    begin
    {
        Write-Verbose "Start $($MyInvocation.MyCommand)"
    }
    process
    {
        foreach ($User in $UserPrincipalName)
        {
            $EntraUser = Get-MgUser -Filter "userPrincipalName eq '$User'" -Property Id, UserPrincipalName, AccountEnabled

            if (-not $EntraUser)
            {
                Write-Warning "$User not found in Entra ID. Skip !"
                continue
            }
            if (-not $EntraUser.AccountEnabled)
            {
                Write-Warning "$User is disabled."
            }

            $Licenses = Get-MgUserLicenseDetail -UserId $EntraUser.Id
            if (-not $Licenses)
            {
                Write-Warning "$User has no license assigned."
            }

            [PSCustomObject]@{
                UserPrincipalName = $EntraUser.UserPrincipalName
                Enabled           = $EntraUser.AccountEnabled
                Licenses          = $Licenses.SkuPartNumber -join ', '
            }
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
ﲵ Get-EntraUserStatus -UserPrincipalName lskywalker@SynapsysTest.onmicrosoft.com,lorgana@SynapsysTest.onmicrosoft.com,hsolo@SynapsysTest.onmicrosoft.com -Verbose
VERBOSE: Start Get-EntraUserStatus

UserPrincipalName                       Enabled Licenses
-----------------                       ------- --------
lskywalker@SynapsysTest.onmicrosoft.com    True DEVELOPERPACK_E5
WARNING: lorgana@SynapsysTest.onmicrosoft.com is disabled.
WARNING: lorgana@SynapsysTest.onmicrosoft.com has no license assigned.
lorgana@SynapsysTest.onmicrosoft.com      False
WARNING: hsolo@SynapsysTest.onmicrosoft.com not found in Entra ID. Skip !
VERBOSE: End Get-EntraUserStatus
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

### Output Preference

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
