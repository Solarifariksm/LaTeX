# LaTeX-Kollaboration: Protokolle für Physik F-Praktikum & Synthesechemie

Dieses Repo dient der gemeinsamen Erstellung von Praktikumsprotokollen
(Physik F-Praktikum und Synthesechemie) von drei Personen.

## Struktur

```
LaTeX/
├── Praeambel.tex            zentrale Präambel (Pakete, eigene Befehle) für ALLE Protokolle
├── info.txt                 nützliche Pakete & Befehle für Physik/Chemie + Protokoll-Regeln
├── Anleitung-Protokoll.pdf  offizielle Anleitung „Protokoll“ (Uni Kassel F-Praktikum)
├── 01-Physik-FPraktikum/    Muster-Protokoll Physik (Struktur gemäß Anleitung)
│   ├── protokoll.tex        Hauptdatei (Deckblatt, 
│   ├── literatur.bib        Versuchsnummer/Titel/Datum als Makros)
│   ├── Inhaltliches/        theorie → experimentelles → ergebnisse →
│   └── Bilder/               zusammenfassung_diskussion → literatur → anhang
└── 02-Synthesechemie/       Muster-Protokoll Chemie
    ├── protokoll.tex
    ├── literatur.bib
    ├── Inhaltliches/
    └── Bilder/
```

## Nachdem Änderungen gemacht wurden
```terminal
git add -A                     # alle deine Änderungen stagen
git commit -m "Kapitel Auswertung Versuch 42 ergänzt"   # mit aussagekräftiger Nachricht
git push                       # auf GitHub hochladen
```

## Die zentrale Praeambel einrichten

Die `Praeambel.tex` liegt im Repo-Root und wird von **jedem** Protokoll
zentral eingebunden. So richtest du sie ein bzw. verwendest sie:

1. **Einbinden im Protokoll:** In der Hauptdatei (`protokoll.tex`) direkt nach
   `\documentclass` eine Zeile ergänzen — da die Protokolle in Unterordnern
   liegen, mit relativem Pfad nach oben:
   ```latex
   \documentclass[11pt, a4paper, headings=small]{scrartcl}
   \input{../Praeambel.tex}   % eine Ebene nach oben zum Repo-Root
   ```
2. **Neues Protokoll auf gleicher Ebene**: derselbe Befehl
   `\input{../Praeambel.tex}` legt den Ort des Präambles fest. Dabei bedeutet '../', dass das Präamble in einem Übergeordneten Ordner liegt.
3. **Eigene Anpassungen:** Paket-Optionen und neue Pakete bitte **nur zentral**
   in `Praeambel.tex` ergänzen (nie in einzelnen Protokollen), damit alle
   Protokelle einheitlich aussehen und es keine Doppel-Ladungen gibt.
   Verschiedene Paket-Kategorien sind dort per Kommentarblöcken gegliedert
   (Mathematik, Chemie, Grafik, Optik, eigene Befehle …).
4. **Lokales Testen ohne Repo-Struktur:** Wenn du ein Protokoll-Verzeichnis
   allein kompilierst, funktioniert `\input{../Praeambel.tex}` nur, wenn
   der Ordner eine Ebene unter dem Repo-Root liegt. Am einfachsten immer
   das komplette Repo klonen und darin arbeiten.

## Enthaltene "design"-Pakete

| Paket | Zweck |
|---|---|
| `microtype` | bessere Typografie, sauberere Ränder |
| `enumitem` + `\setlist` | kompakte, aufgeräumte Listen |
| `caption`-Setup | kleine Captions mit fetter Nummer |
| `scrlayer-scrpage` | Kopfzeile mit Seitenzahl + Trennlinie, `parskip=half` |
| `csquotes` | typografisch korrekte Anführungszeichen (`\enquote{}`) |
| `wrapfig` | Textumlauf um kleine Abbildungen |
| `tabularx` / `longtable` | breite Tabellen / Tabellen über Seitengrenzen |
| `pdfpages` | gescannte Messprotokolle im Anhang einfügen |
| `todonotes` | offene Aufgaben im Text markieren (`\todo{}`) |
| `hyperref` (colorlinks) | klickbare Verweise in dezentem Dunkelgrau |

## Neues Protokoll anlegen

1. Einen der Musterordner kopieren, z. B. `03-Physik-Versuch-YZ/`.
2. Titel und Autoren in `protokoll.tex` anpassen.
3. Kapitel in `Inhaltliches/` umbenennen/bearbeiten.
4. Die zentrale `Praeambel.tex` bleibt unverändert (Fix: `Praeambel.tex` im Hauptverzeichnis).
   In `protokoll.tex` steht deshalb `\input{../Praeambel.tex}`.

## Kompilieren

```bash
latexmk -pdf protokoll.tex
# oder manuell:
pdflatex protokoll.tex && biber protokoll && pdflatex protokoll.tex && pdflatex protokoll.tex
```

### Fehlende Pakete automatisch installieren

Schlägt der Build mit `...sty not found` fehl, einmalig im Protokoll-Ordner:

