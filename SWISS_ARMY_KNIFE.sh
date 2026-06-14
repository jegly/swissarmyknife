#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE SYSTEM DIAGNOSTIC TOOLKIT - SWISS ARMY KNIFE EDITION
# ═══════════════════════════════════════════════════════════════════════════
# Dependencies: whiptail, bash, coreutils, less
# Version: 4.0 - Complete Edition
# ═══════════════════════════════════════════════════════════════════════════

set -uo pipefail

VERSION="4.0"
HISTORY_FILE="$HOME/.diagnostic_history"
FAVORITES_FILE="$HOME/.diagnostic_favorites"
CMD_TIMEOUT="${SAK_TIMEOUT:-120}"   # seconds; long-running commands are killed
LAST_OUTPUT_FILE=""
TMP_FILES=()

declare -A MENU
declare -A COMMAND_SAFETY  # Track command safety levels

cleanup() { (( ${#TMP_FILES[@]} )) && rm -f "${TMP_FILES[@]}" 2>/dev/null; }
trap cleanup EXIT

# Format: MENU["Category:Command"]="Description"

# ═══════════════════════════════════════════════════════════════════════════
# EXISTING CATEGORIES (Enhanced)
# ═══════════════════════════════════════════════════════════════════════════

# 🧨 SYSTEM ERRORS
MENU["System Errors:journalctl -p err..alert -b"]="Boot-time system errors"
MENU["System Errors:journalctl -xe"]="Recent system errors"
MENU["System Errors:dmesg --level=err,warn"]="Kernel error/warning messages"
MENU["System Errors:dmesg | grep -i 'fail\\|error'"]="Search dmesg for failures/errors"
MENU["System Errors:grep -i 'fail\\|error' /var/log/syslog"]="Syslog failures/errors"
MENU["System Errors:grep -i 'segfault\\|panic' /var/log/syslog"]="Syslog segfaults/panics"
MENU["System Errors:grep -i 'critical' /var/log/syslog"]="Syslog critical issues"
MENU["System Errors:grep -i 'oom' /var/log/kern.log"]="Kernel OOM events"
MENU["System Errors:journalctl -b -1 | grep systemd"]="Previous boot systemd logs"
MENU["System Errors:journalctl --boot=-1"]="Full previous boot log"
MENU["System Errors:last -x"]="Last shutdown/reboot events"
MENU["System Errors:systemd-analyze blame"]="Boot time per service"
MENU["System Errors:systemd-analyze critical-chain"]="Critical boot chain"
MENU["System Errors:systemd-analyze plot > ~/boot_plot.svg && echo 'Saved to ~/boot_plot.svg'"]="Generate boot plot SVG"
MENU["System Errors:journalctl -u systemd-shutdown"]="Shutdown logs"
MENU["System Errors:journalctl -u systemd-halt"]="Halt logs"
MENU["System Errors:journalctl -u systemd-poweroff"]="Poweroff logs"
MENU["System Errors:grep -i plymouth /var/log/syslog"]="Plymouth shutdown errors"
MENU["System Errors:journalctl -u plymouth*"]="Plymouth service logs"

# 🛠️ SNAP MANAGEMENT
MENU["Snap Management:snap list"]="List installed snaps"
MENU["Snap Management:snap changes"]="Recent snap changes"
MENU["Snap Management:snap refresh --list"]="List available snap updates"
MENU["Snap Management:snap debug sandbox-features"]="Snap sandbox features"
MENU["Snap Management:snap debug confinement"]="Snap confinement mode"
MENU["Snap Management:snap debug seeding"]="Snap seeding status"

# 🔐 TPM + FDE + SNAP BOOT
MENU["TPM & FDE:ls -la /dev/tpm*"]="List TPM devices"
MENU["TPM & FDE:dmesg | grep -i tpm"]="TPM kernel messages"
MENU["TPM & FDE:journalctl -b | grep -i tpm"]="TPM journal messages"
MENU["TPM & FDE:lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,UUID"]="List block devices with filesystem info"
MENU["TPM & FDE:snap debug boot"]="Snap boot info"
MENU["TPM & FDE:snap debug boot --verbose"]="Verbose snap boot info"
MENU["TPM & FDE:snap debug fde-status"]="Full disk encryption status"
MENU["TPM & FDE:snap debug secureboot-status"]="Secure boot status"
MENU["TPM & FDE:snap debug tpm-status"]="TPM status via snap"
MENU["TPM & FDE:snap recover --show"]="Show recovery status"

# 🧍 NETWORK MANAGER
MENU["Network Manager:nmcli general status"]="NM general status"
MENU["Network Manager:nmcli device status"]="Device status"
MENU["Network Manager:nmcli connection show"]="List connections"
MENU["Network Manager:nmcli radio all"]="Radio status"
MENU["Network Manager:nmcli networking connectivity check"]="Connectivity check"
MENU["Network Manager:nmcli device wifi list"]="List WiFi networks"
MENU["Network Manager:ip a"]="Show IP addresses"
MENU["Network Manager:ip r"]="Show routing table"
MENU["Network Manager:ip link"]="Show network interfaces"
MENU["Network Manager:ip -s link"]="Show interface statistics"
MENU["Network Manager:ip -br a"]="Brief IP address list"

# 🧱 IPTABLES FIREWALL
MENU["Firewall:iptables -L -v -n"]="List firewall rules"
MENU["Firewall:iptables -S"]="List rules in save format"
MENU["Firewall:iptables -t nat -L -n -v"]="List NAT table rules"
MENU["Firewall:iptables -t mangle -L -n -v"]="List mangle table rules"
MENU["Firewall:iptables-save"]="Save current rules to stdout"
COMMAND_SAFETY["Firewall:iptables -F"]="DANGEROUS"
MENU["Firewall:iptables -F"]="⚠️  Flush all rules (WARNING: May disconnect)"

# 🧍 NETWORK DIAGNOSTICS
MENU["Network Diagnostics:ping -c 4 8.8.8.8"]="Ping Google DNS (4 packets)"
MENU["Network Diagnostics:ping -c 4 1.1.1.1"]="Ping Cloudflare DNS (4 packets)"
MENU["Network Diagnostics:traceroute 8.8.8.8"]="Traceroute to Google"
MENU["Network Diagnostics:netstat -tulnp"]="Show open ports"
MENU["Network Diagnostics:ss -tuln"]="Show socket stats"
MENU["Network Diagnostics:ss -tulnp"]="Show socket stats with processes"
MENU["Network Diagnostics:dig example.com"]="DNS lookup for example.com"
MENU["Network Diagnostics:nslookup example.com"]="DNS lookup via nslookup"
MENU["Network Diagnostics:host example.com"]="DNS lookup via host"
MENU["Network Diagnostics:curl -I https://example.com"]="HTTP header check"
MENU["Network Diagnostics:wget --spider https://example.com"]="Test URL reachability"

# 🔍 SYSTEM INSIGHTS
MENU["System Insights:systemctl list-units --failed"]="List failed units"
MENU["System Insights:systemctl list-units --type=service"]="List all services"
MENU["System Insights:systemctl list-timers"]="List systemd timers"
MENU["System Insights:lshw -short"]="Hardware overview"
MENU["System Insights:lsblk"]="List block devices"
MENU["System Insights:lscpu"]="CPU information"
MENU["System Insights:lsusb"]="USB devices"
MENU["System Insights:lspci"]="PCI devices"
MENU["System Insights:uname -a"]="System information"
MENU["System Insights:cat /proc/cpuinfo"]="Detailed CPU info"
MENU["System Insights:cat /proc/meminfo"]="Detailed memory info"
MENU["System Insights:cat /proc/version"]="Kernel version details"
MENU["System Insights:free -h"]="Memory usage"

# 🧰 SERVICE & DAEMON CONTROL
MENU["Service Control:systemctl list-units --type=service --state=running"]="List running services"
MENU["Service Control:systemctl list-units --type=service --state=failed"]="List failed services"
MENU["Service Control:systemctl daemon-reload"]="Reload systemd manager"
COMMAND_SAFETY["Service Control:systemctl daemon-reload"]="MODIFIES"

# 🧩 KERNEL & MODULE INFO
MENU["Kernel Info:uname -r"]="Show kernel version"
MENU["Kernel Info:lsmod"]="List loaded kernel modules"
MENU["Kernel Info:lsmod | wc -l"]="Count loaded modules"
MENU["Kernel Info:modprobe -c | grep -v '^#' | head -50"]="Module configuration (first 50)"
MENU["Kernel Info:dmesg | grep -i module"]="Search dmesg for module messages"

# 🧬 USER & GROUP MANAGEMENT
MENU["User Management:id"]="Show current user ID"
MENU["User Management:groups"]="Show user groups"
MENU["User Management:getent passwd"]="List all users"
MENU["User Management:getent group"]="List all groups"
MENU["User Management:sudo -l"]="Show sudo privileges"
MENU["User Management:who"]="Show logged-in users"
MENU["User Management:w"]="Show who is logged in and what they are doing"
MENU["User Management:last | head -30"]="Show last login records (30 entries)"
MENU["User Management:lastlog | head -30"]="Show last login for all users (30 entries)"

# 🧼 CLEANUP & MAINTENANCE
MENU["Cleanup:apt autoremove --dry-run"]="Preview unused packages to remove"
MENU["Cleanup:apt clean --dry-run"]="Preview package cache cleanup"
MENU["Cleanup:journalctl --disk-usage"]="Show journal disk usage"
MENU["Cleanup:journalctl --vacuum-size=100M"]="Limit journal to 100MB"
MENU["Cleanup:journalctl --vacuum-time=7d"]="Remove journal entries older than 7 days"
MENU["Cleanup:journalctl --rotate"]="Rotate journal logs"
MENU["Cleanup:systemd-tmpfiles --clean"]="Clean temporary files"
MENU["Cleanup:apt autoremove"]="Remove unused packages (modifies system)"
MENU["Cleanup:apt clean"]="Clear local package cache (modifies system)"
COMMAND_SAFETY["Cleanup:apt autoremove"]="MODIFIES"
COMMAND_SAFETY["Cleanup:apt clean"]="MODIFIES"

# 🧰 PACKAGE INTEGRITY
MENU["Package Integrity:dpkg -l | wc -l"]="Count installed packages"
MENU["Package Integrity:dpkg -l | tail -50"]="List installed packages (last 50)"
MENU["Package Integrity:apt list --installed | wc -l"]="Count installed packages (apt)"
MENU["Package Integrity:apt-mark showmanual | head -50"]="Show manually installed packages (first 50)"
MENU["Package Integrity:apt-mark showauto | head -50"]="Show automatically installed packages (first 50)"
MENU["Package Integrity:dpkg --verify"]="Verify package integrity"
MENU["Package Integrity:debsums -s"]="Check package checksums (silent)"

# 🧬 ENVIRONMENT & CONFIG
MENU["Environment:env | sort"]="Show environment variables (sorted)"
MENU["Environment:printenv | grep -i path"]="Show PATH-related variables"
MENU["Environment:locale"]="Show locale settings"
MENU["Environment:ulimit -a"]="Show resource limits"
MENU["Environment:hostnamectl"]="Show hostname info"
MENU["Environment:timedatectl"]="Show time and date settings"
MENU["Environment:loginctl show-user $USER"]="Show session info for current user"

# 🧱 FILESYSTEM & STORAGE
MENU["Storage:df -h"]="Disk space usage"
MENU["Storage:df -i"]="Inode usage"
MENU["Storage:du -sh /* 2>/dev/null | sort -h"]="Directory sizes in root (sorted)"
MENU["Storage:mount | column -t"]="Show mounted filesystems (formatted)"
MENU["Storage:lsblk"]="List block devices"
MENU["Storage:lsblk -f"]="List block devices with filesystems"
MENU["Storage:blkid"]="Show block device UUIDs"
MENU["Storage:findmnt"]="Find mounted filesystems"
MENU["Storage:ls -lah /"]="List root directory"

# 🧾 LOG FILE LOCATIONS
MENU["Log Files:ls -lh /var/log/ | head -50"]="List log files (first 50)"
MENU["Log Files:cat /var/log/syslog | tail -100"]="Last 100 lines of syslog"
MENU["Log Files:cat /var/log/kern.log | tail -100"]="Last 100 lines of kern.log"
MENU["Log Files:cat /var/log/auth.log | tail -100"]="Last 100 lines of auth.log"
MENU["Log Files:cat /var/log/dmesg"]="Kernel ring buffer log"
MENU["Log Files:ls /var/log/apt/"]="List APT log files"

# 🧠 DEBUGGING & MONITORING
MENU["Debugging:ps aux | head -30"]="List processes (first 30)"
MENU["Debugging:ps aux --sort=-pcpu | head -20"]="Top 20 CPU consumers"
MENU["Debugging:ps aux --sort=-%mem | head -20"]="Top 20 memory consumers"
MENU["Debugging:top -b -n 1 | head -30"]="Process snapshot (first 30 lines)"
MENU["Debugging:lsof -i"]="List open network files"
MENU["Debugging:lsof +D /var/log"]="Files open in /var/log"
MENU["Debugging:vmstat 1 5"]="Virtual memory stats (5 samples)"
MENU["Debugging:iostat -xz 1 5"]="I/O statistics (5 samples)"

# 🧪 SYSTEM AUDIT
MENU["System Audit:ausearch -ts recent 2>/dev/null | head -50"]="Recent audit events (first 50)"
MENU["System Audit:aureport -x --summary 2>/dev/null"]="Audit executable summary"
MENU["System Audit:aureport -u --summary 2>/dev/null"]="Audit user summary"
MENU["System Audit:auditctl -l 2>/dev/null"]="List audit rules"

# 🕵️ SECURITY
MENU["Security:find /tmp -type f -name '.*' 2>/dev/null | head -30"]="Find hidden files in /tmp (first 30)"
MENU["Security:find / -type f -perm -4000 2>/dev/null | head -50"]="Find SUID files (first 50)"
MENU["Security:find / -type f -size +100M 2>/dev/null | head -20"]="Find large files >100MB (first 20)"
MENU["Security:find /etc -type f -exec grep -l 'password' {} \\; 2>/dev/null | head -20"]="Files with 'password' in /etc (first 20)"

# ═══════════════════════════════════════════════════════════════════════════
# NEW CATEGORIES - HIGH PRIORITY
# ═══════════════════════════════════════════════════════════════════════════

# 📊 PERFORMANCE MONITORING
MENU["Performance:uptime"]="System uptime and load average"
MENU["Performance:sar -u 1 5"]="CPU utilization (5 samples)"
MENU["Performance:sar -r 1 5"]="Memory utilization (5 samples)"
MENU["Performance:sar -n DEV 1 5"]="Network statistics (5 samples)"
MENU["Performance:mpstat -P ALL 1 5"]="Per-CPU statistics (5 samples)"
MENU["Performance:dstat -cdngy 1 5"]="Versatile resource stats (5 samples)"
MENU["Performance:atop -1"]="Advanced system monitor snapshot"
MENU["Performance:nmon -c 5 -s 1"]="Performance monitor (5 snapshots)"

# 🐳 DOCKER & CONTAINERS
MENU["Containers:docker ps -a"]="List all Docker containers"
MENU["Containers:docker images"]="List Docker images"
MENU["Containers:docker stats --no-stream"]="Container resource usage snapshot"
MENU["Containers:docker system df"]="Docker disk usage"
MENU["Containers:docker network ls"]="List Docker networks"
MENU["Containers:docker volume ls"]="List Docker volumes"
MENU["Containers:docker info"]="Docker system information"
MENU["Containers:podman ps -a"]="List Podman containers"
MENU["Containers:podman images"]="List Podman images"
MENU["Containers:lxc list"]="List LXC containers"
MENU["Containers:docker system prune -a"]="⚠️  Remove ALL unused Docker data (DANGEROUS)"
COMMAND_SAFETY["Containers:docker system prune -a"]="DANGEROUS"

# 💾 DISK I/O & FILESYSTEM
MENU["Disk I/O:iotop -b -n 1"]="I/O usage by process (1 iteration)"
MENU["Disk I/O:iostat -xz 1 5"]="Extended I/O statistics (5 samples)"
MENU["Disk I/O:fdisk -l"]="Partition tables"
MENU["Disk I/O:parted -l"]="Partition information"
MENU["Disk I/O:lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE"]="Block devices detailed"
MENU["Disk I/O:findmnt -t ext4,xfs,btrfs"]="Find specific filesystem types"
MENU["Disk I/O:cat /proc/diskstats"]="Disk statistics"

# 🧠 MEMORY ANALYSIS
MENU["Memory:free -m -t"]="Memory with totals in MB"
MENU["Memory:free -h"]="Memory usage human-readable"
MENU["Memory:vmstat -s"]="Virtual memory statistics"
MENU["Memory:slabtop -o"]="Kernel slab cache info (once)"
MENU["Memory:cat /proc/meminfo"]="Detailed memory information"
MENU["Memory:ps aux --sort=-%mem | head -20"]="Top 20 memory consumers"
MENU["Memory:swapon --show"]="Swap usage details"
MENU["Memory:cat /proc/sys/vm/swappiness"]="Swappiness value"
MENU["Memory:smem -tk 2>/dev/null"]="Memory reporting with totals"

# 🔧 HARDWARE INFORMATION
MENU["Hardware:hwinfo --short"]="Hardware info summary"
MENU["Hardware:inxi -Fxz"]="Comprehensive system info"
MENU["Hardware:dmidecode -t memory"]="Memory hardware details"
MENU["Hardware:dmidecode -t processor"]="CPU hardware details"
MENU["Hardware:dmidecode -t bios"]="BIOS information"
MENU["Hardware:dmidecode -t system"]="System information"
MENU["Hardware:sensors"]="Temperature sensors"
MENU["Hardware:lspci -v | head -100"]="Verbose PCI devices (first 100 lines)"
MENU["Hardware:lsusb -v | head -100"]="Verbose USB devices (first 100 lines)"
MENU["Hardware:lshw -class disk"]="Disk hardware info"
MENU["Hardware:lshw -class network"]="Network hardware info"

# 🔄 PROCESS MANAGEMENT
MENU["Processes:pstree -p"]="Process tree with PIDs"
MENU["Processes:ps aux --sort=-pcpu | head -20"]="Top 20 CPU consumers"
MENU["Processes:ps aux --sort=-%mem | head -20"]="Top 20 memory consumers"
MENU["Processes:pgrep -a systemd"]="Find systemd processes"
MENU["Processes:jobs"]="List background jobs"
MENU["Processes:lsof +D /var"]="Files open under /var"
MENU["Processes:fuser -v /var/log"]="Processes using /var/log"
MENU["Processes:pidof systemd"]="Find PID of systemd"

# ⚙️ SYSTEMD DEEP DIVE
MENU["Systemd:systemctl list-unit-files | head -50"]="Unit files and states (first 50)"
MENU["Systemd:systemctl list-unit-files --state=enabled"]="Enabled unit files"
MENU["Systemd:systemctl list-unit-files --state=disabled"]="Disabled unit files"
MENU["Systemd:systemctl list-sockets"]="Active sockets"
MENU["Systemd:systemctl list-jobs"]="Active jobs"
MENU["Systemd:systemd-cgtop -n 1"]="Control group resource usage (1 iteration)"
MENU["Systemd:systemd-cgls"]="Control group hierarchy"
MENU["Systemd:systemd-delta"]="Configuration overrides"
MENU["Systemd:systemd-analyze security"]="Security analysis of units"

# 🌐 NETWORK ADVANCED
MENU["Network Advanced:arp -a"]="ARP cache table"
MENU["Network Advanced:route -n"]="Routing table (numeric)"
MENU["Network Advanced:ip neigh"]="Neighbor table (ARP/NDP)"
MENU["Network Advanced:ss -s"]="Socket statistics summary"
MENU["Network Advanced:ss -antp"]="All TCP connections with processes"
MENU["Network Advanced:ss -anup"]="All UDP connections with processes"
MENU["Network Advanced:iftop -n -t -s 5"]="Bandwidth by connection (5 sec)"
MENU["Network Advanced:tcpdump -i any -c 100 -nn"]="Packet capture (100 packets)"
MENU["Network Advanced:netstat -i"]="Network interface statistics"
MENU["Network Advanced:ip -s -s link"]="Detailed interface statistics"

# 🔒 SECURITY & HARDENING
MENU["Security Audit:aa-status"]="AppArmor status"
MENU["Security Audit:sestatus"]="SELinux status"
MENU["Security Audit:getenforce"]="SELinux enforcement mode"
MENU["Security Audit:ufw status verbose"]="UFW firewall status"
MENU["Security Audit:fail2ban-client status"]="Fail2ban service status"
MENU["Security Audit:lastb | head -20"]="Failed login attempts (first 20)"
MENU["Security Audit:w -i"]="Who with IP addresses"
MENU["Security Audit:find / -perm -4000 -ls 2>/dev/null | head -30"]="SUID files (first 30)"
MENU["Security Audit:find / -perm -2000 -ls 2>/dev/null | head -30"]="SGID files (first 30)"

# ⏰ TIME & NTP
MENU["Time & NTP:timedatectl status"]="Time and date status"
MENU["Time & NTP:timedatectl show-timesync --all"]="Detailed time sync info"
MENU["Time & NTP:chronyc tracking"]="Chrony NTP tracking"
MENU["Time & NTP:chronyc sources"]="Chrony time sources"
MENU["Time & NTP:ntpq -p"]="NTP peers"
MENU["Time & NTP:date"]="Current date and time"
MENU["Time & NTP:hwclock --show"]="Hardware clock"

# ═══════════════════════════════════════════════════════════════════════════
# NEW CATEGORIES - MEDIUM PRIORITY
# ═══════════════════════════════════════════════════════════════════════════

# ⏱️ CRON & SCHEDULED TASKS
MENU["Scheduled Tasks:crontab -l"]="Current user's crontab"
MENU["Scheduled Tasks:sudo crontab -l"]="Root's crontab"
MENU["Scheduled Tasks:ls -la /etc/cron.d/"]="Cron.d directory"
MENU["Scheduled Tasks:ls -la /etc/cron.daily/"]="Daily cron jobs"
MENU["Scheduled Tasks:ls -la /etc/cron.hourly/"]="Hourly cron jobs"
MENU["Scheduled Tasks:ls -la /etc/cron.weekly/"]="Weekly cron jobs"
MENU["Scheduled Tasks:cat /etc/crontab"]="System crontab"
MENU["Scheduled Tasks:systemctl list-timers --all"]="All systemd timers"
MENU["Scheduled Tasks:at -l"]="Pending at jobs"

# 🔐 CERTIFICATES & SSL
MENU["Certificates:certbot certificates"]="Let's Encrypt certificates"
MENU["Certificates:openssl version -a"]="OpenSSL version"
MENU["Certificates:ls -lh /etc/ssl/certs/ | head -30"]="SSL certificates directory (first 30)"
MENU["Certificates:update-ca-certificates --fresh --verbose"]="Update CA certificates"

# 🥾 BOOT & GRUB
MENU["Boot:efibootmgr -v"]="EFI boot entries"
MENU["Boot:grub-install --version"]="GRUB version"
MENU["Boot:cat /boot/grub/grub.cfg | head -50"]="GRUB config (first 50 lines)"
MENU["Boot:cat /proc/cmdline"]="Kernel boot parameters"
MENU["Boot:dmesg | head -100"]="Early boot messages (first 100)"
MENU["Boot:journalctl -b 0 | head -100"]="Current boot log (first 100)"

# 🌐 WEB SERVERS
MENU["Web Servers:apache2ctl -S"]="Apache virtual hosts"
MENU["Web Servers:apache2ctl -V"]="Apache version and settings"
MENU["Web Servers:nginx -t"]="Nginx config test"
MENU["Web Servers:nginx -T"]="Nginx config dump"
MENU["Web Servers:nginx -v"]="Nginx version"
MENU["Web Servers:curl -I localhost"]="Local web server check"
MENU["Web Servers:systemctl status apache2"]="Apache service status"
MENU["Web Servers:systemctl status nginx"]="Nginx service status"

# 📦 QUOTA & LIMITS
MENU["Quotas:quota -v"]="User disk quota"
MENU["Quotas:repquota -a"]="All quotas"
MENU["Quotas:cat /etc/security/limits.conf"]="System limits config"
MENU["Quotas:ulimit -a"]="Current shell limits"

# 🔊 SOUND & AUDIO
MENU["Audio:aplay -l"]="List playback devices"
MENU["Audio:arecord -l"]="List recording devices"
MENU["Audio:pactl list sinks short"]="PulseAudio sinks"
MENU["Audio:pactl list sources short"]="PulseAudio sources"
MENU["Audio:amixer scontrols"]="ALSA mixer controls"

# 🖥️ GRAPHICS & DISPLAY
MENU["Graphics:xrandr"]="Display configuration"
MENU["Graphics:glxinfo | grep OpenGL"]="OpenGL information"
MENU["Graphics:xdpyinfo | head -30"]="X display info (first 30 lines)"
MENU["Graphics:cat /var/log/Xorg.0.log | grep EE"]="X errors"
MENU["Graphics:nvidia-smi"]="NVIDIA GPU info"

# 🔋 POWER MANAGEMENT
MENU["Power:acpi -V"]="ACPI information"
MENU["Power:cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 'No battery found'"]="Battery percentage"
MENU["Power:cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo 'No battery found'"]="Battery status"
MENU["Power:powertop --html=~/powertop.html && echo 'Report saved to ~/powertop.html'"]="Power consumption report"

# 🔌 USB & PERIPHERALS
MENU["USB:usb-devices"]="USB device details"
MENU["USB:lsusb -t"]="USB device tree"
MENU["USB:dmesg | grep -i usb | tail -50"]="Recent USB messages (last 50)"

# 📡 BLUETOOTH
MENU["Bluetooth:bluetoothctl show"]="Bluetooth controller info"
MENU["Bluetooth:hciconfig -a"]="Bluetooth device info"
MENU["Bluetooth:rfkill list"]="Radio device status"

# 📋 SYSTEM INFO SUMMARY
MENU["System Info:screenfetch"]="System info with ASCII art"
MENU["System Info:neofetch"]="Modern system info"
MENU["System Info:landscape-sysinfo"]="Ubuntu landscape info"
MENU["System Info:hostnamectl"]="Hostname information"

# ═══════════════════════════════════════════════════════════════════════════
# SPECIAL ACTIONS
# ═══════════════════════════════════════════════════════════════════════════

MENU["Quick Actions:HEALTH_CHECK"]="🏥 Run comprehensive health check"
MENU["Quick Actions:EXPORT_REPORT"]="📄 Export full diagnostic report"
MENU["Quick Actions:SEARCH_COMMANDS"]="🔍 Search all commands"
MENU["Quick Actions:VIEW_HISTORY"]="📜 View command history"
MENU["Quick Actions:VIEW_FAVORITES"]="⭐ View favorite commands"

# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

# ─── whiptail wrappers (consistent stderr capture & sizing) ──────────────────
wt_menu()  { whiptail --title "$1" --menu  "$2" "${3:-25}" "${4:-100}" "${5:-15}" "${@:6}" 3>&1 1>&2 2>&3; }
wt_yesno() { whiptail --title "$1" --yesno "$2" "${3:-14}" "${4:-78}" 3>&1 1>&2 2>&3; }
wt_input() { whiptail --title "$1" --inputbox "$2" "${3:-10}" "${4:-72}" "${5:-}" 3>&1 1>&2 2>&3; }
wt_msg()   { whiptail --title "$1" --scrolltext --msgbox "$2" "${3:-22}" "${4:-90}"; }

# First token of a command (ignoring a leading sudo).
base_cmd() { awk '{print $1}' <<<"${1#sudo }"; }

# Is the command's primary tool installed?
tool_available() { command -v "$(base_cmd "$1")" &>/dev/null; }

check_command_exists() {
  local b; b=$(base_cmd "$1")
  if ! command -v "$b" &>/dev/null; then
    wt_msg "Command Not Found" \
      "The tool '$b' is not installed.\n\nTry:\n  sudo apt install $b\n\n(Package name may differ from the command name.)" 14 70
    return 1
  fi
  return 0
}

# Heuristic: does this command likely require root? (FIXES the old dead needs_sudo)
command_needs_sudo() {
  local cmd="$1"
  [[ $EUID -eq 0 ]] && return 1            # already root
  [[ "$cmd" == sudo\ * ]] && return 1      # already explicit
  case "$cmd" in
    iptables*|dmidecode*|hwinfo*|smartctl*|hdparm*|fsck*|tcpdump*|iotop*|\
    fail2ban-client*|auditctl*|ausearch*|aureport*|debsums*|powertop*|\
    *dpkg\ --verify*|*"crontab -l"*) return 0 ;;
  esac
  # Reads a typically root-only log/path (but plain `ls` of it is fine)
  [[ "$cmd" == *"/var/log/auth.log"* || "$cmd" == *"/var/log/kern.log"* ]] \
    && [[ "$cmd" != ls\ * ]] && return 0
  return 1
}

# Risk classification. Explicit COMMAND_SAFETY wins; otherwise heuristics.
# Returns: SAFE | MODIFIES | DANGEROUS
classify_safety() {
  local key="$1" cmd="$2"
  if [[ -n "${COMMAND_SAFETY[$key]:-}" ]]; then echo "${COMMAND_SAFETY[$key]}"; return; fi
  case "$cmd" in
    *"rm -rf"*|*mkfs*|*"dd if="*|*" prune"*|*"prune -"*|*"iptables -F"*|\
    *shutdown*|*reboot*|*" kill "*|*pkill*|*mkswap*|*">/dev/sd"*)
      echo "DANGEROUS"; return ;;
    apt*install*|apt*remove*|"apt autoremove"|"apt clean"|apt*upgrade*|\
    *"systemctl start"*|*"systemctl stop"*|*"systemctl restart"*|\
    *"systemctl enable"*|*"systemctl disable"*|*daemon-reload*|\
    *--vacuum*|*update-ca-certificates*|*--rotate*|*"tmpfiles --clean"*|\
    *"nginx -s"*|*"chmod "*|*"chown "*|*"modprobe "*)
      echo "MODIFIES"; return ;;
  esac
  echo "SAFE"
}

log_to_history() { echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$HISTORY_FILE"; }

add_to_favorites() {
  local key="$1"
  if ! grep -qxF "$key" "$FAVORITES_FILE" 2>/dev/null; then
    echo "$key" >> "$FAVORITES_FILE"
    wt_msg "Added to Favorites" "Saved!\n\nAccess via: Quick Actions → View Favorites" 10 60
  else
    wt_msg "Already a Favorite" "This command is already in your favorites." 8 55
  fi
}

# Save the most recent command output to a user-chosen file.
save_last_output() {
  [[ -f "$LAST_OUTPUT_FILE" ]] || { wt_msg "No Output" "Nothing to save yet." 8 50; return; }
  local default="$HOME/sak_output_$(date +%Y%m%d_%H%M%S).txt" path
  path=$(wt_input "Save Output" "Write output to file:" 10 72 "$default") || return
  [[ -z "$path" ]] && return
  if cp "$LAST_OUTPUT_FILE" "$path" 2>/dev/null; then
    wt_msg "Saved" "Output written to:\n$path" 9 72
  else
    wt_msg "Error" "Could not write to:\n$path" 9 60
  fi
}

# Render command output: pager for big results, textbox otherwise.
display_output() {
  local cmd="$1" output="$2" exit_code="${3:-0}" lines chars tmp title
  lines=$(wc -l <<<"$output"); chars=$(wc -c <<<"$output")
  tmp=$(mktemp "${TMPDIR:-/tmp}/sak_out.XXXXXX"); TMP_FILES+=("$tmp")
  {
    echo "Command : $cmd"
    echo "Exit    : $exit_code    Lines: $lines    Size: $((chars/1024))KB"
    echo "When    : $(date '+%F %T')"
    printf '%.0s─' {1..72}; echo
    echo "$output"
  } > "$tmp"
  LAST_OUTPUT_FILE="$tmp"

  title="Output: $cmd"
  (( exit_code != 0 )) && title="Command Failed (exit $exit_code): $cmd"

  if (( chars > 40000 || lines > 800 )); then
    if wt_yesno "Large Output" "Output is large ($lines lines, $((chars/1024))KB).\n\nYes = open in pager (less)\nNo  = show truncated in a dialog" 13 70; then
      clear; less -R "$tmp"
    else
      wt_msg "$title (truncated)" "$(head -400 "$tmp")\n\n[... truncated — choose 'Save output' to keep the full result ...]" 30 100
    fi
  else
    whiptail --title "$title" --scrolltext --textbox "$tmp" 30 100
  fi
}

# Menu shown after a command runs (replaces the old forced favorites prompt).
post_run_menu() {
  local key="$1" cmd="$2" sel
  while true; do
    sel=$(wt_menu "What next?" "Finished: $cmd" 17 80 7 \
      RERUN "🔁 Run again" \
      VIEW  "📄 View output in pager" \
      SAVE  "💾 Save output to file" \
      FAV   "⭐ Add to favorites" \
      BACK  "↩ Back to menu") || return
    case "$sel" in
      RERUN) execute_command "$key"; return ;;
      VIEW)  [[ -f "$LAST_OUTPUT_FILE" ]] && { clear; less -R "$LAST_OUTPUT_FILE"; } ;;
      SAVE)  save_last_output ;;
      FAV)   add_to_favorites "$key" ;;
      BACK)  return ;;
    esac
  done
}

