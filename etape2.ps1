# etape2.ps1
Import-Module ActiveDirectory

# 3. Création de la zone DNS inverse
Write-Host "Création de la zone DNS inverse..." -ForegroundColor Yellow
Add-DnsServerPrimaryZone -NetworkID "192.168.100.0/24" -ReplicationScope "Forest"

# 4. Création des OU (Unités d'Organisation)
Write-Host "Création de la structure AD..." -ForegroundColor Yellow

New-ADOrganizationalUnit -Name "ECOLE"               -Path "DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Comptes-Utilisateurs" -Path "OU=ECOLE,DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Administration"       -Path "OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Profs"                -Path "OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Eleves"               -Path "OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Comptes-Ordinateurs"  -Path "OU=ECOLE,DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Pilotes"              -Path "OU=Comptes-Ordinateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-ADOrganizationalUnit -Name "Production"           -Path "OU=Comptes-Ordinateurs,OU=ECOLE,DC=mediaschool,DC=local"

# 5. Création des Groupes de Sécurité
Write-Host "Création des groupes de sécurité..." -ForegroundColor Yellow
New-ADGroup -Name "MS-Administration" -GroupScope Global -Path "OU=Administration,OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-ADGroup -Name "MS-Profs"          -GroupScope Global -Path "OU=Profs,OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"
New-ADGroup -Name "MS-Eleves"         -GroupScope Global -Path "OU=Eleves,OU=Comptes-Utilisateurs,OU=ECOLE,DC=mediaschool,DC=local"

Write-Host "Structure AD créée." -ForegroundColor Green