```bash
../install-fehlende-pakete.sh protokoll.log   # liest das Log, installiert Fehlendes
latexmk -pdf protokoll.tex                    # Build wiederholen
```

Das Skript nutzt `tlmgr`, wenn verfügbar, sonst `apt` mit den passenden
`texlive-*`-Paketgruppen. MiKTeX-Nutzer: „Install missing packages
on-the-fly" in den MiKTeX-Optionen aktivieren, dann passiert es automatisch.
Einmal alles installieren (ca. 5–7 GB, danach sollte Ruhe sein):

```bash
sudo apt install texlive-full
```

## Zusammenarbeit (3 Personen)

- Jede/r arbeitet in einem eigenen Branch oder direkt im eigenen Kapitel,
  Konflikte in `Praeambel.tex` bitte im Team besprechen.
- Bilder mit aussagekräftigen Dateinamen in `Bilder/` ablegen.
- Paket-Vorschläge und nützliche Befehle: in `info.txt` eintragen.

## Auto-Sync: automatisch committen und pullen

Im Repo liegt `git-auto-sync.sh`. Es überwacht das Repo und führt bei
jeder Dateiänderung automatisch `git add -A && git commit && git pull &&
git push` aus — ihr müsst im Alltag gar nichts mehr tippen.

```bash
./git-auto-sync.sh               # Watch-Modus: synchronisiert beim Speichern
./git-auto-sync.sh --interval 60 # alternativ: alle 60 Sekunden
./git-auto-sync.sh --once        # genau ein Durchlauf (manuell)
```

Voraussetzungen: macOS `brew install fswatch`, Linux
`sudo apt install inotify-tools` (ohne beide: automatischer 60s-Fallback).
**Windows 11:** stattdessen `git-auto-sync.ps1` nutzen (PowerShell, keine
Zusatztools nötig — der Watch-Modus nutzt den eingebauten FileSystemWatcher):

```powershell
# PowerShell im Repo-Ordner:
.\git-auto-sync.ps1                        # Watch-Modus
.\git-auto-sync.ps1 -Interval 60           # alle 60 s
.\git-auto-sync.ps1 -Once                  # ein Durchlauf
# falls die Ausfuehrung blockiert wird:
powershell -ExecutionPolicy Bypass -File .\git-auto-sync.ps1
```

Für den Windows-Autostart: `Win+R` → `shell:startup` → eine Verknüpfung zu
diesem Befehl in den Ordner ziehen:
`powershell -ExecutionPolicy Bypass -File "C:\Pfad\zu\LaTeX\git-auto-sync.ps1"`

**Wichtig:** Bei einem Merge-Konflikt **hält das Skript an** und zerstört
nichts — es zeigt an, dass ihr von Hand auflösen müsst (Marker in der
Datei bearbeiten, dann `git add -A && git rebase --continue && git push`),
und macht erst weiter, wenn das Repo wieder sauber ist. Deshalb ist das
sicherer als ein blindes Cron-Skript, das Konflikte mit Kraft lösen würde.

Am bequemsten: das Skript beim Login im Hintergrund starten —
macOS (`launchd`) oder Linux (Systemd-User-Service):

```bash
# Linux: Unit in ~/.config/systemd/user/latex-autosync.service
[Service]
ExecStart=%h/Desktop/LaTeX/git-auto-sync.sh
[Install]
WantedBy=default.target
# dann: systemctl --user enable --now latex-autosync.service

# macOS: launchd-PLIST oder simpel per Autostart-Terminal-Command
open -a Terminal git-auto-sync.sh   # manuell, oder in Login-Items aufnehmen
```

## Fehler "Please clean your repository working tree before checkout" vermeiden

Der Fehler tritt auf, wenn beim Branch-Wechsel/Checkout uncommittete
Änderungen im Klon liegen, die Git nicht überschreiben darf. Vorbeugen:

1. **Häufig committen** — am besten nach jedem bearbeiteten Kapitel:
   ```bash
   git add -A && git commit -m "Kapitel X aktualisiert"
   git push
   ```
2. **Vor dem Branch-Wechsel/pull Status prüfen:** `git status` — wenn
   Dateien unter "Changes not staged" auftauchen: committen oder stashen.
3. **Mal schnell parken statt verlieren:**
   ```bash
   git stash        # Änderungen parken
   git pull         # aktualisieren
   git stash pop    # Änderungen zurückholen
   ```
4. **Build-Artefakte nie einchecken:** `.aux`, `.log`, `.pdf` etc. sind
   bereits in `.gitignore` — sie sollten bei `git status` nie als
   "untracked" auftauchen. Falls doch: `git clean -fdX` entfernt sie
   (Vorsicht: löscht alle ignorierten Dateien, auch gebaute PDFs).
5. **LaTeX-Editor-Automatik:** Falls VS Code beim Speichern automatisch
   buildet und dabei Dateien anlegt, die Git stören: die `.latexmkrc`
   im Protokoll-Ordner hält den Build im Ordner, und `.gitignore`
   fängt die Artefakte ab.
