# ✅ Sicheres Block-Skript: nur bewährte Botnet/Malware-Listen

# 0. Admin-Prüfung (traditionell am Skriptanfang)
if (-not ([Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "❗ Bitte das Skript als Administrator ausführen!"
    Exit
}

function Import-IPsFromUrl {
    param($url)
    try {
        (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content -split "`n" |
            Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+(/\d+)?$' }
    } catch {
        Write-Warning "❗ Fehler beim Laden von $url"
        return @()
    }
}

# 1. FireHOL Level 1: etablierte Angriffsliste (wenige False Positives)
$fh1 = Import-IPsFromUrl 'https://iplists.firehol.org/files/firehol_level1.netset'
foreach ($ip in $fh1) {
    New-NetFirewallRule -DisplayName "Block_FireHOL1_$ip" `
        -Direction Outbound -RemoteAddress $ip `
        -Protocol Any -Action Block -Profile Any
}

# 2. Spamhaus BCL (Botnet Controller List): Einzelne C&C-Server
$bcl = Import-IPsFromUrl 'https://www.spamhaus.org/drop/bcl.txt'
foreach ($ip in $bcl) {
    New-NetFirewallRule -DisplayName "Block_SpamhausBCL_$ip" `
        -Direction Outbound -RemoteAddress $ip `
        -Protocol Any -Action Block -Profile Any
}

# 3. Spamhaus XBL (Exploit Blocklist): kompromittierte Hosts
$xbl = Import-IPsFromUrl 'https://www.spamhaus.org/drop/xbl.txt'
foreach ($ip in $xbl) {
    New-NetFirewallRule -DisplayName "Block_SpamhausXBL_$ip" `
        -Direction Outbound -RemoteAddress $ip `
        -Protocol Any -Action Block -Profile Any
}

Write-Host "🎯 Block-Skript ausgeführt: FireHOL1, BCL & XBL-Listen blockiert."
