# config wsus.ps1
Import-Module UpdateServices

# 6. Post-installation WSUS (stockage local)
Write-Host "Post-installation de WSUS..." -ForegroundColor Yellow
if (-not (Test-Path "D:\WSUS")) {
    New-Item -Path "D:\WSUS" -ItemType Directory | Out-Null
}
& "C:\Program Files\Update Services\Tools\wsusutil.exe" postinstall CONTENT_DIR=D:\WSUS

# 7. Connexion au serveur WSUS
Write-Host "Configuration de WSUS (Produits, Classes, Groupes)..." -ForegroundColor Yellow
$wsusServer = Get-WsusServer -Name "localhost" -Port 8530

# 8. Synchro depuis Microsoft
$wsusServer | Set-WsusServerSynchronization -SyncFromMicrosoftUpdate

# 9. Désactiver tous les produits
$wsusServer | Get-WsusProduct | Where-Object { $_.IsSubscribed } | Set-WsusProduct -Disable

# 10. Activer les produits requis
$wsusServer | Get-WsusProduct -TitleIncludes "Windows 10"          | Set-WsusProduct
$wsusServer | Get-WsusProduct -TitleIncludes "Windows 11"          | Set-WsusProduct
$wsusServer | Get-WsusProduct -TitleIncludes "Windows Server 2022" | Set-WsusProduct

# 11. Configurer les classifications
$classifications = "Critical Updates", "Security Updates", "Definition Updates"
$wsusServer | Get-WsusClassification | Set-WsusClassification -Disable
$classifications | ForEach-Object {
    $wsusServer | Get-WsusClassification -Title $_ | Set-WsusClassification
}

# 12. Créer les groupes WSUS
if (-not ($wsusServer.GetComputerTargetGroups() | Where-Object Name -eq "WSUS-Pilote")) {
    $wsusServer.CreateComputerTargetGroup("WSUS-Pilote") | Out-Null
}
if (-not ($wsusServer.GetComputerTargetGroups() | Where-Object Name -eq "WSUS-Production")) {
    $wsusServer.CreateComputerTargetGroup("WSUS-Production") | Out-Null
}

# 13. Approber automatiquement (une première fois) les updates de Sécurité/Defs pour Pilote
Write-Host "Approbation automatique initiale des mises à jour Sécurité/Defs pour WSUS-Pilote..." -ForegroundColor Yellow

# Récupère toutes les MAJ non approuvées de type Sécurité / Définitions
$updatesToApprove = Get-WsusUpdate |
    Where-Object {
        $_.UpdateClassificationTitle -in @("Security Updates","Definition Updates") -and
        $_.IsApproved -eq $false
    }

if ($updatesToApprove) {
    $updatesToApprove | Approve-WsusUpdate -Action Install -TargetGroupName "WSUS-Pilote"
}

# 14. Lancer la première synchro (peut être long)
Write-Host "Lancement de la première synchronisation WSUS..." -ForegroundColor Yellow
Invoke-WsusServerSynchronization -Server $wsusServer

Write-Host "Configuration WSUS terminée." -ForegroundColor Green
