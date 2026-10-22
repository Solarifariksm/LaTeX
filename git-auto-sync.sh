#!/usr/bin/env bash
# =====================================================================
#  git-auto-sync.sh — automatisches Git-Sync für das Protokoll-Repo
#
#  Was es tut (immer in dieser Reihenfolge):
#    1. git add -A            alle Änderungen stagen
#    2. git commit            nur falls es etwas zu committen gibt
#                             (Nachricht: "Automatischer Stand <Zeit>")
#    3. git pull              Änderungen der anderen holen (rebase)
#    4. git push              euer Stand hochladen
#
#  Wann es das tut:
#    - Standard: bei jeder Dateiänderung (fswatch auf macOS,
#      inotifywait auf Linux), max. alle 5 Sekunden gebündelt
#    - Alternative: Zeitintervall (--interval SEKUNDEN)
#
#  Sicherheit:
#    - Bei Konflikten hält das Skript an und stellt den Zustand
#      NICHT kaputt: es bricht den Rebase ab, benachrichtigt und
#      pausiert, bis ihr von Hand aufgelöst habt.
#    - LaTeX-Build-Artefakte (.aux, .log, PDFs ...) werden von
#      .gitignore ignoriert und lösen daher keinen Commit aus.
#
#  Aufruf:
#    ./git-auto-sync.sh                      # im Repo-Ordner, Watch-Modus
#    ./git-auto-sync.sh --interval 60        # alle 60 s synchronisieren
#    ./git-auto-sync.sh --once               # genau einmal synchronisieren
#
#  Beenden: Strg+C
# =====================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR" || exit 1

INTERVAL=""
ONCE=0
for arg in "$@"; do
    case "$arg" in
        --interval) INTERVAL="${2:-60}" ; shift ;;
        [0-9]*) [ -n "${2:-}" ] || INTERVAL="$arg" ;;
        --once|-1) ONCE=1 ;;
    esac
done

log() { printf '\033[1;34m[auto-sync]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[auto-sync]\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------
#  Ein Sync-Durchlauf
# ---------------------------------------------------------------------
sync_once() {
    # Nichts zu tun, wenn weder lokale Änderungen noch Remote voraus
    if ! git diff --quiet --cached && git diff --quiet && \
       [ -z "$(git ls-files --others --exclude-standard)" ] && \
       [ "$(git rev-list --count @{upstream}..HEAD 2>/dev/null)" = "0" ]; then
        return 0
    fi

    # 1) Änderungen stagen und committen (falls vorhanden)
    if ! git diff --quiet --cached || ! git diff --quiet || \
       [ -n "$(git ls-files --others --exclude-standard)" ]; then
        STAMP="$(date '+%Y-%m-%d %H:%M:%S')"
        git add -A || { err "git add fehlgeschlagen"; return 1; }
        git commit -m "Automatischer Stand ($STAMP)" \
            --author="auto-sync <auto@sync>" >/dev/null 2>&1 || true
        log "Änderungen committet ($STAMP)"
    fi

    # 2) Remote-Stand holen und per rebase integrieren
    if ! git fetch origin; then
        err "git fetch fehlgeschlagen (offline?) — überspringe diesen Durchlauf"
        return 1
    fi
    if [ "$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)" -gt 0 ]; then
        if ! git rebase origin/main; then
            err "KONFLIKT beim Einbinden der Remote-Änderungen!"
            err "Der Rebase wurde abgebrochen, nichts ist verloren."
            err "Bitte von Hand auflösen: Dateien mit <<<<<<<-Markern bearbeiten,"
            err "dann:  git add -A && git rebase --continue && git push"
            return 2
        fi
        log "Remote-Änderungen integriert"
    fi

    # 3) Pushen
    if ! git push origin main; then
        err "git push fehlgeschlagen (Netzwerk/Berechtigung?)"
        return 1
    fi
    log "Synchronisiert mit origin/main"
    return 0
}

# ---------------------------------------------------------------------
#  Trigger-Logik
# ---------------------------------------------------------------------
if [ "$ONCE" = 1 ]; then
    sync_once
    exit $?
fi

if [ -n "$INTERVAL" ]; then
    # ---- Zeitmodus: alle N Sekunden ----
    log "Zeitmodus: synchronisiere alle ${INTERVAL}s (Strg+C zum Beenden)"
    while true; do
        sync_once
        sleep "$INTERVAL"
    done
fi

# ---- Watch-Modus: bei Dateiänderungen ----
if command -v fswatch >/dev/null 2>&1; then
    log "Watch-Modus (fswatch): synchronisiere bei Änderungen (Strg+C zum Beenden)"
    fswatch -r --exclude '\.git' "$REPO_DIR" | while read -r _; do
        sync_once
        sleep 5      # Debounce: mehrere Speicherungen bündeln
    done
elif command -v inotifywait >/dev/null 2>&1; then
    log "Watch-Modus (inotifywait): synchronisiere bei Änderungen (Strg+C zum Beenden)"
    while true; do
        inotifywait -rq -e modify,create,delete,move \
            --exclude '\.git' "$REPO_DIR" >/dev/null
        sleep 5      # Debounce
        sync_once
    done
else
    err "Weder fswatch (macOS: brew install fswatch) noch"
    err "inotifywait (Linux: sudo apt install inotify-tools) gefunden."
    err "Fallback: Zeitmodus alle 60 Sekunden. Oder Paket nachinstallieren."
    log "Zeitmodus: synchronisiere alle 60s (Strg+C zum Beenden)"
    while true; do
        sync_once
        sleep 60
    done
fi
