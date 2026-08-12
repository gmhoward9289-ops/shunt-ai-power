# APCAM - refresh.ps1
#
# Unattended refresh: collect the latest usage, then rebuild the page.
# Registered as a scheduled task by install-task.ps1. Appends to refresh.log.
#
# Also pulls a second machine's dataset over SSH (reef by default) so the
# built page is the combined multi-machine view build.ps1 already knows how
# to render, not just this machine. Best-effort: if reef is unreachable, has
# not been calibrated, or its dataset is not anonymised, this machine's build
# proceeds alone rather than failing the whole refresh - a machine that is
# temporarily off should not take the dashboard down.
#
# KEEP THIS FILE PURE ASCII - PowerShell 5.1 reads .ps1 as ANSI without a BOM.
param(
    [string]$Root       = $PSScriptRoot,
    [string]$LogFile    = "$PSScriptRoot\refresh.log",
    [int]   $MaxLogKB   = 512,
    [switch]$SkipPublish,  # rebuild the local page only, leave the artifact alone
    [string]$RemoteHost = 'reef',        # ssh alias; apcam must already be deployed there
                                          # with machine.json calibrated
    [string]$RemotePath = 'C:\Users\Owner\apcam',   # absolute Windows path on the remote
    [switch]$SkipRemote   # rebuild from this machine's own dataset only
)
$ErrorActionPreference = 'Continue'

if ((Test-Path $LogFile) -and ((Get-Item $LogFile).Length -gt $MaxLogKB * 1KB)) {
    Move-Item $LogFile "$LogFile.old" -Force
}

function Write-Log([string]$msg) {
    $line = "{0}  {1}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $LogFile -Value $line -Encoding utf8
    Write-Output $line
}

# Refreshes <RemoteHost>'s own dataset over SSH and pulls it down as
# dataset.<RemoteHost>.json (the naming convention .gitignore already covers
# for per-source datasets). Returns the local path on success, $null on any
# failure - callers treat that as "build without this machine this round".
function Get-RemoteDataset([string]$RemoteHost, [string]$RemotePath, [string]$Root) {
    # Write-Log's Write-Output would otherwise become part of THIS function's
    # own return value the moment it is called from inside a function (every
    # unassigned pipeline write a function makes joins its output), silently
    # smuggling log text - including a "HH:MM:SS" timestamp that Resolve-
    # InputPath then misparses as a drive-qualified path - into whatever the
    # caller does with the real return value. Route every call through
    # Out-Null here so only the explicit `return` ever reaches the caller.
    $label = $RemoteHost
    $local = Join-Path $Root "dataset.$label.json"

    # The remote command runs through TWO shells stacked on top of each other:
    # ssh's Windows default shell is cmd.exe (confirmed - it is not PowerShell,
    # even though everything else here is PowerShell), and cmd.exe treats a
    # bare & as its own command-chaining operator. A "-Command & '...'" payload
    # gets silently split at that &, so PowerShell only ever saw "-Command"
    # with nothing after it (hence a stray PowerShell help dump in the log)
    # while the path fragment failed on its own. Wrapping the same payload in
    # one more layer of double quotes fixes the cmd.exe side, but constructing
    # that string inside local PowerShell 5.1 and handing it to ssh.exe as a
    # single argument hits ANOTHER quirk: embedded double quotes get mangled
    # somewhere in native-argument passing, dropping the backslash in
    # ".\collect.ps1" before it ever left this machine. Rather than fight two
    # unrelated quoting layers at once, collect.bat (deployed alongside
    # collect.ps1 on the remote - see apcam's remote setup notes) removes the
    # need for any of it: a bare path with no special characters for either
    # shell to misparse.
    $remoteBat = "$RemotePath\collect.bat"
    $sshArgs = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', $RemoteHost, $remoteBat)
    try {
        $collectOut = & ssh @sshArgs 2>&1
        foreach ($l in $collectOut) { Write-Log "  [$label] $l" | Out-Null }
        if ($LASTEXITCODE -ne 0) {
            Write-Log "  [$label] collect.ps1 exited $LASTEXITCODE - skipping this machine" | Out-Null
            return $null
        }
    } catch {
        Write-Log "  [$label] ssh collect failed: $($_.Exception.Message) - skipping this machine" | Out-Null
        return $null
    }

    $tmp = Join-Path $env:TEMP "apcam-$label-dataset.json"
    $remoteDatasetPath = ($RemotePath -replace '\\', '/') + '/dataset.json'
    try {
        & scp -q -o BatchMode=yes "${RemoteHost}:${remoteDatasetPath}" $tmp 2>&1 |
            ForEach-Object { Write-Log "  [$label] scp: $_" | Out-Null }
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tmp)) {
            Write-Log "  [$label] scp pull failed - skipping this machine" | Out-Null
            return $null
        }
    } catch {
        Write-Log "  [$label] scp threw: $($_.Exception.Message) - skipping this machine" | Out-Null
        return $null
    }

    try {
        $rd = Get-Content $tmp -Raw | ConvertFrom-Json
    } catch {
        Write-Log "  [$label] pulled dataset is not valid JSON - skipping this machine" | Out-Null
        Remove-Item $tmp -ErrorAction SilentlyContinue
        return $null
    }
    if ($rd.anonymised -eq $false) {
        # Same privacy gate as the deploy/publish steps below - never fold in a
        # dataset captured with -KeepRawClients, even from a machine we trust.
        Write-Log "  [$label] dataset is NOT anonymised - skipping this machine" | Out-Null
        Remove-Item $tmp -ErrorAction SilentlyContinue
        return $null
    }
    if (-not $rd.machine -or -not $rd.machine.measured) {
        Write-Log "  [$label] machine.json has no measured power envelope - run calibrate.ps1 on $RemoteHost first, skipping this machine" | Out-Null
        Remove-Item $tmp -ErrorAction SilentlyContinue
        return $null
    }
    if (-not $rd.PSObject.Properties['label']) {
        $rd | Add-Member -NotePropertyName label -NotePropertyValue $label
    }
    ($rd | ConvertTo-Json -Depth 30 -Compress) | Set-Content -Path $local -Encoding utf8
    Remove-Item $tmp -ErrorAction SilentlyContinue
    Write-Log "  [$label] dataset pulled ok ($($rd.events.Count) events)" | Out-Null
    return $local
}

