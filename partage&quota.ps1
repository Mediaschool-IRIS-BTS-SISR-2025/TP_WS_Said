# partage&quota.ps1
Write-Host "Création du partage et configuration FSRM..." -ForegroundColor Yellow

# Installation du rôle FSRM si nécessaire
if (-not (Get-WindowsFeature FS-Resource-Manager).Installed) {
    Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools
}

# Création du dossier de base
$basePath = "D:\Donnees\Homes"
if (-not (Test-Path "D:\Donnees")) {
    New-Item -Path "D:\Donnees" -ItemType Directory | Out-Null
}
if (-not (Test-Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory | Out-Null
}

# Partage SMB
if (-not (Get-SmbShare -Name "Homes" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "Homes" -Path $basePath -FullAccess "Everyone"
}

# Création des modèles de quotas FSRM
if (-not (Get-FsrmQuotaTemplate -Name "Template-Eleves (1 Go)" -ErrorAction SilentlyContinue)) {
    New-FsrmQuotaTemplate -Name "Template-Eleves (1 Go)" -Limit 1GB -Threshold 85 | Out-Null
}
if (-not (Get-FsrmQuotaTemplate -Name "Template-Profs (5 Go)" -ErrorAction SilentlyContinue)) {
    New-FsrmQuotaTemplate -Name "Template-Profs (5 Go)" -Limit 5GB -Threshold 85 | Out-Null
}
if (-not (Get-FsrmQuotaTemplate -Name "Template-Admin (10 Go)" -ErrorAction SilentlyContinue)) {
    New-FsrmQuotaTemplate -Name "Template-Admin (10 Go)" -Limit 10GB -Threshold 85 | Out-Null
}

# Application d'un quota auto-généré sur le dossier Homes (base Élèves)
if (-not (Get-FsrmAutoQuota -Path $basePath -ErrorAction SilentlyContinue)) {
    New-FsrmAutoQuota -Path $basePath -Template "Template-Eleves (1 Go)" -UpdateMatchingQuotas | Out-Null
}

Write-Host "Partage et quotas FSRM configurés." -ForegroundColor Green
