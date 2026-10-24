#!/usr/bin/env bash
# =====================================================================
#  git-auto-sync.sh — automatisches Git-Sync für das Protokoll-Repo
#
#  Was es tut (immer in dieser Reihenfolge):
#    1. git add -A            alle Änderungen stagen
#    2. git commit            nur falls es etwas zu committen gibt
#                             (Nachricht: "Automatischer Stand <Zeit>")
#    3. git fetch + rebase    Änderungen der anderen holen
#    4. git push              eigenen Stand hochladen
#
#  Wann es das tut:
#    - Standard: bei jeder Dateiänderung (fswatch auf macOS,
#      inotifywait auf Linux), max. alle 5 Sekunden gebündelt
#    - Alternative: Zeitintervall (--interval SEKUNDEN)
#
#  Sicherheit:
#    - Bei Konflikten bleibt der Rebase zur manuellen Auflösung
#      bestehen. Währenddessen nimmt das Skript keine Änderungen vor.
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
log() { printf '\033[1;34m[auto-sync]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[auto-sync]\033[0m %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        --interval)
            if [ "$#" -lt 2 ]; then
                err "--interval benötigt eine positive Sekundenanzahl"
                exit 2
            fi
            INTERVAL="$2"
            shift 2
            ;;
        --once|-1)
            ONCE=1
            shift
            ;;
        *)
            err "Unbekanntes Argument: $1"
            exit 2
            ;;
    esac
done

if [ -n "$INTERVAL" ] && ! [[ "$INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
    err "--interval muss eine positive Sekundenanzahl sein"
    exit 2
fi
if [ "$ONCE" = 1 ] && [ -n "$INTERVAL" ]; then
    err "--once und --interval können nicht zusammen verwendet werden"
    exit 2
fi

# ---------------------------------------------------------------------
#  Ein Sync-Durchlauf
# ---------------------------------------------------------------------
sync_once() {
    local upstream remote remote_branch rebase_merge rebase_apply behind ahead stamp

    rebase_merge="$(git rev-parse --git-path rebase-merge)" || return 1
    rebase_apply="$(git rev-parse --git-path rebase-apply)" || return 1
    if [ -d "$rebase_merge" ] || [ -d "$rebase_apply" ]; then
        err "Ein Rebase ist noch aktiv. Bitte manuell auflösen und mit git rebase --continue abschließen."
        return 2
    fi

    # Konfliktmarker in Arbeitsdateien? Dann NICHT committen,
    # sondern laut um Hilfe rufen (verhindert, dass Marker ins
    # Repository und damit ins PDF gelangen).
    local conflict_files
    conflict_files="$( { git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } \
        | sort -u | while read -r f; do
            [ -f "$f" ] && grep -lE '^(<{7}|>{7}|={7})' "$f" 2>/dev/null
        done )"
    if [ -n "${conflict_files}" ]; then
        err "KONFLIKTMARKER in Datei(en) gefunden:"
        err "${conflict_files}"
        err "Nichts wurde committet. Bitte Datei(en) in VS Code/TeXstudio öffnen,"
        err "die <<<<<<<-Blöcke von Hand auflösen, dann:"
        err "  git add -A && git commit -m 'Konflikt gelöst' && git push"
        return 2
    fi

    upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || {
        err "Kein Upstream-Branch konfiguriert. Bitte zuerst git push -u <remote> <branch> ausführen."
        return 1
    }
    remote="${upstream%%/*}"
    remote_branch="${upstream#*/}"

    # 1) Änderungen stagen und committen (falls vorhanden)
    if [ -n "$(git status --porcelain)" ]; then
        git add -A || { err "git add fehlgeschlagen"; return 1; }
        stamp="$(date '+%Y-%m-%d %H:%M:%S')"
        if ! git -c user.name=auto-sync -c user.email=auto@sync \
            commit -m "Automatischer Stand ($stamp)" \
            --author="auto-sync <auto@sync>" >/dev/null; then
            err "git commit fehlgeschlagen"
            return 1
        fi
        log "Änderungen committet ($stamp)"
    fi

    # 2) Remote-Stand holen und per rebase integrieren
    if ! git fetch "$remote"; then
        err "git fetch fehlgeschlagen (offline?) — überspringe diesen Durchlauf"
        return 1
    fi
    local counts
    counts="$(git rev-list --left-right --count "$upstream...HEAD")" || {
        err "Upstream-Stand konnte nicht ermittelt werden: $upstream"
        return 1
    }
    read -r behind ahead <<< "$counts"
    if [ "$behind" -gt 0 ]; then
        if ! git rebase "$upstream"; then
            err "KONFLIKT beim Einbinden der Remote-Änderungen!"
            err "Der Rebase bleibt zur manuellen Auflösung aktiv."
            err "Dateien mit Konfliktmarkern bearbeiten, dann:"
            err "  git add -A && git rebase --continue"
            return 2
        fi
        log "Remote-Änderungen integriert"
    fi

    # 3) Pushen
    if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        if ! git push "$remote" "HEAD:$remote_branch"; then
            err "git push fehlgeschlagen (Netzwerk/Berechtigung?)"
            return 1
        fi
    fi
    log "Synchronisiert mit $upstream"
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
