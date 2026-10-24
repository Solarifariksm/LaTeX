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
#    - Bei Konflikten bleibt der Rebase zur manuellen Aufloesung
#      bestehen. Waehrenddessen nimmt das Skript keine Aenderungen vor.
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
    $rebaseMerge = git rev-parse --git-path rebase-merge
    $rebaseApply = git rev-parse --git-path rebase-apply
    if ((Test-Path (Join-Path $RepoDir $rebaseMerge)) -or
        (Test-Path (Join-Path $RepoDir $rebaseApply))) {
        Write-Err "Ein Rebase ist noch aktiv. Bitte manuell aufloesen und mit git rebase --continue abschliessen."
        return $false
    }

    # Konfliktmarker in Arbeitsdateien? Dann NICHT committen,
    # sondern um Hilfe rufen (verhindert, dass Marker ins Repository
    # und damit ins PDF gelangen).
    $changedFiles = @(git diff --name-only 2>$null) + @(@((git diff --cached --name-only 2>$null))) + @((git ls-files --others --exclude-standard 2>$null)) | Where-Object { $_ } | Sort-Object -Unique
    $conflictFiles = @()
    foreach ($f in $changedFiles) {
        if ($f -and (Test-Path $f -PathType Leaf)) {
            $hit = Select-String -Path $f -Pattern '^(<{7}|>{7}|={7})' -List -ErrorAction SilentlyContinue
            if ($hit) { $conflictFiles += $f }
        }
    }
    if ($conflictFiles.Count -gt 0) {
        Write-Err "KONFLIKTMARKER in Datei(en) gefunden:"
        Write-Err ($conflictFiles -join ', ')
        Write-Err "Nichts wurde committet. Bitte Datei(en) in VS Code/TeXstudio oeffnen,"
        Write-Err "die <<<<<<<-Bloecke von Hand aufloesen, dann:"
        Write-Err "  git add -A; git commit -m 'Konflikt geloest'; git push"
        return $false
    }

    $upstream = git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $upstream) {
        Write-Err "Kein Upstream-Branch konfiguriert. Bitte zuerst git push -u <remote> <branch> ausfuehren."
        return $false
    }
    $remote, $remoteBranch = $upstream -split "/", 2

    # Gibt es lokale Aenderungen?
    $status = git status --porcelain 2>$null
    $localChanges = ($status | Measure-Object).Count -gt 0

    # 1) Stagen + Committen (nur wenn noetig)
    if ($localChanges) {
        git add -A
        if ($LASTEXITCODE -ne 0) { Write-Err "git add fehlgeschlagen"; return $false }
        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git -c user.name=auto-sync -c user.email=auto@sync commit `
            -m "Automatischer Stand ($stamp)" --author="auto-sync <auto@sync>" *>$null
        if ($LASTEXITCODE -ne 0) { Write-Err "git commit fehlgeschlagen"; return $false }
        Write-Log "Aenderungen committet ($stamp)"
    }

    # 2) Remote holen und per rebase integrieren
    git fetch $remote
    if ($LASTEXITCODE -ne 0) {
        Write-Err "git fetch fehlgeschlagen (offline?) - ueberspringe diesen Durchlauf"
        return $false
    }
    $counts = git rev-list --left-right --count "$upstream...HEAD" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $counts) {
        Write-Err "Upstream-Stand konnte nicht ermittelt werden: $upstream"
        return $false
    }
    $countParts = @($counts -split '\s+' | Where-Object { $_ -ne "" })
    if ($countParts.Count -ne 2) {
        Write-Err "Unerwartete Upstream-Statusantwort: $counts"
        return $false
    }
    $behind = [int]$countParts[0]
    $ahead = [int]$countParts[1]
    if ($behind -gt 0) {
        git rebase $upstream
        if ($LASTEXITCODE -ne 0) {
            Write-Err "KONFLIKT beim Einbinden der Remote-Aenderungen!"
            Write-Err "Der Rebase bleibt zur manuellen Aufloesung aktiv."
            Write-Err "Dateien mit Konfliktmarkern bearbeiten, dann:"
            Write-Err "  git add -A"
            Write-Err "  git rebase --continue"
            return $false
        }
        Write-Log "Remote-Aenderungen integriert"
    }

    # 3) Pushen
    if ($ahead -gt 0 -or $behind -gt 0) {
        git push $remote "HEAD:$remoteBranch"
        if ($LASTEXITCODE -ne 0) {
            Write-Err "git push fehlgeschlagen (Netzwerk/Berechtigung?)"
            return $false
        }
    }
    Write-Log "Synchronisiert mit $upstream"
    return $true
}

# ---------------------------------------------------------------------
#  Trigger-Logik
# ---------------------------------------------------------------------
if ($Once) {
    if (Sync-Once) { exit 0 } else { exit 1 }
}

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
    if ($path -match '(^|[\\/])\.git([\\/]|$)') { return $false }
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
