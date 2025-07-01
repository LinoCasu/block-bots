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

# → Erlaube Domains wie error.sytes.net
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

# -------- BLOCK LIST --------

# ⚫ Botnetz- & Scam-Ranges (aus Screenshots & bekannten Quellen)
$blockRanges = @(
    "104.234.0.0/16",   # OVH / Scammer Hosting
    "141.98.0.0/16",    # Brute-Force/Spam
    "185.234.0.0/16",   # Ransomware / Scam
    "185.107.0.0/16",   # Bulletproof Hosting
    "94.103.0.0/16",    # Botnets & Scam-Infrastruktur
    "91.219.236.0/24",  # Spezifischer Host aus Screenshot
    "185.220.101.0/24", # Verdächtig / teils Tor
    "185.180.6.0/24",   # Scam-/Phishing-Zielnetz
    "154.0.0.0/16",
    "134.0.0.0/16",
    "94.0.0.0/16",
    "138.0.0.0/16",
    "165.0.0.0/16"
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
