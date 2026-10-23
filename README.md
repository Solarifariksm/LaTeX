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

### Vorschau in VS Code

VS Code empfiehlt für dieses Repository die Erweiterung **LaTeX Workshop**.
Öffne `protokoll.tex` und starte einmal den Befehl
**LaTeX Workshop: View LaTeX PDF file**. Die PDF erscheint dann rechts neben
dem Quelltext und wird bei Änderungen automatisch aktualisiert. Die
Workspace-Einstellungen gelten für beide Protokollordner.

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

Im Repo liegt `git-auto-sync.sh`. Es überwacht das Repo und committet lokale
Änderungen automatisch. Anschließend holt es auch bei einem sauberen lokalen
Arbeitsverzeichnis neue Commits vom konfigurierten Upstream-Branch und pusht
eigene Commits dorthin. Voraussetzung ist ein eingerichteter Upstream (z. B.
`git push -u origin main`).

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

**Wichtig:** Bei einem Rebase-Konflikt verändert das Skript den Konfliktzustand
nicht weiter. Konflikte von Hand auflösen, danach `git add -A &&
git rebase --continue`; der nächste Sync-Durchlauf pusht anschließend den
integrierten Stand.

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

===============================================================================
INFO – Nützliche LaTeX-Pakete & Befehle für Physik- und Chemie-Protokolle
================================================================================

fügt gerne selbst Nützliches hinzu!

--------------------------------------------------------------------------------
1) CHEMIE – Analyse & Darstellung chemischer Verbindungen
--------------------------------------------------------------------------------

mhchem (in Präambel: \usepackage[version=4]{mhchem})
  Chemische Formeln im Fließ- und Mathe-Modus:
    \ce{H2O}                    ->  H2O
    \ce{2H2 + O2 -> 2H2O}       ->  Reaktionsgleichungen
    \ce{SO4^2-}                 ->  Ionen mit Ladungen
    \ce{^{227}_{90}Th+}         ->  Nuklide (Massen-/Ordnungszahl)
    \ce{A ->[T][\Delta] B}      ->  Pfeile mit Bedingungen über/unter dem Pfeil
    \ce{C6H5-NO2}               ->  organische Summenformeln

chemmacros (\usepackage{chemmacros}, \usechemmodule{all})
  Einheiten, Prozesse, Reaktionstypen:
    \begin{reaction} A + B -> C \end{reaction}   % nummerierte Reaktionen
    \pH, \pOH, \pKa, \pKb                         % typografisch korrekt
    \el                                            % Elektronen-Symbol
    \NewChemPhase                                  % Zustände (s), (l), (g)

bpchem (\usepackage{bpchem})
  Nomenklatur: \newreaction{ox}{Oxidation} – Reaktions-Nummern referenzierbar

isotope (\usepackage{isotope})
  \isotope{14}, \isotope[14]{C} – Isotope/Zerfallsreihen sauber setzen

modiagram (\usepackage{modiagram})
  Molekülorbital-/Orbital-Diagramme, z. B. \modiagram{...}

--------------------------------------------------------------------------------
2) CHEMIE – Apparaturen (Synthesechemie)
--------------------------------------------------------------------------------

chemfig + TikZ: Destillations-/Reflux-Apparaturen zeichnen.
  Fertige Symbolik (Kolben, Kühler): Paket "chemplants" (CTAN) –
  z. B. \chemname{\chemfig{...}}{Rundkolben}
  Alternative: "tikz-chemistry", chemische Apparaturen als TikZ-Bausteine.

--------------------------------------------------------------------------------
3) PHYSIK – Rechnen, Fehlerrechnung, Einheiten
--------------------------------------------------------------------------------

siunitx (\usepackage{siunitx})
  \SI{9.81}{\meter\per\square\second}   % Zahl + Einheit korrekt gesetzt
  \si{\kilo\gram\per\cubic\meter}       % reine Einheit
  \SI{3(1)}{\meter}                     % 3±1 direkt in der Klammer!
  \num{1.23e4}                          % Zahlen formatieren
  \SIrange{10}{20}{\degreeCelsius}      % Wertebereiche: 10 bis 20 °C

