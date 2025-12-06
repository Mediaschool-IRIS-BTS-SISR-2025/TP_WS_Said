# horloge.ps1
Import-Module ActiveDirectory

Write-Host "Configuration des horaires de connexion..." -ForegroundColor Yellow

<#
  Fonction utilitaire :
  Crée un tableau de 21 octets (7 jours x 24h) pour l'attribut LogonHours.
  Convention : 
    - Jour 0 = Dimanche, 1 = Lundi, ... 6 = Samedi
    - Chaque bit = 1 heure (0 = refusé, 1 = autorisé)
#>
function New-LogonHoursArray {
    param(
        [int[][]]$RangesPerDay # ex: @{ day=1; start=8; end=18 }
    )

    $bytes = New-Object 'Byte[]' 21

    foreach ($range in $RangesPerDay) {
        $day       = $range.day
        $startHour = $range.start
        $endHour   = $range.end

        for ($hour = $startHour; $hour -lt $endHour; $hour++) {
            $bitIndex  = ($day * 24) + $hour
            $byteIndex = [math]::Floor($bitIndex / 8)
            $bitOffset = $bitIndex % 8

            # On met le bit à 1 (LSB-first)
            $bytes[$byteIndex] = $bytes[$byteIndex] -bor (1 -shl $bitOffset)
        }
    }

    return $bytes
}

# Horaires Administration : Lun–Ven 07h–19h
$adminRanges = @()
1..5 | ForEach-Object {
    $adminRanges += [pscustomobject]@{ day = $_; start = 7; end = 19 }
}
$Horaires_Admin = New-LogonHoursArray -RangesPerDay $adminRanges

# Horaires Profs : Lun–Ven 07h–20h, Samedi 08h–12h
$profsRanges = @()
1..5 | ForEach-Object {
    $profsRanges += [pscustomobject]@{ day = $_; start = 7; end = 20 }
}
$profsRanges += [pscustomobject]@{ day = 6; start = 8; end = 12 } # Samedi
$Horaires_Profs = New-LogonHoursArray -RangesPerDay $profsRanges

# Horaires Eleves : Lun–Ven 08h–18h
$elevesRanges = @()
1..5 | ForEach-Object {
    $elevesRanges += [pscustomobject]@{ day = $_; start = 8; end = 18 }
}
$Horaires_Eleves = New-LogonHoursArray -RangesPerDay $elevesRanges

# Application aux membres des groupes
Write-Host "Application des horaires aux groupes AD..." -ForegroundColor Yellow

# Administration
Get-ADGroupMember -Identity "MS-Administration" -Recursive |
    Where-Object { $_.ObjectClass -eq "user" } |
    ForEach-Object {
        Set-ADUser -Identity $_.DistinguishedName -LogonHours $Horaires_Admin
    }

# Profs
Get-ADGroupMember -Identity "MS-Profs" -Recursive |
    Where-Object { $_.ObjectClass -eq "user" } |
    ForEach-Object {
        Set-ADUser -Identity $_.DistinguishedName -LogonHours $Horaires_Profs
    }

# Eleves
Get-ADGroupMember -Identity "MS-Eleves" -Recursive |
    Where-Object { $_.ObjectClass -eq "user" } |
    ForEach-Object {
        Set-ADUser -Identity $_.DistinguishedName -LogonHours $Horaires_Eleves
    }

Write-Host "Horaires de connexion appliqués." -ForegroundColor Green
