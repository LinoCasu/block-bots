# ======================
# SAFE FIREWALL KONFIG
# ======================
Write-Host "🛡️  Konfiguriere sichere Firewallregeln..." -ForegroundColor Cyan

# -------- ALLOW LIST --------
$allowPorts   = @(5000, 8088, 8089, 8090, 7522, 554, 4000, 443)
$allowDNS     = @("1.1.1.1", "8.8.8.8", "8.8.4.4")
$allowDomains = @("YOUR_DOMAIN")  # Wird dynamisch aufgelöst

# Erlaube benötigte Ports (eingehend + ausgehend)
foreach ($port in $allowPorts) {
    New-NetFirewallRule -DisplayName "ALLOW_PORT_${port}_IN"   -Direction Inbound  -LocalPort $port   -Protocol TCP -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "ALLOW_PORT_${port}_OUT"  -Direction Outbound -RemotePort $port  -Protocol TCP -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# Erlaube DNS-Server (UDP/53, ausgehend)
foreach ($dns in $allowDNS) {
    New-NetFirewallRule -DisplayName "ALLOW_DNS_${dns}"         -Direction Outbound -RemoteAddress $dns -Protocol UDP -RemotePort 53 -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# Erlaube Domains (aufgelöste IPs)
foreach ($domain in $allowDomains) {
    try {
        $addresses = (Resolve-DnsName $domain -ErrorAction Stop).IPAddress
        foreach ($addr in $addresses) {
            New-NetFirewallRule -DisplayName "ALLOW_DOMAIN_${domain}_${addr}" -Direction Outbound -RemoteAddress $addr -Protocol Any -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Konnte Domain $domain nicht auflösen."
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

# Erlaube Proton AG IP-Ranges (eingehend + ausgehend)
foreach ($range in $ProtonWhitelist) {
    New-NetFirewallRule -DisplayName "ALLOW_PROTON_${range}_IN"  -Direction Inbound  -RemoteAddress $range -Protocol Any -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "ALLOW_PROTON_${range}_OUT" -Direction Outbound -RemoteAddress $range -Protocol Any -Action Allow -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# --- Google News Whitelist (Anycast-IPs dynamisch ermitteln) ---
try {
    $GoogleNewsWhitelist = Resolve-DnsName news.google.com -Type A `
        | Select-Object -ExpandProperty IPAddress `
        | ForEach-Object { "$($_)/32" }
} catch {
    Write-Warning "⚠️ Konnte news.google.com nicht auflösen – Google-News-IPs werden nicht gefiltert."
    $GoogleNewsWhitelist = @()
}

# (optional: wenn Du statisch bleiben willst, statt Resolve-DnsName einfach manuell befüllen)
# $GoogleNewsWhitelist = @('142.250.176.195/32','142.250.176.193/32', …)

# … weiter unten, nachdem Du alle Feeds in $AllRanges geladen hast …
# Beispiel bei Dir vielleicht so benannt:
# $AllRanges = Import-Feeds | Sort-Object –Unique

# → Entferne vor dem Speichern alle Google-News-IPs
$AllRanges = $AllRanges | Where-Object {
    -not ($GoogleNewsWhitelist -contains $_)
}

# jetzt erst: $AllRanges in JSON/CSV dumpen
# z.B.:
# $AllRanges | ConvertTo-Json | Out-File feeds.json


# -------- BLOCK LIST --------
# ⚫ Botnetz- & Scam-Ranges (aus Malewarebyte-Logs & bekannten Quellen)
$blockRanges = @(
    "104.234.0.0/16",  # OVH / Scammer Hosting
    "141.0.0.0/8",     # Brute-Force/Spam
    "94.0.0.0/8",      # Botnets & Scam-Infrastruktur
    "91.0.0.0/8",      # Spezifischer Host aus Malewarebyte-Logs
    "154.0.0.0/8",     # Scam-/Phishing-Zielnetz
    "134.0.0.0/8",
    "138.0.0.0/8",
    "165.0.0.0/8",
    "89.0.0.0/8",
    "18.0.0.0/8",
    "192.81.0.0/16",
    "80.0.0.0/8",
    "45.0.0.0/8",
    "206.0.0.0/8",
    "87.0.0.0/8",
    "3.0.0.0/8",
    "46.0.0.0/8",
    "64.0.0.0/8",
    "51.0.0.0/8",
    "47.0.0.0/8",
    "20.0.0.0/8"
)

foreach ($range in $blockRanges) {
    New-NetFirewallRule -DisplayName "BLOCK_BOTNET_${range}_IN"  -Direction Inbound  -RemoteAddress $range -Protocol Any -Action Block -Profile Any -Enabled True -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "BLOCK_BOTNET_${range}_OUT" -Direction Outbound -RemoteAddress $range -Protocol Any -Action Block -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# ⚫ Microsoft & Windows Telemetrie
$telemetryRanges = @(
    "13.107.0.0/16",   # Microsoft
    "40.76.0.0/14",    # Microsoft
    "65.52.0.0/14",    # Microsoft
    "131.107.0.0/16",  # Microsoft
    "157.55.0.0/16",   # Microsoft
    "207.46.0.0/16"    # Microsoft
)
foreach ($range in $telemetryRanges) {
    New-NetFirewallRule -DisplayName "BLOCK_TELEMETRY_${range}" -Direction Inbound  -RemoteAddress $range -Protocol Any -Action Block -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

# ⚫ Google Tracking (ohne DNS!)
$googleTrackers = @(
    "142.250.0.0/16",  # Google (allg.)
    "172.217.0.0/16",  # Google Tracking
    "216.58.0.0/16"    # Google Services
)
foreach ($range in $googleTrackers) {
    New-NetFirewallRule -DisplayName "BLOCK_GOOGLE_${range}" -Direction Outbound -RemoteAddress $range -Protocol Any -Action Block -Profile Any -Enabled True -ErrorAction SilentlyContinue
}

Write-Host "`n✅ Fertig! Wichtige Dienste erlaubt – Bots & Telemetrie geblockt." -ForegroundColor Green