Write-Log "=== refresh start ==="
$failed = $false

$collectScript = Join-Path $Root 'collect.ps1'
if (-not (Test-Path $collectScript)) {
    Write-Log "MISSING $collectScript"; $failed = $true
} else {
    try {
        $out = & $collectScript 2>&1
        foreach ($l in $out) { Write-Log ("  [collect] {0}" -f $l) }
    } catch {
        Write-Log "  [collect] THREW: $($_.Exception.Message)"; $failed = $true
    }
}

$remoteDatasets = @()
if (-not $failed -and -not $SkipRemote) {
    $rp = Get-RemoteDataset -RemoteHost $RemoteHost -RemotePath $RemotePath -Root $Root
    if ($rp) { $remoteDatasets += $rp }
}

if (-not $failed) {
    $buildScript = Join-Path $Root 'build.ps1'
    if (-not (Test-Path $buildScript)) {
        Write-Log "MISSING $buildScript"; $failed = $true
    } else {
        try {
            $datasets = @(Join-Path $Root 'dataset.json') + $remoteDatasets
            $out = & $buildScript -Dataset ($datasets -join ',') 2>&1
            foreach ($l in $out) { Write-Log ("  [build] {0}" -f $l) }
        } catch {
            Write-Log "  [build] THREW: $($_.Exception.Message)"; $failed = $true
        }
    }
}

