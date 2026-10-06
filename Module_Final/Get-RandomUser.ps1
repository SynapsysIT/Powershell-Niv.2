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
