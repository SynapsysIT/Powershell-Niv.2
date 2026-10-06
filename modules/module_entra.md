# Atelier : regrouper ses fonctions dans un module

**Objectif** : regrouper les fonctions des ateliers [Create Users](../workshop/new_entra_users.md) et [Get Users](../workshop/get_entra_users.md) dans un module `CustomEntra` versionné, doté d'une fonction **privée** partagée, puis le publier dans un dépôt interne.

!!!
`Get-RandomUser` (atelier [API Random User](../workshop/random_users.md)) **ne fait pas partie du module** : c'est un outil de labo qui génère des données de test, pas une fonction destinée à la production.
!!!

## Étape 1 - Structure

1. Créer l'arborescence d'un module `CustomEntra` avec les dossiers `Public` et `Private`.
2. Placer chaque fonction publique dans son propre fichier :
   - `Public\New-CustomEntraUser.ps1`
   - `Public\Get-CustomEntraUserReport.ps1`
3. Écrire le loader `CustomEntra.psm1`.

## Étape 2 - La fonction privée

Les deux fonctions publiques ont le même prérequis : une session Microsoft Graph ouverte, avec les bonnes permissions. Sans elle, l'utilisateur obtient une erreur Graph peu lisible... **au milieu du traitement**.

Coder une fonction **privée** `Assert-CustomGraphConnection` dans `Private\Assert-CustomGraphConnection.ps1` qui :

1. Reçoit la liste des permissions nécessaires (`-RequiredScope`).
2. Lève une erreur explicite (`throw`) si **aucune session Graph** n'est ouverte.
3. Lève une erreur explicite listant les **permissions manquantes**.
4. Accepte des **alternatives** pour une même permission : `'User.Read.All|User.ReadWrite.All'` signifie que l'une ou l'autre suffit.

Appeler ensuite cette fonction dans le bloc `begin` des deux fonctions publiques :

{.compact}
Fonction | Permissions requises
--- | ---
`New-CustomEntraUser` | `User.ReadWrite.All`
`Get-CustomEntraUserReport` | `User.Read.All`, `AuditLog.Read.All`, `LicenseAssignment.Read.All`

!!! Coup de pouce
`Get-MgContext` renvoie la session Graph en cours (ou `$null` si aucune session n'est ouverte). Sa propriété `Scopes` contient la liste des permissions du jeton.
!!!

## Étape 3 - Manifeste

1. Générer `CustomEntra.psd1` avec `New-ModuleManifest` en version `1.0.0`.
2. Déclarer les modules Graph nécessaires dans `RequiredModules` : `Microsoft.Graph.Authentication`, `Microsoft.Graph.Users` et `Microsoft.Graph.Identity.DirectoryManagement` (pour `Get-MgSubscribedSku`).
3. Vérifier le manifeste avec `Test-ModuleManifest`.
4. Importer le module et valider que :
   - seules `New-CustomEntraUser` et `Get-CustomEntraUserReport` sont visibles ;
   - `Assert-CustomGraphConnection` n'est **pas** accessible depuis la session ;
   - sans `Connect-MgGraph`, `Get-CustomEntraUserReport` renvoie votre message d'erreur explicite.

## Étape 4 - Publication

1. Créer un dossier `C:\PSRepo` et l'enregistrer comme dépôt `LocalRepo`.
2. Publier `CustomEntra` en `1.0.0`.
3. Installer le module depuis le dépôt, ouvrir une **nouvelle** console et enchaîner les ateliers **sans** `Import-Module` :

```powershell
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential -NoWelcome
Get-RandomUser -Count 5 -Domain 'SynapsysTest.onmicrosoft.com' | New-CustomEntraUser | Get-CustomEntraUserReport
```

## Étape 5 - Nouvelle version

1. Extraire la génération du mot de passe de `New-CustomEntraUser` dans une seconde fonction **privée** `New-CustomPassword` (paramètre `-Length`, 16 par défaut).
2. Déterminer le bon numéro de version selon SemVer et mettre à jour le manifeste.
3. Publier, puis mettre à jour le module installé.
4. Vérifier que les **deux** versions sont présentes dans le dépôt.

!!!warning Contraintes
- Un fichier par fonction, nommé comme la fonction.
- `FunctionsToExport` doit être explicite.
- Aucune valeur en dur liée à votre tenant (domaine, Tenant ID, secret...) dans le module.
!!!
