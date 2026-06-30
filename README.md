ubuntufetch

A minimal system‑fetch tool for Ubuntu 26.04 — inspired by neonfetch, but focused on clean output without ASCII noise.
🚀 Usage
bash

chmod +x ubuntufetch.sh
./ubuntufetch.sh

No sudo required.
📊 What it shows

    Hostname

    Kernel

    Uptime

    Shell

    CPU / RAM

    Disk usage

    Package count

    Desktop / WM

    GPU

    Network info

🔧 Customization
Toggle ASCII logo

In main(), comment out the call to
bash

print_ascii

to disable the logo.
Add more distributions

Extend the case block inside print_ascii:
bash

case "$DISTRO" in
    ubuntu)  print_ubuntu ;;
    debian)  print_debian ;;
    arch)    print_arch ;;
esac

Adjust colors

Modify the ANSI color variables at the top of the script:
bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

🎯 Goal

Provide straight system info, no ASCII clutter, no wasted space — just a fast, lightweight fetch tool for Ubuntu users who prefer clean output.