physics (\usepackage{physics})
  \dv{x}, \dv[2]{f}{x}      % Ableitungen (auch partiell: \pdv)
  \abs{x}, \norm{v}         % Betrag, Norm
  \bra{\psi}, \ket{\psi}, \braket{a}{b}   % Dirac-Notation (Quantenmechanik!)
  \commutator{A}{B}         % Kommutator [A,B]

Fehlerrechnung (in Präambel definiert):
  \errval{12.3}{0.4}         % (12.3 ± 0.4)
  \gausserror                % Formelgerüst Gauß'sche Fehlerfortpflanzung

Feynman-Diagramme: \usepackage{feynmp-auto} (MetaPost) oder
  TikZ-Library "feynman": \tikzfeynmanset{}

--------------------------------------------------------------------------------
4) GRAFIK & PLOTS
--------------------------------------------------------------------------------

pgfplots (\usepackage{pgfplots}, \pgfplotsset{compat=1.18})
  Achsen, Fehlerbalken, Fits – direkt im LaTeX-Code:
    \begin{axis}[xlabel={t in \si{\second}}, ylabel={s in \si{\meter}}]
      \addplot+[only marks, error bars/.cd, y dir=both, y explicit]
        coordinates {(0,0) (1,1.1) (2,2.05)};

tikz + libraries (siehe Präambel)
  Schaltkreise: \usetikzlibrary{circuits}
  Optik:        \usetikzlibrary{optics}   (im Paket "tikz-optics")

Für Messdaten-Auswertung: gnuplot (\usepackage{gnuplottex}) oder
  Python (matplotlib) -> PDF exportieren -> mit \includegraphics einbinden.

--------------------------------------------------------------------------------
5) TABELLEN, CAPTIONS, LAYOUT
--------------------------------------------------------------------------------

booktabs  – professionelle Tabellen: \toprule \midrule \bottomrule
multirow  – mehrzeilige Zellen
caption   – Caption-Formatierung, z. B. \captionsetup{font=small}
subcaption – Teilbilder (a), (b) mit eigener Unterschrift
float     – Abbildungen exakt platzieren mit [H]
tabularx  – Tabellen mit automatischer Breitenanpassung

KOMA-Script (dokumentklassen scrubook/art, hier: scrreprt):
  \KOMAoption{captions}{tableheading}
  \setcapindent{0pt}       % Captions bündig

--------------------------------------------------------------------------------
6) LITERATUR & VERWEISE
--------------------------------------------------------------------------------

biblatex + biber (in Präambel konfiguriert):
  \cite{Author2023}          % Zitate im Text
  \printbibliography         % Literaturverzeichnis am Ende
  Literatur.bib im Protokoll-Ordner pflegen.

cleveref – \cref{eq:nernst}, \cref{fig:aufbau} – Referenzen mit
  automatischer Bezeichnung ("Gl. (3)", "Abb. 4").
hyperref – klickbare Verweise, [hidelinks] = keine roten Kasten.

--------------------------------------------------------------------------------
7) PROTOKOLL-Vorgaben
--------------------------------------------------------------------------------

Aufbau (Pflichtteile, exakt in dieser Reihenfolge):
  1. Deckblatt: Namen (gerne mit E-Mail), „Fortgeschrittenen-Praktikum",
     Versuchsnummer und -titel, Datum der Durchführung
  2. Theoretische Grundlagen: max. 2 Seiten; ALLE für die Auswertung
     benötigten Gleichungen; alle Formelzeichen im Text erläutern
  3. Experimentelles: Aufbau skizzieren, Durchführung kurz aber genau,
     ALLE Einstellungen protokollieren
  4. Ergebnisse: erst Originaldaten, dann abgeleitete Werte; zu JEDEM
     berechneten Wert Fehlerbetrachtung; Fehlerbalken in Auftragungen
  5. Zusammenfassung & Diskussion: Ergebnisse inkl. Fehler + Literaturwerte
     in derselben Einheit; statistische vs. systematische Fehlerquellen
  6. Anhang: Messprotokoll vom Versuchstag; bei Zweitabgabe korrigierte
     Version(en)

