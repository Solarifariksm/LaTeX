# Arbeitsanleitung: Protokolle in VS Code (für alle 3 Personen)

Diese Datei einmal lesen, dann läuft der Alltag mit 5 Befehlen.

## Einmalige Einrichtung (pro Person)

1. Repo klonen: `git clone https://github.com/Solarifariksm/LaTeX.git`
2. VS Code: Ordner **LaTeX** als Workspace öffnen (File → Open Folder, nicht einzelne Dateien!)
3. VS Code Extensions installieren:
   - **LaTeX Workshop** (Build + PDF-Vorschau)
   - **GitLens** (optional, zeigt wer was geändert hat)
4. TeX Live installieren: `sudo apt install texlive-full` (oder das
   Skript `install-fehlende-pakete.sh` nutzen, siehe README)

## Neue Protokolle / neue Versuche

Ordner kopieren (z. B. `01-Physik-FPraktikum` → `03-Versuch-XY`), dann in
`protokoll.tex` nur die drei Makros anpassen:

```latex
\newcommand{\Versuchsnummer}{V42}
\newcommand{\Versuchstitel}{Titel des Versuchs}
\newcommand{\Durchfuehrungsdatum}{05.11.2025}
```

Kapitel jeweils in `Inhaltliches/` bearbeiten (eine Datei pro Abschnitt).

## Der normale Arbeitstag (wichtigste Abschnitt)

Bevor du anfängst — **immer als Erstes**:

```bash
git pull
```

Dann: in VS Code die `.tex`-Datei öffnen und schreiben. Build/Vorschau:
- `Strg+Alt+B` = kompilieren (latexmk)
- `Strg+Alt+V` = PDF-Vorschau daneben

Am Ende der Sitzung — **immer als Letztes**:

```bash
git add -A
git commit -m "Kapitel Auswertung Versuch V42 ergänzt"
git push
```

Das war der ganze Alltag: **pull → schreiben → commit → push.**

## Regeln, die Konflikte vermeiden

1. **Häufig committen** — nach jedem fertigen Abschnitt, nicht erst nach
   Stunden. Kleine Commits lassen sich fehlerfrei zusammenführen.
2. **Nicht gleichzeitig in derselben Datei schreiben.** Teilt Kapitel auf
   (Person A: Auswertung, B: Grundlagen, C: Diskussion) und sagt euch das.
   Die Dateien in `Inhaltliches/` sind genau dafür einzeln.
3. **`Praeambel.tex` nur nach Absprache ändern** — sie gilt für ALLE
   Protokolle; Änderungen besprechen, sonst brechen bei allen die Builds.
4. Vor jedem `git pull`/Branch-Wechsel: offene Änderungen committen
   (`git status` sollte clean sein), sonst kommt
   "Please clean your repository working tree".

## Wenn doch mal ein Konflikt passiert

Git markiert die Stelle in der Datei:

```
<<<<<<< HEAD
deine Zeile
=======
die Zeile des anderen
>>>>>>> origin/main
```

In VS Code: auf **Accept Both Changes** klicken (oder die gewünschte
Zeile behalten, Marker löschen), speichern, dann:

```bash
git add <datei>
git commit -m "Konflikt gelöst"
git push
```

## Typische Fehler & schnelle Fixes

| Fehler | Fix |
|---|---|
| `...sty not found` | `../install-fehlende-pakete.sh protokoll.log`, dann neu bauen |
| `File Praeambel.tex not found` | Im Protokoll-Ordner bauen, Repo als Workspace geöffnet? |
| `Please clean working tree` | `git status`, offene Änderungen committen/stashen |
| PDF wird nicht aktueller | latexmk läuft? `Strg+Alt+B` erneut, Aux-Dateien löschen: `latexmk -C` |
