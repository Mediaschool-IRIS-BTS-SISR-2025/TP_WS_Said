

Write-Host "Installation des rôles AD DS, DNS et DHCP..." -ForegroundColor Yellow

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools
Install-WindowsFeature -Name DHCP -IncludeManagementTools

Write-Host "Promotion du serveur en contrôleur de domaine pour mediaschool.local..." -ForegroundColor Yellow

$domainName = "mediaschool.local"

# Mot de passe fort pour Administrateur local + DSRM (doit respecter la complexité)
$AdminPasswordPlain = "TPSaidWindows1!"          # ≈ ton mot de passe mais renforcé
$AdminPassword      = ConvertTo-SecureString $AdminPasswordPlain -AsPlainText -Force

# On définit d'abord le mot de passe du compte Administrateur local
Write-Host "Définition du mot de passe de l'administrateur local..." -ForegroundColor Yellow
net user Administrator $AdminPasswordPlain

# Mot de passe DSRM (mode restauration AD)
$dsrmPassword = $AdminPassword

Install-ADDSForest `
    -DomainName $domainName `
    -InstallDns `
    -SafeModeAdministratorPassword $dsrmPassword `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force
