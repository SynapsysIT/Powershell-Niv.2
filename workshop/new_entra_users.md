# Atelier : créer des utilisateurs Entra ID depuis le pipeline

**Objectif** : coder une fonction qui reçoit les objets produits par `Get-RandomUser` (atelier [API Random User](random_users.md)) **par le pipeline** et crée les utilisateurs correspondants dans Entra ID.

```powershell
Get-RandomUser -Count 10 -Domain 'SynapsysTest.onmicrosoft.com' | New-CustomEntraUser
```

!!! Coup de pouce
Pour qu'une propriété de l'objet reçu alimente automatiquement un paramètre, le paramètre doit porter **le même nom** que la propriété et être déclaré avec `ValueFromPipelineByPropertyName`. Le traitement se fait dans le bloc `process`, exécuté une fois par objet reçu.

Rappel des propriétés produites par `Get-RandomUser` : `DisplayName`, `GivenName`, `Surname`, `MailNickname`, `UserPrincipalName`, `UsageLocation`, `StreetAddress`, `PostalCode`, `City`, `Country`, `MobilePhone`.
!!!

## Consignes

Coder une fonction `New-CustomEntraUser` qui :

1. Accepte **chaque propriété produite par `Get-RandomUser`** comme paramètre, alimenté depuis le pipeline **par nom de propriété** (`ValueFromPipelineByPropertyName`).
2. Rend obligatoires `DisplayName`, `UserPrincipalName` et `MailNickname` (exigés par Entra ID).
3. Génère un mot de passe aléatoire et force son changement à la première connexion.
4. Crée l'utilisateur avec `New-MgUser`, puis renvoie son `Id`, son `DisplayName` et son `UserPrincipalName`.

!!!warning Contraintes
- Pas de `New-MgUser` avec 15 paramètres sur une ligne : utilisez le **splatting**.
- Une propriété absente ou vide ne doit pas être transmise à `New-MgUser`.
- **N'utilisez pas** le mot de passe fourni par l'API (`login.password`) : il ne respecte pas la politique de mots de passe d'Entra ID.
- Prérequis : être connecté à Graph avec la permission `User.ReadWrite.All`.
!!!

## Bonus

- Ajouter le support de `-WhatIf` / `-Confirm` (`SupportsShouldProcess`) pour tester le pipeline **sans rien créer**.
- Ignorer avec un `Write-Warning` un utilisateur dont l'UPN existe déjà dans le tenant.
- Écrire la commande qui supprime les utilisateurs créés pendant l'atelier.
