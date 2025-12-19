Write-Host "Configuration du DHCP..." -ForegroundColor Yellow

# Vérifier que DHCP est installé
if (-not (Get-WindowsFeature DHCP).Installed) {
    Write-Host "Installation du rôle DHCP..." -ForegroundColor Cyan
    Install-WindowsFeature DHCP -IncludeManagementTools
}

# Autoriser le serveur DHCP dans Active Directory
Write-Host "Autorisation du serveur DHCP dans AD..." -ForegroundColor Cyan
try {
    Add-DhcpServerInDC -DnsName "SRV-DC1.mediaschool.local" -IPAddress 192.168.100.10
    Write-Host "Serveur DHCP autorise dans AD" -ForegroundColor Green
} catch {
    Write-Host "Erreur autorisation DHCP (peut deja etre autorise): $_" -ForegroundColor Yellow
}

# Configuration du scope DHCP
$scopeId = "192.168.100.0"
$startRange = "192.168.100.50"
$endRange = "192.168.100.200"
$subnetMask = "255.255.255.0"
$scopeName = "Scope-Lycee"

# Supprimer le scope s'il existe déjà
if (Get-DhcpServerv4Scope -ScopeId $scopeId -ErrorAction SilentlyContinue) {
    Write-Host "Suppression de l'ancien scope..." -ForegroundColor Yellow
    Remove-DhcpServerv4Scope -ScopeId $scopeId -Force
}

# Créer le scope
Write-Host "Creation du scope DHCP $scopeId ($startRange - $endRange)..." -ForegroundColor Cyan
Add-DhcpServerv4Scope -Name $scopeName -StartRange $startRange -EndRange $endRange -SubnetMask $subnetMask -State Active

# Configurer les options DHCP
Write-Host "Configuration des options DHCP..." -ForegroundColor Cyan

# Option 003 - Routeur (Gateway)
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 3 -Value 192.168.100.1

# Option 006 - Serveurs DNS
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 6 -Value 192.168.100.10

# Option 015 - Nom de domaine DNS
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 15 -Value "mediaschool.local"

# Configurer les mises à jour DNS dynamiques
Write-Host "Configuration des mises a jour DNS..." -ForegroundColor Cyan
Set-DhcpServerv4DnsSetting -ScopeId $scopeId -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true

# Configurer la sécurité DHCP
Write-Host "Configuration de la securite DHCP..." -ForegroundColor Cyan
Set-DhcpServerv4DnsSetting -ComputerName "SRV-DC1.mediaschool.local" -DynamicUpdates Always -DeleteDnsRROnLeaseExpiry $true

# Notification de configuration post-installation
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12" -Name ConfigurationState -Value 2 -ErrorAction SilentlyContinue

Write-Host "DHCP configure avec succes!" -ForegroundColor Green
Write-Host "Scope: $scopeId" -ForegroundColor Cyan
Write-Host "Plage: $startRange - $endRange" -ForegroundColor Cyan
Write-Host "DNS: 192.168.100.10" -ForegroundColor Cyan
Write-Host "Domaine: mediaschool.local" -ForegroundColor Cyan