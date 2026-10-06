# Corrigé : API Random User

Énoncé : [API Random User](random_users.md)

```powershell
function Get-RandomUser
{
    [CmdletBinding()]
    param (
        [ValidateRange(1, 100)]
        [int]$Count = 10,

        [Parameter(Mandatory)]
        [string]$Domain
    )

    $Response = Invoke-RestMethod -Uri "https://randomuser.me/api/?results=$Count&nat=FR" -Method Get

    foreach ($User in $Response.results)
    {
        # Les UPN n'acceptent ni accents, ni espaces, ni apostrophes
        $Nickname = "$($User.name.first).$($User.name.last)".Normalize([Text.NormalizationForm]::FormD)
        $Nickname = ($Nickname -replace '\p{Mn}', '' -replace "[^a-zA-Z0-9.\-]", '').ToLower()

        [PSCustomObject]@{
            DisplayName       = "$($User.name.first) $($User.name.last)"
            GivenName         = $User.name.first
            Surname           = $User.name.last
            MailNickname      = $Nickname
            UserPrincipalName = "$Nickname@$Domain"
            UsageLocation     = $User.nat
            StreetAddress     = "$($User.location.street.number) $($User.location.street.name)"
            PostalCode        = [string]$User.location.postcode
            City              = $User.location.city
            Country           = $User.location.country
            MobilePhone       = $User.cell
        }
    }
}
```

```txt
ﲵ Get-RandomUser -Count 2 -Domain 'SynapsysTest.onmicrosoft.com'

DisplayName       : Enola Meyer
GivenName         : Enola
Surname           : Meyer
MailNickname      : enola.meyer
UserPrincipalName : enola.meyer@SynapsysTest.onmicrosoft.com
UsageLocation     : FR
StreetAddress     : 8342 Avenue Jean-Jaurès
PostalCode        : 18137
City              : Montpellier
Country           : France
MobilePhone       : 06-69-61-79-12

DisplayName       : Jérôme Le Gall-Dupré
GivenName         : Jérôme
Surname           : Le Gall-Dupré
MailNickname      : jerome.legall-dupre
UserPrincipalName : jerome.legall-dupre@SynapsysTest.onmicrosoft.com
UsageLocation     : FR
StreetAddress     : 12 Rue de l'Église
PostalCode        : 42000
City              : Saint-Étienne
Country           : France
MobilePhone       : 07-12-34-56-78
```
