# 10. Création des GPO (Partie 1) [cite: 81, 82, 84]
Write-Host "Création et liaison des GPO..." -f Yellow
New-GPO -Name "GPO-ADM-Poste"
New-GPO -Name "GPO-PROF-Poste"
New-GPO -Name "GPO-ELEVE-Poste"

# 11. Liaison des GPO aux OU des Utilisateurs
New-GPLink -Name "GPO-ADM-Poste" -Target "OU=Administration,OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-GPLink -Name "GPO-PROF-Poste" -Target "OU=Profs,OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-GPLink -Name "GPO-ELEVE-Poste" -Target "OU=Eleves,OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"

# 12. Paramétrage des GPO (partie registre)
# Activer "Force logoff when logon hours expire" [cite: 90]
$regPath = "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation"
$regKey = "ForceLogoffWhenLogonHoursExpire"

Set-GPRegistryValue -Name "GPO-ADM-Poste" -Context Computer -Key $regPath -ValueName $regKey -Value 1 -Type DWord
Set-GPRegistryValue -Name "GPO-PROF-Poste" -Context Computer -Key $regPath -ValueName $regKey -Value 1 -Type DWord
Set-GPRegistryValue -Name "GPO-ELEVE-Poste" -Context Computer -Key $regPath -ValueName $regKey -Value 1 -Type DWord

# --- NOTE IMPORTANTE SUR LE LECTEUR H: ---
# La GPO "Drive Maps" (Lecteur H:) est une "Préférence" (GPP)[cite: 87].
# Le module PowerShell 'GroupPolicy' de base ne peut PAS configurer les GPP.
# Vous devez faire cette partie (configurer le lecteur H:) manuellement via GPMC.exe.
# GPMC.exe -> Modifier "GPO-ELEVE-Poste" -> Préférences -> Mappages de lecteurs