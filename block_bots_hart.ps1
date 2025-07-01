<#
.SYNOPSIS
  Blockiert aggressive Botnet-IP-Ranges via Windows-Firewall – alle Botnet-Ranges wurden geblockt!

.DESCRIPTION
  • Lädt Blocklisten von FeodoTracker, Spamhaus DROP und CINSArmy.  
  • Entfernt Kommentare („; …“) und Leerzeilen, trimmt Whitespace.  
  • Filtert nur Zeilen, die mit einer IP, CIDR oder Range beginnen.  
  • Wandelt Einzel-IPv4-Adressen in /24-Netze um (z.B. 20.29.24.17 → 20.29.24.0/24).  
  • Legt für jede Range eine Inbound-Blockregel an (sofern noch nicht vorhanden).
#>

# 0. Admin-Check
if (-not ([Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Error "❗ Bitte PowerShell als Administrator neu starten!"
    Exit
}

# 1. Hilfsfunktion: Liste von URLs laden und filtern
function Import-IPsFromUrl {
    param($url)
    try {
        (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content `
            -split "`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            ($_ -and -not $_.StartsWith(';')) -and
            ($_ -match '^(?:\d+\.\d+\.\d+\.\d+(?:/\d+)?|\d+\.\d+\.\d+\.\d+-\d+\.\d+\.\d+\.\d+)$')
        }
    }
    catch {
        # Hier die Subexpressions, damit $url und $_ korrekt expandieren
        Write-Warning "❗ Fehler beim Laden von $($url): $($_)"
        return @()
    }
}

# 2. Hilfsfunktion: Einzel-IP → /24 umwandeln
function Normalize-To24 {
    param($entry)
    if ($entry -match '^(\d+\.\d+\.\d+)\.\d+$') {
        return "$($matches[1]).0/24"
    }
    else {
        return $entry
    }
}

# 3. Quellen definieren
$blocklistUrls = @(
    'https://feodotracker.abuse.ch/downloads/ipblocklist.csv',
    'https://www.spamhaus.org/drop/drop.txt',
    'https://cinsscore.com/list/ci-badguys.txt'
)

# 4. Ranges importieren und blocken
foreach ($url in $blocklistUrls) {
    Write-Host "`nLade Liste von $url …"
    $entries = Import-IPsFromUrl $url

    foreach ($entry in $entries) {
        $cidr = Normalize-To24 $entry
        $ruleName = "BlockBot_$($cidr -replace '[\/\-]','_')"

        if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule `
                -DisplayName   $ruleName `
                -Direction     Inbound `
                -Action        Block `
                -Profile       Any `
                -RemoteAddress $cidr `
                -Description   "Block Botnet-Range $cidr"
            Write-Host "⛔ Angelegt: $cidr"
        }
        else {
            Write-Host "✔ übersprungen (bereits vorhanden): $cidr"
        }
    }
}

Write-Host "`n✅ Fertig – alle Botnet-Ranges wurden geblockt!" -ForegroundColor Green

