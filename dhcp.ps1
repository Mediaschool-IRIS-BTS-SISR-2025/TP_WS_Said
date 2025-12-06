# dhcp.ps1
Import-Module DhcpServer

Write-Host "Configuration du DHCP..." -ForegroundColor Yellow

# Ajout du serveur DHCP dans l'AD (adapter le nom si besoin)
Add-DhcpServerInDC -DnsName "SRV-DC1.mediaschool.local" -IPAddress "192.168.100.10"

# 7. Création du Scope DHCP
$poolStart   = "192.168.100.50"
$poolEnd     = "192.168.100.200"
$scopeId     = "192.168.100.0"      # adresse du réseau
$gateway     = "192.168.100.1"
$dnsServer   = "192.168.100.10"
$domainName  = "mediaschool.local"
$leaseDuration = New-TimeSpan -Hours 6

Write-Host "Création du scope DHCP $scopeId ($poolStart - $poolEnd)..." -ForegroundColor Yellow

Add-DhcpServerv4Scope `
    -Name "SCOPE-SALLE-INFO" `
    -StartRange $poolStart `
    -EndRange $poolEnd `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration $leaseDuration

# 8. Configuration des Options du Scope
Write-Host "Configuration des options DHCP..." -ForegroundColor Yellow
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 3  -Value $gateway     # Router
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 6  -Value $dnsServer   # DNS Servers
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 15 -Value $domainName  # DNS Domain Name

# 9. Activation des mises à jour DNS sécurisées
Write-Host "Activation des mises à jour DNS sécurisées pour le scope..." -ForegroundColor Yellow
Set-DhcpServerv4Scope -ScopeId $scopeId -DynamicUpdates "Secure"

Write-Host "DHCP configuré." -ForegroundColor Green
