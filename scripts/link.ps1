# 1. Joindre le serveur au domaine (redémarrera le serveur)
# (Assurez-vous que le DNS de SRV-FS1 est 192.168.100.10)
Write-Host "Jonction au domaine mediaschool.local..." -f Yellow
Add-Computer -DomainName "mediaschool.local" -Credential (Get-Credential) -Restart -Force

# --- ATTENDEZ LE REDÉMARRAGE AVANT DE CONTINUER ---
# --- RE-OUVREZ POWERSHELL EN ADMIN DE DOMAINE (ex: MEDIASCHOOL\Administrateur) ---

# 2. Installation des rôles FSRM, WSUS, WDS [cite: 19, 167, 201]
Write-Host "Installation des rôles Fichiers, FSRM, WSUS, WDS..." -f Yellow
Install-WindowsFeature -Name File-Services, FS-Resource-Manager, UpdateServices, WDS -IncludeManagementTools