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

Describe 'Remove-CustomEntraUser' {

    BeforeAll {
        Mock -ModuleName CustomEntra -CommandName Assert-CustomGraphConnection -MockWith { }
        Mock -ModuleName CustomEntra -CommandName Remove-MgUser -MockWith { }

        $User = [PSCustomObject]@{ UserPrincipalName = 'enola.meyer@contoso.com' }
    }

    It 'ne supprime rien avec -WhatIf' {
        $User | Remove-CustomEntraUser -WhatIf

        Should -Invoke -ModuleName CustomEntra -CommandName Remove-MgUser -Times 0 -Exactly
    }

    It 'supprime sans confirmation avec -Confirm:$false' {
        $User | Remove-CustomEntraUser -Confirm:$false

        Should -Invoke -ModuleName CustomEntra -CommandName Remove-MgUser -Times 1 -Exactly
    }
}
