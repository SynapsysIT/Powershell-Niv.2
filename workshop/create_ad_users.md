---
icon: beaker
order: 8
title: Create AD Users
---

1. Cloner le resository sur votre machine:
  
```bash
git clone https://github.com/SynapsysIT/Powershell-Niv.2-Resources.git
```

1. A partir d'un fichier du répertoire `"\Workshop\Generate AD Users\"` , créer une fonction qui depuis ce fichier en entrée, pourra générer des utilisateurs dans le domaine.

Le champ "Service" du fichier définira l'OU cible qui devras être créee si néccéssaire.

!!!warning
Cette fonction devra recevoir en paramètre un chemin d'accés vers le fichier (à minima)
!!!

### Functions Utiles

```powershell 
function Create-Password {
    param (
        [int]$Length = 15
    )

        $MyRange += 65..90 #UpperCase
        $MyRange += 97..122 #LowerCase
        $MyRange += 48..57 #Numbers
        $MyRange += (33..47) + (58..64) + (91..96) + (123..126) #Specials Characters


($MyRange | Get-Random -Count $Length | % { [char]$_ }) -join ''

}
```
