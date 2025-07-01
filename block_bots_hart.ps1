<#
.SYNOPSIS
  Blockiert aggressive Botnet-IP-Ranges via Windows-Firewall – robust gegen Kommentare und leere Zeilen.

.DESCRIPTION
  • Lädt Blocklisten von FeodoTracker, Spamhaus DROP und CINSArmy.  
  • Entfernt Kommentare („; …“) und Leerzeilen, trimmt Whitespace.  
  • Filtert nur Zeilen, die mit einer IP oder CIDR beginnen.  
  • Legt für jede Range eine Inbound-Blockregel an (sofern noch nicht vorhanden).
#>

# Admin-Check
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
  ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Error "Bitte PowerShell als Administrator neu starten!"
  exit 1
}

# 1) Quellen
$feeds = @{
  "FeodoTracker" = "https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
  "SpamhausDROP" = "https://www.spamhaus.org/drop/drop.txt"
  "CINSArmy"     = "https://cinsscore.com/list/ci-badguys.txt"
}

# 2) Hilfsfunktion: Zeile → saubere CIDR/IP
function Parse-Line($line) {
    # Kommentare abschneiden
    $line = $line.Split(';')[0]
    $line = $line.Trim()
    # Nur Zeilen, die mit Ziffern oder IPv6 ([0-9a-f:]) beginnen
    if ($line -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}(\/\d{1,2})?$') {
        return $line
    }
    return $null
}

$allRanges = [System.Collections.Generic.HashSet[string]]::new()

# 3) Feeds laden und parsen
foreach ($name in $feeds.Keys) {
    $url = $feeds[$name]
    try {
        Write-Host "⏳ Lade Feed [$name]: $url"
        $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
        $content -split "`n" | ForEach-Object {
            $cidr = Parse-Line $_
            if ($cidr) { $allRanges.Add($cidr) | Out-Null }
        }
    }
    catch {
        Write-Warning "⚠️ Fehler beim Laden von $name – übersprungen."
    }
}

# 4) Block-Regeln anlegen
Write-Host "`n🎯 Erstelle Block-Regeln für $($allRanges.Count) Ranges…" -ForegroundColor Cyan
foreach ($cidr in $allRanges) {
    $ruleName = "BlockBot_$($cidr.Replace('/','_'))"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule `
          -DisplayName    $ruleName `
          -Direction      Inbound `
          -Action         Block `
          -Profile        Any `
          -RemoteAddress  $cidr `
          -Description    "Block Botnet-Range $cidr"
        Write-Host "⛔ Angelegt: $cidr"
    }
}

Write-Host "`n✅ Fertig – alle Botnet-Ranges wurden geblockt!" -ForegroundColor Green
