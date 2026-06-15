<p align="center">
  <img src="https://github.com/globalcve/swissarmyknife/blob/main/SwissArmyKnife.png" alt="SwissArmyKnife Banner" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white" />
  <img src="https://img.shields.io/badge/Toolkit-SwissArmyKnife-blue" />
  <img src="https://img.shields.io/badge/Utilities-Network%2FSystem-lightgrey" />
  <img src="https://img.shields.io/github/license/globalcve/swissarmyknife" />
  <img src="https://img.shields.io/badge/Branch-Stable-green?logo=github&logoColor=white" />
  <img src="https://img.shields.io/github/last-commit/globalcve/swissarmyknife" />
</p>

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/jegly/swissarmyknife)

# Swiss Army Knife

A Bash toolkit for Linux system diagnostics, security auditing, and incident
response. It presents 290+ commands across 40 categories in a `whiptail` menu,
with a safety system that confirms before running anything that changes state.

---

## Features

- System recon: kernel, CPU, memory, disk, uptime, users, network
- Security: firewall rules, listening ports, failed logins, sudoers, SSH config, SUID/SGID
- Packages and services: installed packages, running/failed units, cron and timers
- Filesystem: mounts, block devices, large files, world-writable and hidden files
- Diagnostics: top processes, sockets, DNS lookups, traceroute, packet capture
- Reports: one-shot health check and full diagnostic export

## New in v4.0

- Three safety tiers (`SAFE` / `MODIFIES` / `DANGEROUS`). Read-only commands run
  immediately; state-changing or destructive ones show a preview and require confirmation.
- Automatic privilege handling. Commands that need root are detected and run with
  `sudo` (prompting once), instead of failing silently.
- Per-command timeout. Long-running or hung commands are killed rather than
  freezing the menu (`SAK_TIMEOUT`, default 120s).
- Post-run actions: re-run, view in pager, save output to file, add to favorites.
- Missing-tool markers. Commands whose underlying tool isn't installed are flagged.
- Global keyword search, favorites, and command history.
- Strict mode (`set -uo pipefail`) and automatic temp-file cleanup.

---

## Requirements

- Bash 4+
- Ubuntu/Debian (tested on 20.04+)
- `whiptail`, `coreutils`, `less`. Other tools are prompted for per command.

---

## Usage

```bash
chmod +x SWISS_ARMY_KNIFE.sh
sudo ./SWISS_ARMY_KNIFE.sh          # interactive menu

# Non-interactive
./SWISS_ARMY_KNIFE.sh --health      # run the health check
./SWISS_ARMY_KNIFE.sh --report      # export a full diagnostic report
./SWISS_ARMY_KNIFE.sh --version
./SWISS_ARMY_KNIFE.sh --help

# Optional: per-command timeout in seconds
SAK_TIMEOUT=300 ./SWISS_ARMY_KNIFE.sh
```

Running without `sudo` also works: the toolkit elevates only the commands that
need root and prompts once for your password.

### Safety tiers

| Tier | Behavior | Examples |
|------|----------|----------|
| SAFE | Runs immediately | `df -h`, `ip a`, `lscpu` |
| MODIFIES | Confirm before running | `apt autoremove`, `systemctl restart`, `journalctl --vacuum-*` |
| DANGEROUS | Warning + confirm | `iptables -F`, `docker system prune -a` |

---

## Output

- Results are shown in a scrollable dialog, or opened in `less` when large.
- Any command's output can be saved to a timestamped file.
- Command history is logged to `~/.diagnostic_history`; favorites to `~/.diagnostic_favorites`.

![Preview of SWISS_ARMY_KNIFE.sh submenu](./swiss_army_knife.png)

---

## Contributing

Pull requests welcome.

## License

MIT.


---

## Sample output (`--health`)

```text
SYSTEM HEALTH CHECK REPORT
Generated: ...

[SYSTEM]
Hostname: ubuntu-dev
Kernel: 5.15.0-91-generic
Uptime: up 3 days, 4 hours

[CPU]
Model name: Intel(R) Core(TM) i5
CPU(s): 2

[MEMORY]
              total        used        free
Mem:           15Gi       6.2Gi       4.1Gi

[FAILED SERVICES]
none

[RECENT ERRORS - last 20]
...
```
