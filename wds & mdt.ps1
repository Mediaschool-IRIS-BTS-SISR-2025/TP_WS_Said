# wds & mdt.ps1

# --- PARTIE MANUELLE ---
# Avant d'exécuter ce script, installez :
#  - Windows ADK
#  - WinPE Addon
#  - Microsoft Deployment Toolkit (MDT)
#  - Le rôle WDS sur ce serveur

Write-Host "Initialisation de WDS..." -ForegroundColor Yellow
Initialize-WdsServer -WdsClientNBP "\Boot\x64\wdsnbp.com" -NewDC

# Import du module MDT
Write-Host "Importation du module MDT..." -ForegroundColor Yellow
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\Microsoft.Deployment.Toolkit.psd1"

# 17. Création du Deployment Share MDT
$mdtPath = "D:\MDT"
if (-not (Test-Path $mdtPath)) {
    New-Item -Path $mdtPath -ItemType Directory | Out-Null
}

Write-Host "Création du Deployment Share MDT..." -ForegroundColor Yellow
New-MDTDeploymentShare -Name "MDTShare" -Path $mdtPath -Description "MDT Deployment Share"

# 18. Importation de l'OS (suppose l'ISO sur E:)
Write-Host "Importation de l'OS (E:\sources\install.wim)..." -ForegroundColor Yellow
Import-MDTOperatingSystem -Path "$mdtPath\Operating Systems" -SourcePath "E:\sources\install.wim" -Name "Windows 11 Pro (Base)"

# 19. Création de la Task Sequence
Write-Host "Création de la Task Sequence 'Deploy-W11-Standard'..." -ForegroundColor Yellow
New-MDTTaskSequence -Path "$mdtPath\Task Sequences" -Name "Deploy-W11-Standard" -Template "Client.xml" -OSName "Windows 11 Pro (Base)"

# 20. Mise à jour du Share (génère les images de boot)
Write-Host "Mise à jour du Deployment Share... (Patientez, c'est long)" -ForegroundColor Yellow
Update-MDTDeploymentShare -Path $mdtPath

# 21. Ajout de l'image de boot MDT à WDS
Write-Host "Ajout de l'image de boot à WDS..." -ForegroundColor Yellow
Import-WdsBootImage -Path "$mdtPath\Boot\LiteTouchPE_x64.wim" -Name "MDT LiteTouch x64"

Write-Host "Configuration MDT/WDS terminée." -ForegroundColor Green
