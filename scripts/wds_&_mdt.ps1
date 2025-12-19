Write-Host "Configuration WDS et MDT..." -ForegroundColor Yellow

$drive = if (Test-Path "D:\") { "D:" } else { "C:" }

# =============================
# WDS Initialization
# =============================
Write-Host "WDS: Verification de l'installation..." -ForegroundColor Cyan

if (-not (Get-WindowsFeature WDS).Installed) {
    Write-Host "WDS n'est pas installe. Installation..." -ForegroundColor Yellow
    Install-WindowsFeature -Name WDS -IncludeManagementTools
    Start-Sleep -Seconds 10
}

$remInst = "$drive\RemoteInstall"
if (-not (Test-Path $remInst)) {
    New-Item -Path $remInst -ItemType Directory -Force | Out-Null
}

Write-Host "WDS: Initialisation du serveur..." -ForegroundColor Yellow
try {
    # Initialiser WDS
    $wdsInit = & wdsutil /Initialize-Server /RemInst:$remInst 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "WDS initialise avec succes" -ForegroundColor Green
    } else {
        Write-Host "WDS deja initialise ou erreur mineure (continuation)" -ForegroundColor Yellow
    }
    
    # Configurer pour répondre à tous les clients
    & wdsutil /Set-Server /AnswerClients:All 2>&1 | Out-Null
    Write-Host "WDS configure pour repondre a tous les clients" -ForegroundColor Green
    
} catch {
    Write-Host "Erreur WDS: $_" -ForegroundColor Yellow
    Write-Host "WDS peut deja etre initialise" -ForegroundColor Cyan
}

# =============================
# MDT (optionnel)
# =============================
$mdtModule = "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

if (Test-Path $mdtModule) {
    Write-Host "MDT: Module detecte, configuration..." -ForegroundColor Yellow
    
    try {
        Import-Module $mdtModule -ErrorAction Stop
        
        $mdtPath = "$drive\DeploymentShare"
        if (-not (Test-Path $mdtPath)) {
            New-Item -Path $mdtPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer le Deployment Share
        if (-not (Test-Path "$mdtPath\Control")) {
            Write-Host "MDT: Creation du Deployment Share..." -ForegroundColor Cyan
            
            $shareName = "DeploymentShare$"
            $shareUNC = "\\SRV-FS1\$shareName"
            
            New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root $mdtPath -Description "MDT Deployment Share" | Out-Null
            
            # Créer le partage réseau
            if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
                New-SmbShare -Name $shareName -Path $mdtPath -FullAccess "Everyone" | Out-Null
            }
            
            Write-Host "Deployment Share cree" -ForegroundColor Green
        } else {
            Write-Host "Deployment Share deja present" -ForegroundColor Green
        }
        
        # Mise à jour du share (création des images de boot)
        Write-Host "MDT: Mise a jour du Deployment Share (peut prendre plusieurs minutes)..." -ForegroundColor Yellow
        try {
            Update-MDTDeploymentShare -Path "DS001:" -Verbose
            Write-Host "Deployment Share mis a jour" -ForegroundColor Green
        } catch {
            Write-Host "Erreur mise a jour MDT: $_" -ForegroundColor Yellow
        }
        
        # Vérifier et importer l'image de boot dans WDS
        $bootWim = "$mdtPath\Boot\LiteTouchPE_x64.wim"
        if (Test-Path $bootWim) {
            Write-Host "WDS: Import de l'image de boot MDT..." -ForegroundColor Cyan
            try {
                # Vérifier si l'image existe déjà
                $existingImage = Get-WdsBootImage -ImageName "MDT LiteTouch x64" -ErrorAction SilentlyContinue
                
                if (-not $existingImage) {
                    Import-WdsBootImage -Path $bootWim -NewImageName "MDT LiteTouch x64" -NewDescription "MDT Deployment Boot Image" -ErrorAction Stop
                    Write-Host "Image de boot importee dans WDS" -ForegroundColor Green
                } else {
                    Write-Host "Image de boot deja presente dans WDS" -ForegroundColor Green
                }
            } catch {
                Write-Host "Erreur import boot image: $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "ATTENTION: LiteTouchPE_x64.wim introuvable" -ForegroundColor Yellow
            Write-Host "Verifiez que ADK et WinPE sont installes, puis relancez Update-MDTDeploymentShare" -ForegroundColor Cyan
        }
        
        Write-Host "MDT configuration terminee" -ForegroundColor Green
        
    } catch {
        Write-Host "Erreur configuration MDT: $_" -ForegroundColor Yellow
        Write-Host "MDT necessite ADK et WinPE installes" -ForegroundColor Cyan
    }
} else {
    Write-Host "MDT: Non installe" -ForegroundColor Yellow
    Write-Host "Pour utiliser MDT:" -ForegroundColor Cyan
    Write-Host "  1. Installer Windows ADK" -ForegroundColor Cyan
    Write-Host "  2. Installer Windows PE add-on for ADK" -ForegroundColor Cyan
    Write-Host "  3. Installer Microsoft Deployment Toolkit" -ForegroundColor Cyan
    Write-Host "  4. Relancer ce script" -ForegroundColor Cyan
}

Write-Host "Configuration WDS/MDT terminee" -ForegroundColor Green