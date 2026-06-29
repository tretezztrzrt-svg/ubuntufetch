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

✨ Was das Skript bietet

    Alle wichtigen Systeminfos auf einen Blick.

    Farbige, übersichtliche Ausgabe mit automatischem Alignment.

    Fehlertoleranz – fehlende Befehle (z.B. xrandr, gsettings) führen nicht zum Abbruch, sondern zeigen „n/a“.

    ASCII-Logo für Ubuntu, Debian, Fedora, Arch, Manjaro und ein generisches Linux-Logo.

    Kompakt – nur ca. 250 Zeilen, leicht erweiterbar.

    Keine Abhängigkeiten außer den Standard‑Ubuntu‑Tools (die meisten sind ohnehin installiert).

🔧 Anpassungen

    Logo aus-/einschalten: Kommentieren Sie den Aufruf print_ascii in der main()‑Funktion aus, wenn Sie kein Logo möchten.

    Weitere Distributionen: Fügen Sie einfach einen neuen Fall in der case‑Anweisung im print_ascii‑Block hinzu.

    Farben: Passen Sie die Variablen am Anfang des Skripts an (ANSI‑Codes).
