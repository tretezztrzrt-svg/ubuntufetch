#!/usr/bin/env bash
# ============================================================
#  ubuntufetch – Kompaktes Systeminfo-Tool für Ubuntu
#  Stil: Neofetch-ähnlich, aber schlank und Ubuntu-proofed
# ============================================================

# ---------- Farben & Formatierung ----------
reset='\e[0m'
bold='\e[1m'
# Farben: 1=rot, 2=grün, 3=gelb, 4=blau, 5=magenta, 6=cyan, 7=weiß
title_col="${bold}\e[38;5;39m"    # hellblau
sub_col="${bold}\e[38;5;45m"      # türkis
info_col="\e[38;5;255m"           # hellgrau
colon_col="\e[38;5;244m"          # dunkelgrau
bar_col_elapsed="\e[38;5;46m"     # grün
bar_col_total="\e[38;5;240m"      # dunkelgrau

# ---------- Hilfsfunktionen ----------
has_cmd() { command -v "$1" &>/dev/null; }
trim() { echo -n "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
err() { echo -e "${bold}${info_col}⚠️  $*${reset}" >&2; }

# ---------- Systeminformationen sammeln ----------
get_distro() {
    if has_cmd lsb_release; then
        distro="$(lsb_release -ds 2>/dev/null)"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$PRETTY_NAME"
    else
        distro="$(uname -s) $(uname -r)"
    fi
    # Architektur anhängen
    arch="$(uname -m)"
    [[ "$arch" =~ (x86_64|i686|arm64) ]] && distro="$distro $arch"
}

get_host() { hostname="$(hostname)"; }
get_kernel() { kernel="$(uname -r)"; }
get_uptime() {
    if [[ -f /proc/uptime ]]; then
        s=$(cut -d. -f1 /proc/uptime)
    else
        boot="$(date -d"$(uptime -s)" +%s 2>/dev/null || echo 0)"
        now="$(date +%s)"
        s="$((now - boot))"
    fi
    d="$((s/86400))"; h="$(((s%86400)/3600))"; m="$(((s%3600)/60))"
    uptime=""
    ((d>0)) && uptime+="${d}d "
    ((h>0)) && uptime+="${h}h "
    ((m>0)) && uptime+="${m}m"
    [[ -z "$uptime" ]] && uptime="${s}s"
}

get_packages() {
    if has_cmd dpkg; then
        packages="$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)"
        packages="$packages (dpkg)"
    else
        packages="n/a"
    fi
}

get_shell() {
    shell="${SHELL##*/}"
    if [[ "$shell" = bash ]]; then
        shell="$shell $BASH_VERSION"
    elif has_cmd "$SHELL"; then
        ver="$("$SHELL" --version 2>/dev/null | head -1 | awk '{print $NF}')"
        [[ -n "$ver" ]] && shell="$shell $ver"
    fi
}

get_resolution() {
    if has_cmd xrandr && [[ -n "$DISPLAY" ]]; then
        resolution="$(xrandr --nograb --current | awk '/ connected .*[0-9]+x[0-9]+\+/ && !/primary/ {print $3; exit}')"
        [[ -z "$resolution" ]] && resolution="$(xrandr --nograb --current | awk '/ primary/ {print $4; exit}')"
        resolution="${resolution%+*}"
    else
        resolution="n/a"
    fi
}

get_de() {
    if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
        de="$XDG_CURRENT_DESKTOP"
    elif [[ -n "$DESKTOP_SESSION" ]]; then
        de="${DESKTOP_SESSION##*/}"
    elif [[ -n "$GNOME_DESKTOP_SESSION_ID" ]]; then
        de="GNOME"
    elif [[ -n "$MATE_DESKTOP_SESSION_ID" ]]; then
        de="MATE"
    else
        de="n/a"
    fi
    [[ "$de" =~ (X-|:ubuntu) ]] && de="${de//X-/}"
}

get_wm() {
    if [[ -n "$XDG_CURRENT_DESKTOP" ]] && [[ "$XDG_SESSION_TYPE" = wayland ]]; then
        # Wayland compositor
        wm="$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')"
    elif has_cmd xprop && [[ -n "$DISPLAY" ]]; then
        wm="$(xprop -root -notype _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk -F'"' '{print $2}')"
    fi
    [[ -z "$wm" ]] && wm="n/a"
}

get_theme_icons() {
    if has_cmd gsettings; then
        theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"
        icons="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
    elif has_cmd xfconf-query; then
        theme="$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)"
        icons="$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null)"
    fi
    [[ -z "$theme" ]] && theme="n/a"
    [[ -z "$icons" ]] && icons="n/a"
}

get_term() {
    term="${TERM_PROGRAM:-${TERM}}"
    [[ -n "$SSH_CONNECTION" ]] && term="$SSH_TTY"
    [[ -n "$WT_SESSION" ]] && term="Windows Terminal"
    [[ -z "$term" ]] && term="unknown"
}

get_cpu() {
    cpu_model="$(lscpu 2>/dev/null | awk -F': +' '/Model name/ {print $2; exit}')"
    [[ -z "$cpu_model" ]] && cpu_model="$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2-)"
    cores="$(nproc 2>/dev/null)"
    [[ -z "$cores" ]] && cores="$(grep -c '^processor' /proc/cpuinfo)"
    # Temp
    if [[ -d /sys/class/thermal/thermal_zone0 ]]; then
        temp_raw="$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"
        if [[ -n "$temp_raw" ]]; then
            temp_c="$((temp_raw / 1000))"
            [[ "$temp_c" -gt 0 ]] && cpu_temp=" [${temp_c}°C]"
        fi
    fi
    # Speed
    speed_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
    if [[ -f "$speed_file" ]]; then
        speed="$(($(< "$speed_file") / 1000))"
        if (( speed > 1000 )); then
            speed="$(awk "BEGIN {printf \"%.1f\", $speed/1000}")GHz"
        else
            speed="${speed}MHz"
        fi
    else
        speed=""
    fi
    cpu="$cpu_model (${cores})${cpu_temp:+ $cpu_temp}${speed:+ @ $speed}"
}

get_gpu() {
    gpu="$(lspci -mm | awk -F'"' '/"Display|"3D|"VGA/ {print $4 " " $6; exit}')"
    [[ -z "$gpu" ]] && gpu="n/a"
}

get_memory() {
    mem_total_kb="$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')"
    mem_avail_kb="$(grep '^MemAvailable:' /proc/meminfo | awk '{print $2}')"
    if [[ -n "$mem_avail_kb" ]]; then
        mem_used_kb="$((mem_total_kb - mem_avail_kb))"
    else
        mem_free_kb="$(grep '^MemFree:' /proc/meminfo | awk '{print $2}')"
        buffers="$(grep '^Buffers:' /proc/meminfo | awk '{print $2}')"
        cached="$(grep '^Cached:' /proc/meminfo | awk '{print $2}')"
        sreclaim="$(grep '^SReclaimable:' /proc/meminfo | awk '{print $2}')"
        mem_used_kb="$((mem_total_kb - mem_free_kb - buffers - cached - sreclaim))"
    fi
    mem_total="$((mem_total_kb / 1024))"
    mem_used="$((mem_used_kb / 1024))"
    mem_perc="$((mem_used * 100 / mem_total))"
    memory="${mem_used}MiB / ${mem_total}MiB (${mem_perc}%)"
}

get_disk() {
    disk_used="$(df -h / | awk 'NR==2 {print $3}')"
    disk_total="$(df -h / | awk 'NR==2 {print $2}')"
    disk_perc="$(df -h / | awk 'NR==2 {print $5}')"
    disk="${disk_used} / ${disk_total} (${disk_perc})"
}

get_local_ip() {
    # Default route interface
    iface="$(ip route | awk '/default/ {print $5; exit}')"
    if [[ -n "$iface" ]]; then
        ip_addr="$(ip -4 addr show "$iface" | awk '/inet / {print $2; exit}')"
        ip_addr="${ip_addr%/*}"
    fi
    [[ -z "$ip_addr" ]] && ip_addr="n/a"
}

# ---------- ASCII Logo ----------
print_ascii() {
    # Kurzes Logo für Ubuntu und einige andere; falls unbekannt, generisches Linux
    case "$distro" in
        *"Ubuntu"*)
            cat <<'EOF'
${c1}            .-/+oossssoo+\-.
        ´:+ssssssssssssssssss+:`
      -+ssssssssssssssssssyyssss+-
    .ossssssssssssssssss${c2}dMMMNy${c1}sssso.
   /sssssssssss${c2}hdmmNNmmyNMMMMh${c1}ssssss\
  +sssssssss${c2}hm${c1}yd${c2}MMMMMMMNddddy${c1}ssssssss+
 /ssssssss${c2}hNMMM${c1}yh${c2}hyyyyhmNMMMNh${c1}ssssssss\
.ssssssss${c2}dMMMNh${c1}ssssssssss${c2}hNMMMd${c1}ssssssss.
+ssss${c2}hhhyNMMNy${c1}ssssssssssss${c2}yNMMMy${c1}sssssss+
oss${c2}yNMMMNyMMh${c1}ssssssssssssss${c2}hmmmh${c1}ssssssso
oss${c2}yNMMMNyMMh${c1}sssssssssssssshmmmh${c1}ssssssso
+ssss${c2}hhhyNMMNy${c1}ssssssssssss${c2}yNMMMy${c1}sssssss+
.ssssssss${c2}dMMMNh${c1}ssssssssss${c2}hNMMMd${c1}ssssssss.
 \ssssssss${c2}hNMMM${c1}yh${c2}hyyyyhdNMMMNh${c1}ssssssss/
  +sssssssss${c2}dm${c1}yd${c2}MMMMMMMMddddy${c1}ssssssss+
   \sssssssssss${c2}hdmNNNNmyNMMMMh${c1}ssssss/
    .ossssssssssssssssss${c2}dMMMNy${c1}sssso.
      -+sssssssssssssssss${c2}yyy${c1}ssss+-
        `:+ssssssssssssssssss+:`
            .-\+oossssoo+/-.
EOF
        ;;
        *"Debian"*)
            cat <<'EOF'
${c1}       _,met$$$$$gg.
    ,g$$$$$$$$$$$$$$$P.
  ,g$$P"        """Y$$.".
 ,$$P'              `$$$.
',$$P       ,ggs.     `$$b:
`d$$'     ,$P"'   ${c2}.${c1}    $$$
 $$P      d$'     ${c2},${c1}    $$P
 $$:      $$.   ${c2}-${c1}    ,d$$'
 $$;      Y$b._   _,d$P'
 Y$$.    ${c2}`.${c1}`"Y$$P"'
${c1} `$$b      ${c2}"-.__
${c1}  `Y$$
   `Y$$.
     `$$b.
       `Y$$b.
          `"Y$b._
              `"""
EOF
        ;;
        *"Fedora"*)
            cat <<'EOF'
${c1}             .',;::::;,'.
         .';:cccccccccccc:;,.     
      .;cccccccccccccccccccccc;.
    .:cccccccccccccccccccccccccc:.
  .;ccccccccccccc;${c2}.:dddl:.${c1};ccccccc;.
 .:ccccccccccccc;${c2}OWMKOOXMWd${c1};ccccccc:.
.:ccccccccccccc;${c2}KMMc${c1};cc;${c2}xMMc${c1};ccccccc:.
,cccccccccccccc;${c2}MMM.${c1};cc;${c2};WW:${c1};cccccccc,
:cccccccccccccc;${c2}MMM.${c1};cccccccccccccccc:
:ccccccc;${c2}oxOOOo${c1};${c2}MMM0OOk.${c1};cccccccccccc:
cccccc;${c2}0MMKxdd:${c1};${c2}MMMkddc.${c1};cccccccccccc;
ccccc;${c2}XM0'${c1};cccc;${c2}MMM.${c1};cccccccccccccccc'
ccccc;${c2}MMo${c1};ccccc;${c2}MMW.${c1};ccccccccccccccc;
ccccc;${c2}0MNc.${c1}ccc${c2}.xMMd${c1};ccccccccccccccc;
cccccc;${c2}dNMWXXXWM0:${c1};cccccccccccccc:,
cccccccc;${c2}.:odl:.${c1};cccccccccccccc:,.
:cccccccccccccccccccccccccccc:'.
.:cccccccccccccccccccccc:;,..
  '::cccccccccccccc::;,.
EOF
        ;;
        *"Arch"*)
            cat <<'EOF'
${c1}                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:++oooo+:
            `/++++/+++++++:
           `/++++++++++++++:
          `/+++o${c2}oooooooo${c1}oooo/`
${c2}         ${c1}./${c2}ooosssso++osssssso${c1}+`
${c2}        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/
 .`                                 `/
EOF
        ;;
        *"Manjaro"*)
            cat <<'EOF'
${c1}██████████████████  ████████
██████████████████  ████████
██████████████████  ████████
██████████████████  ████████
████████            ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
████████  ████████  ████████
EOF
        ;;
        *)
            # Generisches Linux-Logo
            cat <<'EOF'
${c2}        #####
${c2}       #######
${c2}       ##${c1}O${c2}#${c1}O${c2}##
${c2}       #${c3}#####${c2}#
${c2}     ##${c1}##${c3}###${c1}##${c2}##
${c2}    #${c1}##########${c2}##
${c2}   #${c1}############${c2}##
${c2}   #${c1}############${c2}###
${c3}  ##${c2}#${c1}###########${c2}##${c3}#
${c3}######${c2}#${c1}#######${c2}#${c3}######
${c3}#######${c2}#${c1}#####${c2}#${c3}#######
${c3}  #####${c2}#######${c3}#####
EOF
        ;;
    esac
}

# ---------- Hauptausgabe ----------
main() {
    # Farben für ASCII-Logo setzen (feste Farben)
    c1="${bold}\e[38;5;39m"   # blau
    c2="${bold}\e[38;5;45m"   # türkis
    c3="${bold}\e[38;5;220m"  # gelb
    c4="${bold}\e[38;5;196m}" # rot

    # Informationen sammeln
    get_distro
    get_host
    get_kernel
    get_uptime
    get_packages
    get_shell
    get_resolution
    get_de
    get_wm
    get_theme_icons
    get_term
    get_cpu
    get_gpu
    get_memory
    get_disk
    get_local_ip

    # Ausgabe – max. Breite berechnen (für Alignment)
    max_len=0
    declare -A lines
    lines=(
        ["OS"]="$distro"
        ["Host"]="$hostname"
        ["Kernel"]="$kernel"
        ["Uptime"]="$uptime"
        ["Packages"]="$packages"
        ["Shell"]="$shell"
        ["Resolution"]="$resolution"
        ["DE"]="$de"
        ["WM"]="$wm"
        ["Theme"]="$theme"
        ["Icons"]="$icons"
        ["Terminal"]="$term"
        ["CPU"]="$cpu"
        ["GPU"]="$gpu"
        ["Memory"]="$memory"
        ["Disk (/)"]="$disk"
        ["Local IP"]="$ip_addr"
    )

    # Länge der längsten Überschrift ermitteln
    for key in "${!lines[@]}"; do
        len="${#key}"
        (( len > max_len )) && max_len="$len"
    done
    # Spaltenbreite: Überschrift + 2 Leerzeichen + Doppelpunkt
    col_width="$((max_len + 2))"

    # Ausgabe auf Terminal (mit Farben)
    echo -e "${title_col}${bold}$(hostname) System Info${reset}"
    echo -e "${sub_col}${bold}$distro${reset}\n"

    # ASCII-Logo ausgeben (optional)
    print_ascii

    # Info-Zeilen ausgeben
    for key in "OS" "Host" "Kernel" "Uptime" "Packages" "Shell" "Resolution" "DE" "WM" "Theme" "Icons" "Terminal" "CPU" "GPU" "Memory" "Disk (/)" "Local IP"; do
        value="${lines[$key]}"
        # Führende/trailing Whitespace entfernen
        value="$(trim "$value")"
        printf "${sub_col}%-${col_width}s${colon_col}:${info_col} %s${reset}\n" "$key" "$value"
    done

    echo -e "\n${bold}${info_col}Report generated: $(date '+%Y-%m-%d %H:%M:%S')${reset}"
}

# ---------- Start ----------
main "$@"