Schreibweise:
  - neutrale Erzählperspektive, KEINE Ich-Form
  - kurz & prägnant, keine Redundanzen, auf Rechtschreibung achten

Abbildungen/Auftragungen:
  - fortlaufende Nummerierung + Bildunterschrift (selbsterklärend,
    keine Interpretationen in der Caption)
  - Achsen IMMER mit Einheiten beschriften
  - Einheiten so wählen, dass viele Nullen vermieden werden
    (0,1 mA statt 0,0001 A; 10 km statt 10 000 m)
  - Datenpunkte groß genug, aber Fehlerbalken erkennbar
  - fremde Abbildungen mit Quellenangabe

Zahlen & Fehler:
  - Signifikanz des Ergebnisses = niedrigste Signifikanz der Ausgangswerte
  - SI-Einheiten verwenden; sinnvolle Zehnerpotenz/Präfixe
  - Wert und Fehler: dieselbe Einheit, dieselbe Anzahl Nachkommastellen
  - Fehler GRUNDSÄTZLICH aufrunden, z. B. (7,8 ± 0,1) mA

Fehlerbetrachtung:
  - Mittelwert:        x̄ = (1/N) Σ x_i
  - Standardabweichung: σ = sqrt( 1/(N-1) Σ (x̄ - x_i)^2 )
  - Fehler des Mittelwerts: Δx = σ/sqrt(N)
  - Gauß'sche Fehlerfortpflanzung (unkorreliert):
    Δy = sqrt( Σ (∂y/∂x_i)^2 · Δx_i^2 )
  - Fehler ehrlich abschätzen; im Zweifel überschätzen

Literatur:
  - keine Internetquellen für Literaturwerte; Fachzeitschriften/Bücher
  - EIN Zitierstil für alle Quellen; Quelle muss auffindbar sein

--------------------------------------------------------------------------------
8) SONSTIGES NÜTZLICHES
--------------------------------------------------------------------------------

microtype     – bessere Typografie (immer laden!)
todonotes    – \todo{Noch messen!} – bunte Notizen am Rand
listings     – Code-Schnipsel (z. B. Auswertungs-Skripte) sauber setzen
minted       – Syntax-Highlighting (benötigt Pygments, -shell-escape)
xcolor       – eigene Farben: \definecolor{TUgreen}{RGB}{0,122,54}
wrapfig      – Textumlauf um Abbildungen
algorithm2e  – Pseudocode / Rechenwege übersichtlich darstellen

Compilieren mit pdfLaTeX, Literatur mit biber:
  pdflatex protokoll.tex && biber protokoll && pdflatex protokoll.tex && pdflatex protokoll.tex
  (empfohlen: latexmk -pdf protokoll.tex – automatisiert alles)

--------------------------------------------------------------------------------
9) STRUKTUR DIESES REPOS
--------------------------------------------------------------------------------

Rechnerordner pro Protokoll (z. B. 01-Physik-Versuch-XY, 02-Chemie-Synthese-AB):

  <Protokoll-Ordner>/
      protokoll.tex            Hauptdatei (documentclass, \input der Kapitel)
      literatur.bib            pro Protokoll eigene Bibliographie
      Inhaltliches/            die Kapitel (zur Übersicht, je Versuchsteil eine Datei)
      Bilder/                  Abbildungen, Plots, Scan-Skizzen

  Praeambel.tex (Repo-Root)   zentrale Pakete & eigene Befehle für ALLE Protokolle
  info.txt                    diese Datei

  Neue Protokolle: Ordner kopieren (z. B. 03-Physik-Versuch-YZ) und
  Hauptdatei-Inhalt anpassen – Praeambel bleibt zentral.

================================================================================
