# horloge.ps1
Import-Module ActiveDirectory

Write-Host "Configuration des horaires de connexion..." -ForegroundColor Yellow

<#
  LogonHours = 21 octets (7 jours x 24h = 168 bits).
  Convention AD :
    - Jour 0 = Dimanche, 1 = Lundi, ... 6 = Samedi
    - Chaque bit = 1 heure (0 = refuse, 1 = autorise)
  IMPORTANT: LogonHours est interprete en UTC par AD.
#>

function New-LogonHoursArray {
    param(
        [Parameter(Mandatory=$true)]
        [object[]]$RangesPerDay,

        # Optionnel: decalage horaire en heures (ex: +1 pour CET, +2 pour CEST)
        [int]$UtcOffsetHours = 0
    )

    $bytes = New-Object 'Byte[]' 21

    foreach ($range in $RangesPerDay) {
        $day       = [int]$range.day
        $startHour = [int]$range.start
        $endHour   = [int]$range.end

        if ($day -lt 0 -or $day -gt 6) { throw "Jour invalide: $day (0..6)" }
        if ($startHour -lt 0 -or $startHour -gt 24) { throw "Heure debut invalide: $startHour (0..24)" }
        if ($endHour -lt 0 -or $endHour -gt 24) { throw "Heure fin invalide: $endHour (0..24)" }
        if ($endHour -le $startHour) { throw "Plage invalide (fin <= debut) : $startHour-$endHour (jour $day)" }

        for ($hour = $startHour; $hour -lt $endHour; $hour++) {

            # Application offset UTC si besoin
            $adjusted = $hour - $UtcOffsetHours

            # normaliser dans 0..23 en roulant sur les jours si necessaire
            $adjDay = $day
            while ($adjusted -lt 0)  { $adjusted += 24; $adjDay = ($adjDay - 1) }
            while ($adjusted -ge 24) { $adjusted -= 24; $adjDay = ($adjDay + 1) }
            $adjDay = ($adjDay % 7 + 7) % 7

            $bitIndex  = ($adjDay * 24) + $adjusted
            $byteIndex = [math]::Floor($bitIndex / 8)
            $bitOffset = $bitIndex % 8

            $bytes[$byteIndex] = $bytes[$byteIndex] -bor (1 -shl $bitOffset)
        }
    }

    return $bytes
}

# ⚠️ Pour un TP en France, souvent AD est interprete en UTC:
# - En hiver: UtcOffsetHours = +1 (CET)
# - En ete:   UtcOffsetHours = +2 (CEST)
# Si tu ne veux pas de decalage, laisse 0.
$UtcOffsetHours = 1

# Administration : Lun–Ven 07h–19h
$adminRanges = foreach ($d in 1..5) { [pscustomobject]@{ day = $d; start = 7; end = 19 } }
$Horaires_Admin = New-LogonHoursArray -RangesPerDay $adminRanges -UtcOffsetHours $UtcOffsetHours

# Profs : Lun–Ven 07h–20h, Samedi 08h–12h
$profsRanges = foreach ($d in 1..5) { [pscustomobject]@{ day = $d; start = 7; end = 20 } }
$profsRanges += [pscustomobject]@{ day = 6; start = 8; end = 12 }
$Horaires_Profs = New-LogonHoursArray -RangesPerDay $profsRanges -UtcOffsetHours $UtcOffsetHours

# Eleves : Lun–Ven 08h–18h
$elevesRanges = foreach ($d in 1..5) { [pscustomobject]@{ day = $d; start = 8; end = 18 } }
$Horaires_Eleves = New-LogonHoursArray -RangesPerDay $elevesRanges -UtcOffsetHours $UtcOffsetHours

function Apply-LogonHoursToGroup {
    param(
        [Parameter(Mandatory=$true)][string]$GroupName,
        [Parameter(Mandatory=$true)][byte[]]$Hours
    )

    Write-Host "Application horaires au groupe: $GroupName" -ForegroundColor Cyan

    $members = @()
    try {
        $members = Get-ADGroupMember -Identity $GroupName -Recursive -ErrorAction Stop |
                   Where-Object { $_.ObjectClass -eq "user" }
    } catch {
        Write-Host "Groupe introuvable ou inaccessible: $GroupName. Details: $_" -ForegroundColor Yellow
        return
    }

    if (-not $members -or $members.Count -eq 0) {
        Write-Host "Aucun utilisateur dans $GroupName (skip)." -ForegroundColor Yellow
        return
    }

    $count = 0
    foreach ($u in $members) {
        try {
            Set-ADUser -Identity $u.DistinguishedName -Replace @{ logonHours = $Hours }
            $count++
        } catch {
            Write-Host "Impossible de definir LogonHours pour $($u.SamAccountName): $_" -ForegroundColor Yellow
        }
    }

    Write-Host "OK: $count utilisateur(s) mis a jour pour $GroupName." -ForegroundColor Green
}

Apply-LogonHoursToGroup -GroupName "MS-Administration" -Hours $Horaires_Admin
Apply-LogonHoursToGroup -GroupName "MS-Profs"          -Hours $Horaires_Profs
Apply-LogonHoursToGroup -GroupName "MS-Eleves"         -Hours $Horaires_Eleves

Write-Host "Horaires de connexion appliques." -ForegroundColor Green
