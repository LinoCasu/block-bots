# ======================
# SAFE FIREWALL KONFIG
# ======================
Write-Host "🛡️  Konfiguriere sichere Firewallregeln..." -ForegroundColor Cyan

# -------- ALLOW LIST --------
$allowPorts = @(5000, 8088, 8089, 8090, 7522, 554, 4000, 443)
$allowDNS = @("1.1.1.1", "8.8.8.8", "8.8.4.4")
$allowDomains = @("error.sytes.net")  # Wird dynamisch aufgelöst

# → Erlaube benötigte Ports (eingehend + ausgehend)
foreach ($port in $allowPorts) {
    New-NetFirewallRule -DisplayName "ALLOW_PORT_$port_IN" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "ALLOW_PORT_$port_OUT" -Direction Outbound -Protocol TCP -LocalPort $port -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# → Erlaube DNS zu bekannten Servern
foreach ($dns in $allowDNS) {
    New-NetFirewallRule -DisplayName "ALLOW_DNS_$dns" -Direction Outbound -RemoteAddress $dns -Protocol UDP -LocalPort 53 -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# → Erlaube Domains wie YOUR URL
foreach ($domain in $allowDomains) {
    try {
        $ip = [System.Net.Dns]::GetHostAddresses($domain) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
        if ($ip) {
            New-NetFirewallRule -DisplayName "ALLOW_DOMAIN_$domain" -Direction Outbound -RemoteAddress $ip.IPAddressToString -Action Allow -Profile Any -Protocol Any -Enabled True
        }
    } catch {
        Write-Host "⚠️  Konnte $domain nicht auflösen – Regel übersprungen" -ForegroundColor Yellow
    }
}

# -------- PROTON AG WHITELIST --------
$ProtonWhitelist = @(
    '109.224.244.0/24',
    '176.119.200.0/24',
    '185.205.70.0/24',
    '185.70.40.0/24',
    '185.70.41.0/24',
    '185.70.42.0/24',
    '185.70.43.0/24',
    '194.0.147.0/24',
    '79.135.106.0/24',
    '79.135.107.0/24'
)

# → Erlaube benötigte Ports (eingehend + ausgehend)
foreach ($port in $allowPorts) {
    New-NetFirewallRule -DisplayName "ALLOW_PORT_$port_IN"  -Direction Inbound  -LocalPort $port -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "ALLOW_PORT_$port_OUT" -Direction Outbound -LocalPort $port -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# … dein Code zum Erlauben von DNS und Domains …

# -------- BLOCK LIST --------

# ⚫ Botnetz- & Scam-Ranges (aus Screenshots & bekannten Quellen)
$blockRanges = @(
    "104.234.0.0/16", # OVH / Scammer Hosting
    "141.0.0.0/8",    # Brute-Force/Spam
    "94.0.0.0/8",     # Botnets & Scam-Infrastruktur
    "91.0.0.0/8",     # Spezifischer Host aus Screenshot
    "185.0.0.0/8",    # Verdächtig / teils Tor
    "154.0.0.0/8",    # Scam-/Phishing-Zielnetz
    "134.0.0.0/8",
    "94.0.0.0/8",
    "138.0.0.0/8",
    "165.0.0.0/8"
	"89.0.0.0/8"
	"18.0.0.0/8"
	"192.81.0.0/16"
	"80.0.0.0/8"
	"45.0.0.0/8"
	"206.0.0.0/8"
	"87.0.0.0/8"
	"3.0.0.0/8"
	"46.0.0.0/8"
	"64.0.0.0/8"
	"51.0.0.0/8"
	"45.0.0.0/8"
	"47.0.0.0/8"
	"20.0.0.0/8"
)

foreach ($range in $blockRanges) {
    New-NetFirewallRule -DisplayName "BLOCK_SCAM_$range" -Direction Outbound -RemoteAddress $range -Action Block -Profile Any -Protocol Any -Enabled True -ErrorAction SilentlyContinue
}

# ⚫ Microsoft & Windows Telemetrie
$telemetryRanges = @(
    "13.107.0.0/16",    # Microsoft
    "40.76.0.0/14",     # Microsoft
    "65.52.0.0/14",     # Microsoft
    "131.107.0.0/16",   # Microsoft
    "157.55.0.0/16",    # Microsoft
    "207.46.0.0/16"     # Microsoft
)

foreach ($range in $telemetryRanges) {
    New-NetFirewallRule -DisplayName "BLOCK_TELEMETRY_$range" -Direction Outbound -RemoteAddress $range -Action Block -Profile Any -Protocol Any -Enabled True -ErrorAction SilentlyContinue
}

# ⚫ Google Tracking (ohne DNS!)
$googleTrackers = @(
    "142.250.0.0/16",   # Google (allg.)
    "172.217.0.0/16",   # Google Tracking
    "216.58.0.0/16"     # Google Services
)

foreach ($range in $googleTrackers) {
    New-NetFirewallRule -DisplayName "BLOCK_GOOGLE_$range" -Direction Outbound -RemoteAddress $range -Action Block -Profile Any -Protocol Any -Enabled True -ErrorAction SilentlyContinue
}

Write-Host "`n✅ Fertig! Wichtige Dienste erlaubt – Bots & Telemetrie geblockt." -ForegroundColor Green
