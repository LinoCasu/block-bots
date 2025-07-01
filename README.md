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
   .\block_bots_hart.ps1

<div class="tenor-gif-embed" data-postid="25111514" data-share-method="host" data-aspect-ratio="1.3913" data-width="100%"><a href="https://tenor.com/view/dr-strangelove-dr-strangelove-or-how-i-learned-to-stop-worrying-and-love-the-bomb-how-i-learned-to-stop-worrying-and-love-the-bomb-peter-sellers-gigantic-complex-of-computers-gif-25111514">Dr Strangelove Dr Strangelove Or How I Learned To Stop Worrying And Love The Bomb GIF</a>from <a href="https://tenor.com/search/dr+strangelove-gifs">Dr Strangelove GIFs</a></div> <script type="text/javascript" async src="https://tenor.com/embed.js"></script>
   
