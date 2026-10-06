# Tester son code avec Pester

[Pester](https://pester.dev) est le framework de tests de PowerShell. Il permet de vérifier automatiquement qu'une fonction fait ce qu'on attend d'elle, **avant** de la publier, et de détecter une régression à chaque modification.

## Installation

Windows est livré avec une ancienne version de Pester (3.4). On installe la version 5 :

```powershell
Install-Module -Name Pester -Scope CurrentUser -Force -SkipPublisherCheck
Get-Module -Name Pester -ListAvailable
```

## Le vocabulaire

{.compact}
Mot-clé | Rôle
--- | ---
`Describe` | Regroupe les tests d'une fonction (ou d'un sujet)
`It` | Un test : une vérification précise
`Should` | L'assertion : `Should -Be`, `-Contain`, `-HaveCount`, `-Throw`...
`BeforeAll` | Code exécuté une fois avant les tests du bloc (import, préparation des données)
`Mock` | Remplace une commande par un faux, pour tester **sans** dépendance externe
`Should -Invoke` | Vérifie qu'une commande « mockée » a été appelée (ou non), et combien de fois

## Exemple : tester le module CustomEntra

Nos fonctions appellent Microsoft Graph. Un test ne doit **jamais** dépendre d'un vrai tenant : grâce à `Mock`, on remplace `Get-MgUser`, `New-MgUser`... par des fausses commandes qui renvoient des données maîtrisées.

Le fichier de tests se place dans le dossier `Tests` du module (voir [Structurer un module](../modules/structure.md)) et son nom se termine **obligatoirement** par `.Tests.ps1` :

```
CustomEntra\
├── CustomEntra.psd1
├── CustomEntra.psm1
├── Public\
├── Private\
└── Tests\
    └── CustomEntra.Tests.ps1
```

```powershell CustomEntra\Tests\CustomEntra.Tests.ps1
BeforeAll {
    Import-Module "$PSScriptRoot\..\CustomEntra.psd1" -Force
}

Describe 'Module CustomEntra' {

    It 'exporte uniquement les fonctions publiques' {
        $Commands = (Get-Command -Module CustomEntra).Name

        $Commands | Should -Contain 'New-CustomEntraUser'
        $Commands | Should -Contain 'Get-CustomEntraUserReport'
        $Commands | Should -Not -Contain 'Assert-CustomGraphConnection'
    }
}

Describe 'New-CustomEntraUser' {

    BeforeAll {
        # Pas de vraie connexion Graph : on remplace le helper et New-MgUser par des mocks
        Mock -ModuleName CustomEntra -CommandName Assert-CustomGraphConnection -MockWith { }
        Mock -ModuleName CustomEntra -CommandName New-MgUser -MockWith {
            [PSCustomObject]@{ Id = '1'; DisplayName = $DisplayName; UserPrincipalName = $UserPrincipalName }
        }

        $User = [PSCustomObject]@{
            DisplayName       = 'Enola Meyer'
            UserPrincipalName = 'enola.meyer@contoso.com'
            MailNickname      = 'enola.meyer'
        }
    }

    It "crée l'utilisateur reçu par le pipeline" {
        $Result = $User | New-CustomEntraUser

        $Result.UserPrincipalName | Should -Be 'enola.meyer@contoso.com'
        Should -Invoke -ModuleName CustomEntra -CommandName New-MgUser -Times 1 -Exactly
    }

    It 'ne crée rien avec -WhatIf' {
        $User | New-CustomEntraUser -WhatIf

        Should -Invoke -ModuleName CustomEntra -CommandName New-MgUser -Times 0 -Exactly
    }
}

Describe 'Get-CustomEntraUserReport' {

    BeforeAll {
        Mock -ModuleName CustomEntra -CommandName Assert-CustomGraphConnection -MockWith { }
        Mock -ModuleName CustomEntra -CommandName Get-MgSubscribedSku -MockWith {
            [PSCustomObject]@{ SkuId = 'sku-e5'; SkuPartNumber = 'SPE_E5' }
        }
        Mock -ModuleName CustomEntra -CommandName Get-MgUser -MockWith {
            [PSCustomObject]@{
                UserPrincipalName = 'actif@contoso.com'
                AssignedLicenses  = @([PSCustomObject]@{ SkuId = 'sku-e5' })
                SignInActivity    = [PSCustomObject]@{ LastSignInDateTime = (Get-Date).AddDays(-2) }
            }
            [PSCustomObject]@{
                UserPrincipalName = 'inactif@contoso.com'
                SignInActivity    = [PSCustomObject]@{ LastSignInDateTime = (Get-Date).AddDays(-200) }
            }
            [PSCustomObject]@{
                UserPrincipalName = 'jamais@contoso.com'
                SignInActivity    = $null
            }
        }

        $Report = Get-CustomEntraUserReport -InactiveDays 90
    }

    It 'renvoie un objet par utilisateur' {
        $Report | Should -HaveCount 3
    }

    It 'donne le statut <Expected> à <Upn>' -ForEach @(
        @{ Upn = 'actif@contoso.com';   Expected = 'Active' }
        @{ Upn = 'inactif@contoso.com'; Expected = 'Inactive' }
        @{ Upn = 'jamais@contoso.com';  Expected = 'Never' }
    ) {
        ($Report | Where-Object -Property UserPrincipalName -EQ $Upn).Status | Should -Be $Expected
    }

    It 'traduit les SkuId en noms de licence' {
        ($Report | Where-Object -Property UserPrincipalName -EQ 'actif@contoso.com').Licenses | Should -Be 'SPE_E5'
    }
}
```

!!!
`-ModuleName CustomEntra` est indispensable : il place le mock **à l'intérieur** du module, là où les fonctions appellent `Get-MgUser`. C'est aussi ce qui permet de mocker la fonction privée `Assert-CustomGraphConnection`.
!!!

## Lancer les tests

```powershell
Invoke-Pester -Path .\CustomEntra\Tests -Output Detailed
```

```txt
Describing Module CustomEntra
  [+] exporte uniquement les fonctions publiques
Describing New-CustomEntraUser
  [+] crée l'utilisateur reçu par le pipeline
  [+] ne crée rien avec -WhatIf
Describing Get-CustomEntraUserReport
  [+] renvoie un objet par utilisateur
  [+] donne le statut Active à actif@contoso.com
  [+] donne le statut Inactive à inactif@contoso.com
  [+] donne le statut Never à jamais@contoso.com
  [+] traduit les SkuId en noms de licence
Tests Passed: 8, Failed: 0, Skipped: 0
```

!!!warning
Pester ne peut mocker qu'une commande **existante** : les modules Microsoft Graph doivent être installés sur le poste qui exécute les tests, même si aucune connexion n'est ouverte.
!!!

!!! À essayer
Dans `Get-CustomEntraUserReport`, remplacez le statut `'Never'` par `'Jamais'`, puis relancez les tests : lequel échoue, et que vous indique Pester ?
!!!
