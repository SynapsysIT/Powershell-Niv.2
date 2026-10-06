# Chargement des fonctions privées puis publiques
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
$Public  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue)

foreach ($File in @($Private + $Public))
{
    try
    {
        . $File.FullName
    }
    catch
    {
        Write-Error "Échec du chargement de $($File.FullName) : $_"
    }
}

# Seules les fonctions du dossier Public sont exposées
Export-ModuleMember -Function $Public.BaseName
