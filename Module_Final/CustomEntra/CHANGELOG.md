# Changelog

## [1.1.0] - 2026-10-06
### Added
- `Remove-CustomEntraUser` : suppression des comptes de test (SupportsShouldProcess, ConfirmImpact High).

## [1.0.1] - 2026-10-06
### Changed
- Extraction de la génération du mot de passe dans la fonction privée `New-CustomPassword`.

## [1.0.0] - 2026-10-06
### Added
- `New-CustomEntraUser` : création d'utilisateurs depuis le pipeline.
- `Get-CustomEntraUserReport` : rapport d'activité de connexion.
- Fonction privée `Assert-CustomGraphConnection` : contrôle de la session Graph et des permissions.