if (-not $failed) {
    # Deploy the built page to the tunnel-only portal vhost on swamplink:
    # http://127.0.0.1:8103/apcam/ (over the standing tunnel). This URL is what
    # the portal links to; the Claude artifact below is a secondary snapshot.
    # Same privacy gate as publishing - never ship a non-anonymised dataset.
    $page = Join-Path $Root 'dashboard.html'
    $d = $null
    try { $d = Get-Content (Join-Path $Root 'dataset.json') -Raw | ConvertFrom-Json } catch { }
    if ($d -and $d.anonymised -eq $false) {
        Write-Log "  [deploy] dataset is NOT anonymised - refusing to deploy"
        $failed = $true
    } else {
        # build.ps1 emits a fragment for the artifact wrapper; served raw it
        # would render in quirks mode, so prepend a proper prologue for Caddy.
        $tmp = Join-Path $env:TEMP 'apcam-deploy.html'
        $html = Get-Content $page -Raw -Encoding UTF8
        $prologue = "<!doctype html>`n<html lang=`"en`"><head><meta charset=`"utf-8`">`n" +
            "<meta name=`"viewport`" content=`"width=device-width, initial-scale=1`">`n" +
            "<meta name=`"robots`" content=`"noindex, nofollow`">`n"
        [System.IO.File]::WriteAllText($tmp, $prologue + $html,
            (New-Object System.Text.UTF8Encoding($false)))
        ssh -o BatchMode=yes swamplink "mkdir -p /var/www/swamplink/portal/apcam" 2>&1 | Out-Null
        scp -q $tmp "swamplink:/var/www/swamplink/portal/apcam/index.html"
        if ($LASTEXITCODE -ne 0) {
            Write-Log "  [deploy] scp to swamplink failed with exit $LASTEXITCODE"
            $failed = $true
        } else {
            Write-Log "  [deploy] pushed to swamplink portal/apcam/"
        }
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

if (-not $failed -and -not $SkipPublish) {
    # Republish the artifact. Rebuilding dashboard.html locally used to be the whole job,
    # which meant the published page only moved when someone happened to be in a session.
    $page   = Join-Path $Root 'dashboard.html'
    $prompt = Join-Path $Root 'publish-prompt.txt'
    $d      = $null
    try { $d = Get-Content (Join-Path $Root 'dataset.json') -Raw | ConvertFrom-Json } catch { }

    if ($d -and $d.anonymised -eq $false) {
        # collect.ps1 -KeepRawClients leaves real client addresses in the dataset. Never
        # push that to a hosted page, even a private one.
        Write-Log "  [publish] dataset is NOT anonymised - refusing to publish"
        $failed = $true
    } elseif (-not (Test-Path $prompt)) {
        Write-Log "  [publish] MISSING $prompt"
        $failed = $true
    } else {
        # See PairingLog\refresh.ps1 for why the entrypoint line is load-bearing: the
        # Artifact tool is gated on it, and claude exits 0 whether or not it published.
        #
        # The prompt is NOT piped in. Under the scheduled task's console the emoji
        # favicon did not survive piping even with $OutputEncoding set (2026-07-31,
        # ENCODING_LOST), so the pipe carries only this ASCII bootstrap and claude
        # reads the real prompt from the UTF-8 file itself, which cannot be mangled.
        $env:CLAUDE_CODE_ENTRYPOINT = 'claude-desktop'
        $boot = 'Read the file {0} and follow its instructions exactly.' -f $prompt

        Push-Location $Root
        $out = $boot | & claude -p --allowedTools 'Artifact,Read'
        $rc  = $LASTEXITCODE
        Pop-Location
        foreach ($l in $out) { Write-Log "  [publish] $l" }

        if ($rc -ne 0 -or ($out -join "`n") -notmatch 'PUBLISHED_OK') {
            Write-Log "  [publish] claude exit $rc, no PUBLISHED_OK in reply - treating as failure"
            $failed = $true
        }
    }
}

if (-not $failed) {
    try {
        $ds = Join-Path $Root 'dataset.json'
        $d  = Get-Content $ds -Raw | ConvertFrom-Json
        if ($d.events) {
            $sec = ($d.events | Measure-Object -Property dur -Sum).Sum
            $w   = $d.machine.gpuActiveW + $d.machine.systemWatts
            Write-Log ("  summary: {0} events, {1:N0}s active, {2:N1} Wh at {3:N0} W" -f `
                $d.events.Count, $sec, ($sec * $w / 3600), $w)
        } else {
            Write-Log "  summary: no events recorded yet"
        }
    } catch { Write-Log "  summary unavailable: $($_.Exception.Message)" }
}

Write-Log ("=== refresh {0} ===" -f $(if ($failed) { "FAILED" } else { "ok" }))
if ($failed) { exit 1 }
