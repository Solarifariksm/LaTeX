#!/usr/bin/env bash
# =====================================================================
#  install-fehlende-pakete.sh
#  Liest die LaTeX-Logdatei (protokoll.log) aus, findet fehlende Pakete
#  ("...sty not found" / "...cls not found") und installiert sie
#  automatisch - bevorzugt per tlmgr (TeX Live), sonst per apt.
#
#  Aufruf im Protokoll-Ordner nach einem gescheiterten Build:
#      ./../install-fehlende-pakete.sh protokoll.log
#  oder ohne Argument (dann wird protokoll.log im aktuellen Ordner benutzt)
# =====================================================================
set -euo pipefail

LOG="${1:-protokoll.log}"

if [ ! -f "$LOG" ]; then
    echo "Fehler: Logdatei '$LOG' nicht gefunden."
    echo "Erst einen Build versuchen: latexmk -pdf protokoll.tex"
    exit 1
fi

# Fehlende Pakete aus dem Log extrahieren (nur Dateinamen ohne Endung)
mapfile -t FEHLEND < <(
    grep -oE '(File|package)? ?`?[A-Za-z0-9._-]+\.(sty|cls|def|clo)"? (not found|not found\.)' "$LOG" \
    | grep -oE '[A-Za-z0-9._-]+\.(sty|cls|def|clo)' \
    | sed -E 's/\.(sty|cls|def|clo)$//' \
    | sort -u
)

if [ "${#FEHLEND[@]}" -eq 0 ]; then
    echo "Keine fehlenden Pakete im Log gefunden."
    echo "Falls der Build trotzdem fehlschlägt: Log auf andere Fehler prüfen:"
    echo "  grep -n '^!' $LOG"
    exit 0
fi

echo "Fehlende Pakete: ${FEHLEND[*]}"

# tlmgr verfügbar? (TeX Live / Debian-Paket texlive-base bringt tlmgr nicht immer mit)
if command -v tlmgr >/dev/null 2>&1; then
    echo "== Installiere per tlmgr (User-Modus) =="
    tlmgr init-usertree 2>/dev/null || true
    for p in "${FEHLEND[@]}"; do
        echo "-- tlmgr install $p"
        tlmgr --usermode install "$p" 2>/dev/null || tlmgr install "$p" || true
    done
elif command -v miktex packages >/dev/null 2>&1 || command -v mpm >/dev/null 2>&1; then
    echo "== MiKTeX erkannt: Pakete werden vom LaTeX-Lauf selbst nachgeladen =="
    echo "   (MiKTeX: Option 'Install missing packages on-the-fly' aktivieren)"
elif command -v apt >/dev/null 2>&1; then
    echo "== Installiere per apt (texlive-Paketgruppen) =="
    echo "   Empfehlung für vollständige Abdeckung: sudo apt install texlive-full"
    for p in "${FEHLEND[@]}"; do
        case "$p" in
            chemfig|chemmacros|mhchem|bpchem|isotope|modiagram|physics|siunitx)
                echo "-- apt install texlive-science (enthält $p)"
                sudo apt install -y texlive-science ;;
            sourcesanspro|lmodern|microtype)
                echo "-- apt install texlive-fonts-extra (enthält $p)"
                sudo apt install -y texlive-fonts-extra ;;
            pgfplots|tikz)
                echo "-- apt install texlive-pictures"
                sudo apt install -y texlive-pictures ;;
            biblatex|biber)
                echo "-- apt install texlive-bibtex-extra biber"
                sudo apt install -y texlive-bibtex-extra biber ;;
            mdframed|needspace)
                echo "-- apt install texlive-latex-extra"
                sudo apt install -y texlive-latex-extra ;;
            *)
                echo "-- Versuche texlive-latex-extra für $p"
                sudo apt install -y texlive-latex-extra ;;
        esac
    done
else
    echo "Weder tlmgr noch apt gefunden. Bitte Pakete manuell installieren:"
    printf '  - %s\n' "${FEHLEND[@]}"
    exit 1
fi

echo ""
echo "Fertig. Bitte Build wiederholen: latexmk -pdf protokoll.tex"
echo "Ggf. Skript erneut ausführen, wenn noch Pakete fehlen."
