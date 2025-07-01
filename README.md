# Windows Firewall Botnet Hardening

Dieses Repository enthält ein PowerShell-Skript, das aggressive Botnet-IP-Feeds automatisch lädt und per Windows-Firewall blockiert. Gleichzeitig werden nur Ihre eigenen Netze und Dienste via Whitelist explizit erlaubt.

---

## Inhalt

- `block_bots_hart.ps1` – Hauptskript zum Blockieren aller bekannten Botnetze  
- `LICENSE` – (falls gewünscht) Lizenzinformation  

---

## ⚙️ Voraussetzungen

- Windows 10/11 (oder Server ab 2016)  
- PowerShell 5.1 oder neuer  
- Administrator-Rechte beim Ausführen  

---

## 🔧 Installation

1. Dieses Repo klonen oder ZIP entpacken.  
2. In PowerShell (als Administrator) in das Skript-Verzeichnis wechseln:  
   ```powershell
   cd C:\Pfad\zu\repo
   .\block_bots.ps1

