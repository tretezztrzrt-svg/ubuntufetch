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

# Skript speichern und ausführbar machen
chmod +x ubuntufetch

# Ausführen (kein sudo nötig)
./ubuntufetch

📊 Was das Skript liefert
<img width="433" height="400" alt="grafik" src="https://github.com/user-attachments/assets/a22b60b5-e2c2-40de-89b9-c4ce7799a085" />



🔧 Anpassungen

Logo aus-/einschalten: Kommentieren Sie den Aufruf print_ascii in der main()‑Funktion aus, wenn Sie kein Logo möchten.
Weitere Distributionen: Fügen Sie einfach einen neuen Fall in der case‑Anweisung im print_ascii‑Block hinzu.
Farben: Passen Sie die Variablen am Anfang des Skripts an (ANSI‑Codes).