# Core: preview → confirm-if-risky → (sudo) → timeout → capture → display.
execute_command() {
  local key="$1" cmd safety
  cmd="${key#*:}"                      # everything after the first colon

  if [[ "$cmd" =~ \<.*\> ]]; then
    wt_msg "Manual Input Needed" "This command has placeholders:\n\n$cmd\n\nRun it manually and substitute real values." 12 80
    return
  fi

  check_command_exists "$cmd" || return
  safety=$(classify_safety "$key" "$cmd")

  local use_sudo=0; command_needs_sudo "$cmd" && use_sudo=1
  local sudo_txt="no"; (( use_sudo )) && sudo_txt="yes (sudo)"
  local preview="Command : $cmd\nCategory: ${key%%:*}\nSafety  : $safety\nPrivilege: $sudo_txt\nTimeout : ${CMD_TIMEOUT}s"

  # Only interrupt the user for state-changing or destructive commands.
  case "$safety" in
    DANGEROUS) wt_yesno "⚠️  DANGEROUS COMMAND" "$preview\n\nThis may disrupt the system or destroy data.\n\nProceed?" 17 80 || return ;;
    MODIFIES)  wt_yesno "⚙️  Modifies System"   "$preview\n\nThis changes system state.\n\nProceed?" 16 80 || return ;;
  esac

  # Acquire sudo cleanly up-front so the password prompt isn't swallowed.
  if (( use_sudo )); then
    clear; echo "🔑 '$cmd' needs root privileges."
    if ! sudo -v; then wt_msg "Sudo Failed" "Could not obtain root privileges." 8 55; return; fi
  fi

  clear
  local runner="bash -c" pfx=""
  (( use_sudo )) && { runner="sudo bash -c"; pfx="sudo "; }
  echo "▶ ${pfx}$cmd"
  local output exit_code
  output=$(timeout "$CMD_TIMEOUT" $runner "$cmd" 2>&1); exit_code=$?
  (( exit_code == 124 )) && output+=$'\n\n[!] Timed out after '"${CMD_TIMEOUT}"'s and was terminated.'

  log_to_history "${pfx}$cmd"
  display_output "$cmd" "$output" "$exit_code"
  post_run_menu "$key" "$cmd"
}

