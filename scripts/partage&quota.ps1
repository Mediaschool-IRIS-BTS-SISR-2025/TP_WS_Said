Write-Host "Creation du partage et configuration FSRM..." -ForegroundColor Yellow

# Vérifier et installer FSRM si nécessaire
if (-not (Get-WindowsFeature FS-Resource-Manager).Installed) {
    Write-Host "Installation de FSRM..." -ForegroundColor Cyan
    Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools
}

# Attendre que FSRM soit prêt
Start-Sleep -Seconds 5

# Déterminer le lecteur à utiliser (D: ou C:)
$drive = if (Test-Path "D:\") { "D:" } else { "C:" }
$baseRoot = "$drive\Donnees"
$basePath = "$baseRoot\Homes"

# Créer les dossiers
New-Item -Path $baseRoot -ItemType Directory -Force | Out-Null
New-Item -Path $basePath -ItemType Directory -Force | Out-Null

# Créer le partage Homes
if (-not (Get-SmbShare -Name "Homes" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "Homes" -Path $basePath -FullAccess "Everyone" | Out-Null
    Write-Host "Partage 'Homes' cree : $basePath" -ForegroundColor Green
}

# Créer le seuil à 85% (sans -Action pour éviter les erreurs)
try {
    $threshold85 = New-FsrmQuotaThreshold -Percentage 85
    Write-Host "Seuil quota a 85% cree" -ForegroundColor Green
} catch {
    Write-Host "Erreur creation seuil: $_" -ForegroundColor Yellow
    $threshold85 = $null
}

# Template pour les Élèves (1 Go)
try {
    if (-not (Get-FsrmQuotaTemplate -Name "Template-Eleves (1 Go)" -ErrorAction SilentlyContinue)) {
        if ($threshold85) {
            New-FsrmQuotaTemplate -Name "Template-Eleves (1 Go)" -Size 1GB -Threshold $threshold85 | Out-Null
        } else {
            New-FsrmQuotaTemplate -Name "Template-Eleves (1 Go)" -Size 1GB | Out-Null
        }
        Write-Host "Template quota Eleves (1 Go) cree" -ForegroundColor Green
    }
} catch {
    Write-Host "Erreur template Eleves: $_" -ForegroundColor Yellow
}

# Template pour les Profs (5 Go)
try {
    if (-not (Get-FsrmQuotaTemplate -Name "Template-Profs (5 Go)" -ErrorAction SilentlyContinue)) {
        if ($threshold85) {
            New-FsrmQuotaTemplate -Name "Template-Profs (5 Go)" -Size 5GB -Threshold $threshold85 | Out-Null
        } else {
            New-FsrmQuotaTemplate -Name "Template-Profs (5 Go)" -Size 5GB | Out-Null
        }
        Write-Host "Template quota Profs (5 Go) cree" -ForegroundColor Green
    }
} catch {
    Write-Host "Erreur template Profs: $_" -ForegroundColor Yellow
}

# Template pour les Admin (10 Go)
try {
    if (-not (Get-FsrmQuotaTemplate -Name "Template-Admin (10 Go)" -ErrorAction SilentlyContinue)) {
        if ($threshold85) {
            New-FsrmQuotaTemplate -Name "Template-Admin (10 Go)" -Size 10GB -Threshold $threshold85 | Out-Null
        } else {
            New-FsrmQuotaTemplate -Name "Template-Admin (10 Go)" -Size 10GB | Out-Null
        }
        Write-Host "Template quota Admin (10 Go) cree" -ForegroundColor Green
    }
} catch {
    Write-Host "Erreur template Admin: $_" -ForegroundColor Yellow
}

# Appliquer l'auto-quota sur le dossier Homes
try {
    if (-not (Get-FsrmAutoQuota -Path $basePath -ErrorAction SilentlyContinue)) {
        New-FsrmAutoQuota -Path $basePath -Template "Template-Eleves (1 Go)" | Out-Null
        Write-Host "Auto-quota applique sur $basePath" -ForegroundColor Green
    }
} catch {
    Write-Host "Erreur auto-quota: $_" -ForegroundColor Yellow
}

Write-Host "Partage et quotas FSRM configures avec succes." -ForegroundColor Green
