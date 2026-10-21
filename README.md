# LaTeX-Kollaboration: Protokolle für Physik F-Praktikum & Synthesechemie

Dieses Repo dient der gemeinsamen Erstellung von Praktikumsprotokollen
(Physik F-Praktikum und Synthesechemie) von drei Personen.

## Struktur

```
LaTeX/
├── Praeambel.tex            zentrale Präambel (Pakete, eigene Befehle) für ALLE Protokolle
├── info.txt                 nützliche Pakete & Befehle für Physik/Chemie
├── 01-Physik-FPraktikum/    Muster-Protokoll Physik
│   ├── protokoll.tex        Hauptdatei
│   ├── literatur.bib
│   ├── Inhaltliches/        Kapitel-Dateien (ein Thema pro Datei)
│   └── Bilder/              Abbildungen
└── 02-Synthesechemie/       Muster-Protokoll Chemie
    ├── protokoll.tex
    ├── literatur.bib
    ├── Inhaltliches/
    └── Bilder/
```

## Neues Protokoll anlegen

1. Einen der Musterordner kopieren, z. B. `03-Physik-Versuch-YZ/`.
2. Titel und Autoren in `protokoll.tex` anpassen.
3. Kapitel in `Inhaltliches/` umbenennen/bearbeiten.
4. Die zentrale `Praeambel.tex` bleibt unverändert (Fix: `Praeambel.tex` im Hauptverzeichnis).
   In `protokoll.tex` steht deshalb `\input{../../Praeambel.tex}`.

## Kompilieren

```bash
latexmk -pdf protokoll.tex
# oder manuell:
pdflatex protokoll.tex && biber protokoll && pdflatex protokoll.tex && pdflatex protokoll.tex
```

## Zusammenarbeit (3 Personen)

- Jede/r arbeitet in einem eigenen Branch oder direkt im eigenen Kapitel,
  Konflikte in `Praeambel.tex` bitte im Team besprechen.
- Bilder mit aussagekräftigen Dateinamen in `Bilder/` ablegen.
- Paket-Vorschläge und nützliche Befehle: in `info.txt` eintragen.
