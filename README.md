## Windows Firewall Botnet Hardening

![dr-strangelove-dr-strangelove-or-how-i-learned-to-stop-worrying-and-love-the-bomb](https://github.com/user-attachments/assets/e2d78de6-7873-4459-9d45-614a64a25a67)

For anyone who really wants to go full “hardcore,” here’s a botnet IP blocker I scripted myself. 

**But beware:**

Adjust the ports you need open according to your own specifications.

Used together, these three scripts will block half the Internet -> they’re extremely aggressive. 

If you’re still getting port scans or other botnet attacks after running them, you’ve truly tangled with a botnet; there probably won’t be much of one left.

If you run all three at once, they’re so ruthless they might be overkill for a single user,
but they cover over 16,000+ IP ranges known for botnet activity. 

In the worst case you’ll end up blocking parts of Bulgaria and parts of Africa and Asia,
but if you still aren’t safe with these scripts plus Malwarebytes and AdGuard, I’d be surprised.

P.S. You’ll need to tailor them to your own needs.
---

This repository provides a small PowerShell toolkit that:

1. **Automatically downloads** aggressive botnet IP feeds
2. **Blocks** those IPs via Windows Firewall
3. **Whitelists only** your own networks and services, ensuring no unintended blocks&#x20;

---

## Contents

* **`save_block.ps1`** – *Minimal stage*
  Fetches all configured botnet IP feeds (e.g. EmergingThreats, Blocklist.de) and saves them locally (JSON/CSV) for inspection before applying any firewall changes .

* **`block_bots.ps1`** – *Additional stage*
  Imports the saved lists and creates one or more Windows Firewall rules to block each IP range. You can run this after `save_block.ps1` to apply the blocks without touching any other settings.

* **`block_bots_hart.ps1`** – *Hardening stage*
  Orchestrates both downloading and blocking in one go, *plus* applies extra firewall hygiene:

  * Sets the default inbound profile to “Block”
  * Removes or disables legacy rules that might allow unwanted traffic
  * Creates rate-limit rules and locks down common ports (e.g. RDP, SMB)
  * Ensures the block rules are applied in the correct order for maximum effect

> **Tip:** you can run the scripts one by one to see exactly what each does, or simply run the hardening script to do everything in sequence.

> **Tip2:** change the left open ports inside save_block.ps1 as you need it.

> **Tip3:** change wide ipranges into save_block.ps1 if they are too harsh.
---

## ⚙️ Requirements

* **OS:** Windows 10/11 or Windows Server 2016+
* **PowerShell:** 5.1 or later
* **Permissions:** must be run **as Administrator**&#x20;

> **Reminder:** after applying these scripts, **please adjust the list of open ports** (e.g., RDP, SMB, custom services) **to fit your environment and risk profile**.

---

## 🔧 Installation & Usage

1. Clone this repo or unzip the download.
2. Open PowerShell **as Administrator** and `cd` into the script folder.
3. Execute one of the following, depending on how aggressively you want to lock things down:

   ````powershell
   # minimal: just fetch feeds
   .\save_block.ps1

   # additional: fetch + block
   .\block_bots.ps1

   # hardening: fetch, block, and apply extra firewall policies
   .\block_bots_hart.ps1
    
   ````

---


By separating “fetch,” “block,” and “hardening” into three scripts, you get full control over each step —>ideal for testing in a lab before rolling out to production. 
If you’d like even deeper insight into each rule or feed source, you can open the `.ps1` files directly; they’re heavily commented to guide you through every Firewall API call.





