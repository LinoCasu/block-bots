<#
.SYNOPSIS
  Kombiniertes Hardening-Skript: Backup aller Firewall-Regeln, Download aggressiver Botnet-Feeds und Block aller gefundenen IP-/CIDR-Ranges.
.DESCRIPTION
  1. Admin-Check
  2. Backup bestehender Firewall-Regeln
  3. Download & Parsen von Blocklisten (FeodoTracker, Spamhaus DROP, CINSArmy)
  4. Anlegen von Inbound-Blockregeln für jede IP/CIDR
  5. Ausgabe eines einfachen Logs
#>

# 1) Admin-Check
if (-not ([Security.Principal.WindowsPrincipal] \
    [Security.Principal.WindowsIdentity]::GetCurrent() \
  ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Error "Bitte PowerShell als Administrator neu starten!"
  exit 1
}

# 2) Backup aller aktuellen Firewall-Regeln
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "FirewallBackup_$timestamp.wfw"
Write-Host "🔄 Sichere aktuelle Firewall-Regeln nach: $backupFile"
Export-WindowsFirewallRules -FilePath $backupFile

# 3) Definiere Botnet-Feeds ohne private Informationen
$feeds = @{
  "FeodoTracker" = "https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
  "SpamhausDROP" = "https://www.spamhaus.org/drop/drop.txt"
  "CINSArmy"     = "https://cinsscore.com/list/ci-badguys.txt"
}

# 4) Hilfsfunktion: Kommentar entfernen, nur gültige IPv4(/CIDR)
function Parse-Line {
  param([string]$line)
  $clean = $line.Split(';')[0].Trim()
  if ($clean -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}(\/\d{1,2})?$') {
    return $clean
  }
  return $null
}

# 5) Blockliste sammeln und anwenden
$allRanges = [System.Collections.Generic.HashSet[string]]::new()
foreach ($name in $feeds.Keys) {
  Write-Host "⏳ Lade Feed [$name]..."
  try {
    $content = (Invoke-WebRequest -Uri $feeds[$name] -UseBasicParsing).Content
    foreach ($line in $content -split "`n") {
      $cidr = Parse-Line $line
      if ($cidr) { $allRanges.Add($cidr) | Out-Null }
    }
  }
  catch {
    Write-Warning "⚠️ Fehler beim Laden von $name – übersprungen."
  }
}

Write-Host "🎯 Blockiere $($allRanges.Count) Botnet-IP/CIDR-Ranges..."
foreach ($cidr in $allRanges) {
  $ruleName = "BlockBot_$($cidr.Replace('/','_'))"
  if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule \
      -DisplayName   $ruleName \
      -Direction     Inbound \
      -Action        Block \
      -RemoteAddress $cidr \
      -Profile       Any \
      -Description   "Block Botnet-Range $cidr"
    Write-Host "⛔ Geblockt: $cidr"
  }
}

Write-Host "\n✅ Alle Botnet-Ranges wurden geblockt und Regeln gesichert in $backupFile." -ForegroundColor Green