# Safe, case-insensitive literal search (no regex injection).
search_commands() {
  local kw lc key; kw=$(wt_input "Search" "Search all commands (case-insensitive):" 10 72) || return
  [[ -z "$kw" ]] && return
  lc=${kw,,}
  local results=()
  for key in "${!MENU[@]}"; do
    if [[ "${key,,}" == *"$lc"* || "${MENU[$key],,}" == *"$lc"* ]]; then
      results+=("$key" "${MENU[$key]}")
    fi
  done
  (( ${#results[@]} == 0 )) && { wt_msg "No Results" "No commands match: $kw" 8 60; return; }
  local choice; choice=$(wt_menu "Search: $kw ($(( ${#results[@]} / 2 )) hits)" "Select a command:" 25 100 15 "${results[@]}") || return
  execute_command "$choice"
}

view_history() {
  [[ -s "$HISTORY_FILE" ]] || { wt_msg "No History" "No command history yet." 8 50; return; }
  wt_msg "Command History (last 60)" "$(tail -60 "$HISTORY_FILE")" 28 100
}

view_favorites() {
  [[ -s "$FAVORITES_FILE" ]] || { wt_msg "No Favorites" "No favorites yet.\n\nAdd one from the post-run menu (⭐ Add to favorites)." 10 60; return; }
  local fav=() key
  while IFS= read -r key; do
    [[ -n "$key" ]] && fav+=("$key" "${MENU[$key]:-(no longer available)}")
  done < "$FAVORITES_FILE"
  (( ${#fav[@]} == 0 )) && { wt_msg "No Favorites" "No favorite commands found." 8 50; return; }
  local choice; choice=$(wt_menu "Favorite Commands" "Select a favorite:" 25 100 15 "${fav[@]}") || return
  execute_command "$choice"
}

# ─── Reports ──────────────────────────────────────────────────────────────────
run_health_check() {
  local report=""
  report+="═══════════════════════════════════════════════════════════\n"
  report+="SYSTEM HEALTH CHECK REPORT\nGenerated: $(date)\n"
  report+="═══════════════════════════════════════════════════════════\n\n"
  report+="[SYSTEM]\nHostname: $(hostname)\nKernel: $(uname -r)\nUptime: $(uptime -p)\n\n"
  report+="[LOAD AVERAGE]\n$(uptime | awk -F'load average:' '{print $2}')\n\n"
  report+="[CPU]\n$(lscpu | grep -E '^Model name|^CPU\(s\):|^Thread|^Core')\n\n"
  report+="[MEMORY]\n$(free -h)\n\n"
  report+="[DISK]\n$(df -h | grep -vE 'tmpfs|loop')\n\n"
  report+="[THERMAL]\n"
  local t; t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | awk '{printf "%.0f°C ", $1/1000}')
  report+="${t:-n/a}\n\n"
  report+="[FAILED SERVICES]\n"
  local failed; failed=$(systemctl --failed --no-pager --no-legend 2>/dev/null)
  report+="${failed:-✓ none}\n\n"
  report+="[RECENT ERRORS - last 20]\n$(journalctl -p err -n 20 --no-pager 2>/dev/null || echo 'journal unavailable')\n\n"
  report+="[NETWORK]\n$(ip -br a 2>/dev/null)\n\n"
  report+="[TOP 5 CPU]\n$(ps aux --sort=-pcpu | head -6 | tail -5)\n\n"
  report+="[TOP 5 MEM]\n$(ps aux --sort=-%mem | head -6 | tail -5)\n\n"
  report+="═══════════════════════════════════════════════════════════\n"
  display_output "Health Check" "$(echo -e "$report")" 0
  if wt_yesno "Save Report?" "Save this health check to a file?" 8 60; then
    local f="$HOME/health_check_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "$report" > "$f"
    wt_msg "Saved" "Report saved to:\n$f" 9 70
  fi
}

export_full_report() {
  local f="$HOME/diagnostic_report_$(date +%Y%m%d_%H%M%S).txt"
  whiptail --title "Generating Report" --infobox "Collecting diagnostics…\nThis can take a minute." 8 60
  {
    echo "════════════════════════════════════════════════════════════"
    echo "COMPREHENSIVE SYSTEM DIAGNOSTIC REPORT"
    echo "Generated: $(date)   Host: $(hostname)"
    echo "════════════════════════════════════════════════════════════"
    local c; for c in "uname -a" "uptime" "free -h" "df -h" "lsblk" "ip a" \
                      "systemctl --failed" "journalctl -p err -n 50 --no-pager"; do
      echo; echo "────────────────────────────────────────────────────────"
      echo "Command: $c"
      echo "────────────────────────────────────────────────────────"
      eval "$c" 2>&1 || echo "(failed or unavailable)"
    done
    echo; echo "END OF REPORT"
  } > "$f"
  wt_msg "Report Generated" "Saved to:\n$f\n\nView with:\n  less $f" 12 72
}

# ═══════════════════════════════════════════════════════════════════════════
# STARTUP
# ═══════════════════════════════════════════════════════════════════════════
case "${1:-}" in
  --version|-v) echo "Swiss Army Knife Diagnostic Toolkit v$VERSION"; exit 0 ;;
  --help|-h)
    echo "Usage: $0 [--health|--report|--version|--help]"
    echo "  (no args)   launch the interactive menu"
    echo "  --health    run the health check"
    echo "  --report    export a full diagnostic report"
    echo "Env: SAK_TIMEOUT=<seconds> per-command timeout (default 120)"
    exit 0 ;;
esac

command -v whiptail &>/dev/null || { echo "ERROR: 'whiptail' is required. Install: sudo apt install whiptail"; exit 1; }
touch "$HISTORY_FILE" "$FAVORITES_FILE" 2>/dev/null || true

case "${1:-}" in
  --health) run_health_check; exit 0 ;;
  --report) export_full_report; exit 0 ;;
esac

# ═══════════════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════════════════
while true; do
  # Build sorted unique category list
  CATEGORIES=()
  for key in "${!MENU[@]}"; do
    cat="${key%%:*}"
    [[ " ${CATEGORIES[*]} " == *" $cat "* ]] || CATEGORIES+=("$cat")
  done
  IFS=$'\n' CATEGORIES=($(sort <<<"${CATEGORIES[*]}")); unset IFS

  CATEGORY_OPTIONS=("🔍 SEARCH" "Search all commands by keyword")
  for c in "${CATEGORIES[@]}"; do CATEGORY_OPTIONS+=("$c" "$c"); done

  CATEGORY=$(wt_menu "🧰 Swiss Army Knife Diagnostic Toolkit v$VERSION" \
    "Select a category (or search):" 26 74 16 "${CATEGORY_OPTIONS[@]}") || exit 0

  if [[ "$CATEGORY" == "🔍 SEARCH" ]]; then search_commands; continue; fi

  if [[ "$CATEGORY" == "Quick Actions" ]]; then
    QA=()
    for key in "${!MENU[@]}"; do [[ "$key" == "Quick Actions:"* ]] && QA+=("$key" "${MENU[$key]}"); done
    QA_CHOICE=$(wt_menu "Quick Actions" "Select an action:" 20 70 10 "${QA[@]}") || continue
    case "$QA_CHOICE" in
      "Quick Actions:HEALTH_CHECK")    run_health_check ;;
      "Quick Actions:EXPORT_REPORT")   export_full_report ;;
      "Quick Actions:SEARCH_COMMANDS") search_commands ;;
      "Quick Actions:VIEW_HISTORY")    view_history ;;
      "Quick Actions:VIEW_FAVORITES")  view_favorites ;;
    esac
    continue
  fi

  PAGE=0
  while true; do
    COMMANDS=()
    for key in "${!MENU[@]}"; do [[ "$key" == "$CATEGORY:"* ]] && COMMANDS+=("$key" "${MENU[$key]}"); done
    # sort command entries by description for stable, predictable order
    IFS=$'\n' SORTED=($(for ((i=0; i<${#COMMANDS[@]}; i+=2)); do printf '%s\t%s\n' "${COMMANDS[i]}" "${COMMANDS[i+1]}"; done | sort -t$'\t' -k2)); unset IFS
    COMMANDS=()
    for line in "${SORTED[@]}"; do COMMANDS+=("${line%%$'\t'*}" "${line#*$'\t'}"); done

    ITEMS_PER_PAGE=20
    START=$((PAGE * ITEMS_PER_PAGE))
    TOTAL_ITEMS=${#COMMANDS[@]}
    TOTAL_PAGES=$(( (TOTAL_ITEMS + ITEMS_PER_PAGE - 1) / ITEMS_PER_PAGE ))

    # Page slice + annotate missing tools with ⚠
    PAGE_OPTIONS=()
    for ((i=START; i<START+ITEMS_PER_PAGE && i<TOTAL_ITEMS; i+=2)); do
      k="${COMMANDS[i]}"; d="${COMMANDS[i+1]}"
      tool_available "${k#*:}" || d="⚠ $d"
      PAGE_OPTIONS+=("$k" "$d")
    done
    [[ $((START + ITEMS_PER_PAGE)) -lt $TOTAL_ITEMS ]] && PAGE_OPTIONS+=("NEXT" "Next page →")
    [[ $PAGE -gt 0 ]] && PAGE_OPTIONS+=("PREV" "← Previous page")
    PAGE_OPTIONS+=("BACK" "↩ Return to category menu")

    CHOICE=$(wt_menu "$CATEGORY  (page $((PAGE+1))/$TOTAL_PAGES)" "Select a command to run ( ⚠ = tool not installed ):" 25 100 16 "${PAGE_OPTIONS[@]}") || break
    case "$CHOICE" in
      NEXT) PAGE=$((PAGE+1)) ;;
      PREV) PAGE=$((PAGE-1)) ;;
      BACK) break ;;
      *)    execute_command "$CHOICE" ;;
    esac
  done
done
