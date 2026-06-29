# ubuntufetch
neonfetch -but new in ubuntu 26.04

🚀 Verwendung

    Speichern Sie das Skript z.B. als ubuntufetch und machen Sie es ausführbar:
    bash

    chmod +x ubuntufetch

    Ausführen (kein sudo nötig):
    bash

    ./ubuntufetch

    Optional können Sie es in Ihr $PATH‑Verzeichnis legen (z.B. ~/.local/bin/).

📊 Was das Skript liefert
    Info	Quelle
    OS	lsb_release + Architektur
    Host	hostname
    Kernel	uname -r
    Uptime	/proc/uptime
    Packages	dpkg-query
    Shell	$SHELL + Version
    Resolution	xrandr
    DE	$XDG_CURRENT_DESKTOP u.a.
    WM	xprop oder Wayland
    Theme	gsettings
    Icons	gsettings
    Terminal	$TERM_PROGRAM
    CPU	lscpu + Temperatur + Takt
    GPU	lspci
    Memory	/proc/meminfo
    Disk (/)	df -h /
    Local IP	ip route + ip addr
🔧 Anpassungen

    Logo aus-/einschalten: Kommentieren Sie den Aufruf print_ascii in der main()‑Funktion aus, wenn Sie kein Logo möchten.

    Weitere Distributionen: Fügen Sie einfach einen neuen Fall in der case‑Anweisung im print_ascii‑Block hinzu.

    Farben: Passen Sie die Variablen am Anfang des Skripts an (ANSI‑Codes).
