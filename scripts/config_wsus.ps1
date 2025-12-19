Write-Host "WSUS: post-installation..." -ForegroundColor Yellow

# Vérifier que WSUS est installé
if (-not (Get-WindowsFeature UpdateServices).Installed) {
    Write-Host "WSUS n'est pas installe. Installation..." -ForegroundColor Yellow
    Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
    Install-WindowsFeature -Name UpdateServices-WidDB
    Install-WindowsFeature -Name UpdateServices-Services
    Write-Host "WSUS installe. Attendez quelques instants..." -ForegroundColor Green
    Start-Sleep -Seconds 30
}

# Déterminer le lecteur
$drive = if (Test-Path "D:\") { "D:" } else { "C:" }
$wsusContent = "$drive\WSUS"

if (-not (Test-Path $wsusContent)) {
    New-Item -Path $wsusContent -ItemType Directory -Force | Out-Null
}

# Post-install WSUS
$wsusUtil = "C:\Program Files\Update Services\Tools\wsusutil.exe"
if (Test-Path $wsusUtil) {
    Write-Host "WSUS: execution du post-install (peut prendre 5-10 minutes)..." -ForegroundColor Yellow
    try {
        $result = & $wsusUtil postinstall CONTENT_DIR=$wsusContent 2>&1
        Write-Host "Post-install termine" -ForegroundColor Green
    } catch {
        Write-Host "Erreur post-install WSUS: $_" -ForegroundColor Yellow
    }
    
    # Attendre que WSUS soit prêt
    Start-Sleep -Seconds 30
} else {
    Write-Host "ERREUR: wsusutil.exe introuvable" -ForegroundColor Red
    exit 1
}

# Importer le module UpdateServices
try {
    Import-Module UpdateServices -ErrorAction Stop
    Write-Host "Module UpdateServices importe" -ForegroundColor Green
} catch {
    Write-Host "Erreur import module UpdateServices: $_" -ForegroundColor Red
    exit 1
}

# Connexion au serveur WSUS
Write-Host "WSUS: connexion au serveur..." -ForegroundColor Yellow
try {
    $wsusServer = Get-WsusServer -Name "localhost" -PortNumber 8530 -ErrorAction Stop
    Write-Host "Connexion WSUS reussie" -ForegroundColor Green
} catch {
    Write-Host "Erreur connexion WSUS: $_" -ForegroundColor Red
    exit 1
}

# Configuration de la source de synchronisation
Write-Host "WSUS: configuration de la source de synchronisation..." -ForegroundColor Yellow
try {
    $config = $wsusServer.GetConfiguration()
    $config.SyncFromMicrosoftUpdate = $true
    $config.Save()
    Write-Host "Source de synchronisation configuree" -ForegroundColor Green
} catch {
    Write-Host "Erreur configuration source: $_" -ForegroundColor Yellow
}

# Configuration des produits
Write-Host "WSUS: configuration des produits..." -ForegroundColor Yellow
try {
    # Désactiver tous les produits
    Get-WsusProduct | Where-Object { $_.Product.IsSubscribed } | Set-WsusProduct -Disable -ErrorAction SilentlyContinue
    
    # Activer les produits nécessaires
    Get-WsusProduct | Where-Object { $_.Product.Title -like "*Windows 10*" } | Set-WsusProduct -ErrorAction SilentlyContinue
    Get-WsusProduct | Where-Object { $_.Product.Title -like "*Windows 11*" } | Set-WsusProduct -ErrorAction SilentlyContinue
    Get-WsusProduct | Where-Object { $_.Product.Title -like "*Windows Server 2022*" } | Set-WsusProduct -ErrorAction SilentlyContinue
    
    Write-Host "Produits configures" -ForegroundColor Green
} catch {
    Write-Host "Erreur configuration produits: $_" -ForegroundColor Yellow
}

# Configuration des classifications
Write-Host "WSUS: configuration des classifications..." -ForegroundColor Yellow
try {
    # Désactiver toutes les classifications
    Get-WsusClassification | Set-WsusClassification -Disable -ErrorAction SilentlyContinue
    
    # Activer les classifications nécessaires
    $classifications = @("Critical Updates", "Security Updates", "Definition Updates")
    foreach ($class in $classifications) {
        Get-WsusClassification | Where-Object { $_.Classification.Title -eq $class } | Set-WsusClassification -ErrorAction SilentlyContinue
    }
    
    Write-Host "Classifications configurees" -ForegroundColor Green
} catch {
    Write-Host "Erreur configuration classifications: $_" -ForegroundColor Yellow
}

# Création des groupes
Write-Host "WSUS: creation des groupes..." -ForegroundColor Yellow
try {
    $groups = $wsusServer.GetComputerTargetGroups()
    
    if (-not ($groups | Where-Object { $_.Name -eq "WSUS-Pilote" })) {
        [void]$wsusServer.CreateComputerTargetGroup("WSUS-Pilote")
        Write-Host "Groupe WSUS-Pilote cree" -ForegroundColor Green
    }
    
    if (-not ($groups | Where-Object { $_.Name -eq "WSUS-Production" })) {
        [void]$wsusServer.CreateComputerTargetGroup("WSUS-Production")
        Write-Host "Groupe WSUS-Production cree" -ForegroundColor Green
    }
} catch {
    Write-Host "Erreur creation groupes: $_" -ForegroundColor Yellow
}

Write-Host "WSUS: configuration de base terminee." -ForegroundColor Green
Write-Host "Note: La synchronisation initiale peut etre lancee manuellement depuis la console WSUS." -ForegroundColor Cyan