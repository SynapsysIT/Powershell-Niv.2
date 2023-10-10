---
icon: code
order: 8
title: Mise en forme
---

# Beautify and Simplify your code

Il existe plusieurs méthodes à connaitre pour simplifier et faciliter la lisibilité de votre code.

Rappelez vous de l'existence des ces méthodes avant de vous lancer dans des bouts de code alambiqués.

## Splatting

Le *splatting* est une technique consistant à définir les paramètres d'une commande sous forme de `[hashtable]`.

Le principal avantage de cette technique est qu'elle permet de rendre plus lisible certaines commandes qui peuvent devenir trés longue.

Prenons l'exemple d'une commande [!badge target="blank" text="New-ADUser"](https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser?view=windowsserver2022-ps) standard :

```powershell
New-ADUser -DisplayName "Luke Skywalker" -Name "SKYWALKER" -SamAccountName "lskywalker" -UserPrincipalName "lskywalker@starwars.com" -Surname "Skywalker" -GivenName "Luke" -Path "OU=Users,DC=StarWars,DC=com" -AccountPassword $("Azerty123" | ConvertTo-SecureString -AsPlainText -Force) -Enabled $true
```

En utilsant la méthode du splatting, on regroupe les paramètres dans une hashtable que nous appelerons ensuite dans la commande avec le préfixe [!badge variant="danger" target="blank" text="@"]

```powershell #13
$NewADUserParam = @{
        DisplayName       = "Luke Skywalker"
        Name              = "SKYWALKER"
        SamAccountName    = "lskywalker"
        UserPrincipalName = "lskywalker@starwars.com"
        Surname           = "Skywalker"
        GivenName         = "Luke"
        Path              = "OU=Users,DC=StarWars,DC=com"
        AccountPassword   = $("Azerty123" | ConvertTo-SecureString -AsPlainText -Force)
        Enabled           = $true
    }

New-ADUSer @NewADUserParams
```

Le deuxième avantage est de pouvoir adapter les paramètres en fonction de certaines conditions sans avoir à répéter plusieurs fois la commande dans notre code:

```powershell
if ($Credentials) # Si des credentials ont étés fournis
{
    $NewADUserParams["Credential"] = $Credentials
}

New-ADUSer @NewADUserParams
```

```powershell
if ($SamAccountName -like "ADM-*")
{
    $NewADUserParams["Path"] = "OU=Admins,DC=StarWars,DC=com"
}

New-ADUSer @NewADUserParams
```

Plusieurs *"splat"* peuvent être combinés:

```powershell
$Common = @{
    SubnetMask  = '255.255.255.0'
    LeaseDuration = (New-TimeSpan -Days 8)
    Type = "Both"
}

$DHCPScope = @{
    Name        = 'TestNetwork'
    StartRange  = '10.0.0.2'
    EndRange    = '10.0.0.254'
    Description = 'Network for testlab A'
}

Add-DhcpServerv4Scope @DHCPScope @Common
```

## Format Operator

Les Format Operators permettent de simplifier des manipulations sur des chaînes qui pourrait néccéssiter plusieurs ligne de code:

#### Arrondir une decimal à X chiffre aprés la virgule

+++ :icon-code: Code

```powershell
 "{0:n3}" -f 123.45678
```

+++ :icon-note: Output

```txt
123,46
```

+++

#### Modifier l'affichage d'une suite de chiffre selon un template

+++ :icon-code: Code

```powershell
"{0:0# ## ## ## ##}" -f 0611223344
```

+++ :icon-note: Output

```txt
06 11 22 33 44
```

+++

#### Créer une liste incrémentielle

+++ :icon-code: Code

```powershell
1..10 | ForEach-Object { 'File{0:d3}' -f $_ }
```

+++ :icon-note: Output

```txt
File001
File002
File003
File004
File005
File006
File007
File008
File009
File010
```

+++

#### Afficher un chiffre en pourcentage

+++ :icon-code: Code

```powershell
"{0:p0}" -f 0.5
```

+++ :icon-note: Output

```txt
50%
```

+++

#### Afficher un nombre sur X digits

+++ :icon-code: Code

```powershell
"{0:d5}" -f 123
```

+++ :icon-note: Output

```txt
00123
```

+++

Voir plus : [!badge target="blank" text="Formats Operators"](https://ss64.com/ps/syntax-f-operator.html)

## Type Accelerators

Les Type Accelerators sont des méthodes de classe .NET. Ils peuvent aussi faciliter certaines opérations et contrôles

#### Vérifier la validité d'une adresse IP ou d'une URL

+++ :icon-code: Code

```powershell
"192.168.1.255" -as [System.Net.IPAddress] # Ne renverra rien si l'adresse IP n'est pas valide
```

+++ :icon-note: Output

```txt
00123
```

+++

#### Créer un objet de type version

+++ :icon-code: Code

```powershell
[version]"1.0.2"
```

+++ :icon-note: Output

```txt
Major  Minor  Build  Revision
-----  -----  -----  --------
1      0      2      -1
```

+++

## RegEx

Les expression régulières peuvent faire peur en apparence mais sont trés efficaces pour extraire une information d'une chaîne de caractère:

+++ :icon-code: Code

```powershell
$TVShowPattern = "^(?<titre>.*?)\.S(?<saison>\d+)\.?E(?<episode>\d+)\.(?<reste>.*)$"
"Westworld.S03E01.VOSTFR.1080p.AMZN.WEB-DL.DDP5.1.H.264-MYSTERiON" -match $TVShowPattern

[PSCustomObject]@{
    TVShow  = $Matches.titre
    Saison  = $Matches.saison
    Episode = $Matches.episode
}

```

+++ :icon-note: Output

```txt
TVShow    Saison Episode
------    ------ -------
Westworld 03     01
```

+++

[!badge target="blank" text="Outils Conception RegEx"](https://regexr.com/)
