Write-Host "Configuration WSUS GPO et DHCP PXE..." -ForegroundColor Yellow

$wsusURL = "http://192.168.100.20:8530"
$dcServer = "SRV-DC1.mediaschool.local"

# Tester la connexion au DC
Write-Host "Test de connexion au DC..." -ForegroundColor Cyan
try {
    $pingResult = Test-Connection -ComputerName $dcServer -Count 2 -Quiet
    if (-not $pingResult) {
        Write-Host "ATTENTION: Impossible de joindre le DC $dcServer" -ForegroundColor Yellow
        Write-Host "Les operations GPO et DHCP doivent etre effectuees sur SRV-DC1" -ForegroundColor Yellow
        exit 0
    }
} catch {
    Write-Host "Erreur test connexion DC: $_" -ForegroundColor Yellow
    exit 0
}

# Configuration GPO (si le module existe)
if (Get-Module -ListAvailable -Name GroupPolicy) {
    try {
        Import-Module GroupPolicy -ErrorAction Stop
        
        Write-Host "GPO: Creation des GPO WSUS..." -ForegroundColor Yellow
        
        # GPO Pilote
        if (-not (Get-GPO -Name "GPO-WSUS-Pilote" -ErrorAction SilentlyContinue)) {
            New-GPO -Name "GPO-WSUS-Pilote" -Domain "mediaschool.local" | Out-Null
            Write-Host "GPO-WSUS-Pilote creee" -ForegroundColor Green
        }
        
        # GPO Production
        if (-not (Get-GPO -Name "GPO-WSUS-Production" -ErrorAction SilentlyContinue)) {
            New-GPO -Name "GPO-WSUS-Production" -Domain "mediaschool.local" | Out-Null
            Write-Host "GPO-WSUS-Production creee" -ForegroundColor Green
        }
        
        # Configuration des valeurs de registre
        $regPathWU = "Software\Policies\Microsoft\Windows\WindowsUpdate"
        $regPathAU = "Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
        
        # Fonction pour configurer une GPO WSUS
        function Set-WsusGPO {
            param($GpoName, $TargetGroup)
            
            # WUServer
            Set-GPRegistryValue -Name $GpoName -Key "HKLM\$regPathWU" -ValueName "WUServer" -Type String -Value $wsusURL | Out-Null
            Set-GPRegistryValue -Name $GpoName -Key "HKLM\$regPathWU" -ValueName "WUStatusServer" -Type String -Value $wsusURL | Out-Null
            
            # TargetGroup
            Set-GPRegistryValue -Name $GpoName -Key "HKLM\$regPathWU" -ValueName "TargetGroupEnabled" -Type DWord -Value 1 | Out-Null
            Set-GPRegistryValue -Name $GpoName -Key "HKLM\$regPathWU" -ValueName "TargetGroup" -Type String -Value $TargetGroup | Out-Null
            
            # AutoUpdate
            Set-GPRegistryValue -Name $GpoName -Key "HKLM\$regPathAU" -ValueName "AUOptions" -Type DWord -Value 4 | Out-Null
            Set-GPRegistryValue -Name $GpoName -Key "HKLM\$regPathAU" -ValueName "UseWUServer" -Type DWord -Value 1 | Out-Null
        }
        
        Write-Host "Configuration GPO-WSUS-Pilote..." -ForegroundColor Cyan
        Set-WsusGPO -GpoName "GPO-WSUS-Pilote" -TargetGroup "WSUS-Pilote"
        
        Write-Host "Configuration GPO-WSUS-Production..." -ForegroundColor Cyan
        Set-WsusGPO -GpoName "GPO-WSUS-Production" -TargetGroup "WSUS-Production"
        
        Write-Host "GPO WSUS configurees avec succes" -ForegroundColor Green
        
    } catch {
        Write-Host "Erreur configuration GPO: $_" -ForegroundColor Yellow
        Write-Host "Les GPO devront etre configurees manuellement sur SRV-DC1" -ForegroundColor Yellow
    }
} else {
    Write-Host "Module GroupPolicy absent - Configuration GPO a faire sur SRV-DC1" -ForegroundColor Yellow
}

# Configuration DHCP PXE (si le module existe)
if (Get-Module -ListAvailable -Name DhcpServer) {
    try {
        Import-Module DhcpServer -ErrorAction Stop
        
        Write-Host "DHCP: Configuration options PXE..." -ForegroundColor Yellow
        
        $scopeId = "192.168.100.0"
        
        # Option 66 - Boot Server Host Name
        Set-DhcpServerv4OptionValue -ComputerName $dcServer -ScopeId $scopeId -OptionId 66 -Value "192.168.100.20" -ErrorAction Stop
        Write-Host "Option DHCP 66 configuree" -ForegroundColor Green
        
        # Option 67 - Bootfile Name
        Set-DhcpServerv4OptionValue -ComputerName $dcServer -ScopeId $scopeId -OptionId 67 -Value "boot\x64\wdsnbp.com" -ErrorAction Stop
        Write-Host "Option DHCP 67 configuree" -ForegroundColor Green
        
        Write-Host "Options DHCP PXE configurees avec succes" -ForegroundColor Green
        
    } catch {
        Write-Host "Erreur configuration DHCP: $_" -ForegroundColor Yellow
        Write-Host "Les options DHCP devront etre configurees manuellement sur SRV-DC1" -ForegroundColor Yellow
    }
} else {
    Write-Host "Module DhcpServer absent - Configuration DHCP a faire sur SRV-DC1" -ForegroundColor Yellow
}

Write-Host "Configuration WSUS GPO / DHCP PXE terminee" -ForegroundColor Green