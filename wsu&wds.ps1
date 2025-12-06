# wsu&wds.ps1
Import-Module GroupPolicy
Import-Module DhcpServer

# 14. Création des GPO pour WSUS
Write-Host "Création des GPO WSUS..." -ForegroundColor Yellow
if (-not (Get-GPO -Name "GPO-WSUS-Pilote" -ErrorAction SilentlyContinue)) {
    New-GPO -Name "GPO-WSUS-Pilote" | Out-Null
}
if (-not (Get-GPO -Name "GPO-WSUS-Production" -ErrorAction SilentlyContinue)) {
    New-GPO -Name "GPO-WSUS-Production" | Out-Null
}

$wsusURL   = "http://SRV-FS1:8530"
$regPathWU = "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate"
$regPathAU = "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"

# 15. Configuration GPO-WSUS-Pilote
Write-Host "Configuration de 'GPO-WSUS-Pilote'..." -ForegroundColor Yellow
$gpoName     = "GPO-WSUS-Pilote"
$targetGroup = "WSUS-Pilote"

# Spécifier le serveur WSUS
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "WUServer"      -Value $wsusURL   -Type String
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "WUStatusServer" -Value $wsusURL   -Type String
# Activer le ciblage côté client
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "TargetGroupEnabled" -Value 1           -Type DWord
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "TargetGroup"        -Value $targetGroup -Type String
# Configurer Mises à jour auto (Mode 4)
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathAU -ValueName "AUOptions"           -Value 4  -Type DWord
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathAU -ValueName "ScheduledInstallDay" -Value 0  -Type DWord
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathAU -ValueName "ScheduledInstallTime"-Value 12 -Type DWord

# Configuration GPO-WSUS-Production
Write-Host "Configuration de 'GPO-WSUS-Production'..." -ForegroundColor Yellow
$gpoName     = "GPO-WSUS-Production"
$targetGroup = "WSUS-Production"

Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "WUServer"      -Value $wsusURL   -Type String
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "WUStatusServer" -Value $wsusURL   -Type String
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "TargetGroupEnabled" -Value 1           -Type DWord
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathWU -ValueName "TargetGroup"        -Value $targetGroup -Type String
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathAU -ValueName "AUOptions"           -Value 4  -Type DWord
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathAU -ValueName "ScheduledInstallDay" -Value 0  -Type DWord
Set-GPRegistryValue -Name $gpoName -Context Computer -Key $regPathAU -ValueName "ScheduledInstallTime"-Value 12 -Type DWord

# 16. Liaison des GPO WSUS aux OU des Ordinateurs
Write-Host "Liaison des GPO WSUS aux OU..." -ForegroundColor Yellow
New-GPLink -Name "GPO-WSUS-Pilote"     -Target "OU=Pilotes,OU=Comptes-Ordinateurs,OU=ECOLE,DC=mediaschool,DC=local"    -Enforced:$false -ErrorAction SilentlyContinue
New-GPLink -Name "GPO-WSUS-Production" -Target "OU=Production,OU=Comptes-Ordinateurs,OU=ECOLE,DC=mediaschool,DC=local" -Enforced:$false -ErrorAction SilentlyContinue

# 17. Configuration des Options DHCP pour WDS (PXE)
Write-Host "Configuration des options DHCP pour le PXE..." -ForegroundColor Yellow
$scopeId = "192.168.100.0"
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 66 -Value "SRV-FS1.mediaschool.local"
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 67 -Value '\Boot\x64\wdsmgfw.efi' # UEFI

Write-Host "GPO WSUS et options DHCP PXE configurées." -ForegroundColor Green
