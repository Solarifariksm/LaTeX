# =====================================================================
#  git-auto-sync.ps1 — automatisches Git-Sync fuer das Protokoll-Repo
#  (Windows 11 / PowerShell, nativer Watch-Modus ohne Zusatztools)
#
#  Was es tut (pro Durchlauf, in dieser Reihenfolge):
#    1. git add -A + git commit     nur falls Aenderungen vorhanden
#    2. git fetch + git rebase      Aenderungen der anderen integrieren
#    3. git push                    eigener Stand hochladen
#
#  Wann:
#    - Standard: bei jeder Dateiaenderung (FileSystemWatcher, gebuendelt)
#    - Alternativ:  .\git-auto-sync.ps1 -Interval 60   (alle 60 s)
#    - Einmal:      .\git-auto-sync.ps1 -Once
#
#  Sicherheit:
#    - Bei Konflikten HAELT das Skript an (rebase wird abgebrochen,
#      nichts geht verloren) und zeigt die Aufloesungsschritte an.
#    - .gitignore filtert Build-Artefakte, PDFs etc. aus.
#
#  Start (PowerShell im Repo-Ordner):
#    .\git-auto-sync.ps1
#  Falls Ausfuehrung blockiert wird (ExecutionPolicy):
#    powershell -ExecutionPolicy Bypass -File .\git-auto-sync.ps1
#
#  Beenden: Strg+C
# =====================================================================

param(
    [int]$Interval = 0,
    [switch]$Once
)

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoDir

function Write-Log($msg)  { Write-Host "[auto-sync] $msg" -ForegroundColor Cyan }
function Write-Err($msg)  { Write-Host "[auto-sync] $msg" -ForegroundColor Red }

function Sync-Once {
    # Gibt es lokale Aenderungen?
    $status = git status --porcelain 2>$null
    $localChanges = ($status | Measure-Object).Count -gt 0

    # Gibt es unausgepushte Commits?
    $unpushed = 0
    $revlist = git rev-list --count "@{upstream}..HEAD" 2>$null
    if ($LASTEXITCODE -eq 0 -and $revlist) { $unpushed = [int]$revlist }

    if (-not $localChanges -and $unpushed -eq 0) { return $true }

    # 1) Stagen + Committen (nur wenn noetig)
    if ($localChanges) {
        git add -A
        if ($LASTEXITCODE -ne 0) { Write-Err "git add fehlgeschlagen"; return $false }
        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "Automatischer Stand ($stamp)" --author="auto-sync <auto@sync>" *>$null
        Write-Log "Aenderungen committet ($stamp)"
    }

    # 2) Remote holen und per rebase integrieren
    git fetch origin
    if ($LASTEXITCODE -ne 0) {
        Write-Err "git fetch fehlgeschlagen (offline?) - ueberspringe diesen Durchlauf"
        return $false
    }
    $behind = git rev-list --count "HEAD..origin/main" 2>$null
    if ($LASTEXITCODE -eq 0 -and $behind -gt 0) {
        git rebase origin/main
        if ($LASTEXITCODE -ne 0) {
            Write-Err "KONFLIKT beim Einbinden der Remote-Aenderungen!"
            git rebase --abort *>$null
            Write-Err "Der Rebase wurde abgebrochen, nichts ist verloren."
            Write-Err "Bitte von Hand aufloesen:"
            Write-Err "  1. Dateien mit <<<<<<<-Markern in VS Code bearbeiten"
            Write-Err "  2. git add -A"
            Write-Err "  3. git rebase --continue"
            Write-Err "  4. git push"
            return $false
        }
        Write-Log "Remote-Aenderungen integriert"
    }

    # 3) Pushen
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Err "git push fehlgeschlagen (Netzwerk/Berechtigung?)"
        return $false
    }
    Write-Log "Synchronisiert mit origin/main"
    return $true
}

# ---------------------------------------------------------------------
#  Trigger-Logik
# ---------------------------------------------------------------------
if ($Once) { Sync-Once | Out-Null; exit 0 }

if ($Interval -gt 0) {
    Write-Log "Zeitmodus: synchronisiere alle $Interval s (Strg+C zum Beenden)"
    while ($true) {
        Sync-Once | Out-Null
        Start-Sleep -Seconds $Interval
    }
}

# ---- Watch-Modus: FileSystemWatcher (nativ in Windows) ----
Write-Log "Watch-Modus: synchronisiere bei Aenderungen (Strg+C zum Beenden)"

$watcher = New-Object System.IO.FileSystemWatcher $RepoDir
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor
                          [System.IO.NotifyFilters]::FileName -bor
                          [System.IO.NotifyFilters]::DirectoryName

# .git- und Build-Aenderungen ignorieren
function Test-RelevantPath($path) {
    if ($path -match '\\\.git\\') { return $false }
    if ($path -match '\.(aux|log|out|toc|lof|fls|fdb_latexmk|synctex|bbl|bcf|run\.xml|blg|pdf|synctex\.gz)$') { return $false }
    return $true
}

while ($true) {
    $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
    if (-not $change.TimedOut) {
        if (Test-RelevantPath $change.Name) {
            Start-Sleep -Milliseconds 3000   # Debounce: mehrere Speicherungen buendeln
            Sync-Once | Out-Null
        }
    }
}
