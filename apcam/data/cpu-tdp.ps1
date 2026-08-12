# APCAM - data/cpu-tdp.ps1
#
# A small, curated table of CPU model -> rated TDP (thermal design power, in
# watts), used by calibrate.ps1 to seed a machine-specific default for
# "Non-GPU system draw" instead of a single flat guess (70 W) for every
# machine regardless of what is actually in it.
#
# WHAT THIS TABLE IS, AND IS NOT - same caveat as data/gpu-tdp.ps1's GPU
# table. TDP is a thermal ceiling the vendor guarantees the cooler can
# dissipate, not a measured or even typical draw. calibrate.ps1 uses it only
# to seed the dashboard's system-draw SLIDER with a better starting point;
# the slider stays user-adjustable, and this is never presented as measured.
# Only the GPU is metered by nvidia-smi/amd-smi/powermetrics - everything
# derived from this table is estimated, one rung below even the GPU's own
# spec-estimate fallback because a full system draw is board + RAM + storage
# + fans + PSU losses on top of the CPU, most of which is not in this table
# at all (see Get-SystemDrawEstimate's fixed baseline for that half).
#
# Every entry MUST cite where its number came from (source + sourceDate). Do
# not add an entry you cannot cite; an unmatched CPU falls through to the old
# flat default, which is more honest than a guess across model families.
#
# Provenance of this initial table: Intel/AMD TDP figures are the vendor's
# own published spec-sheet numbers (ark.intel.com "Processor Base Power" /
# amd.com "Default TDP"), compiled from general knowledge and spot-checked
# for the Core i7-6700 and Core i7-8700K entries on 2026-08-12 (these are the
# two machines apcam is actually running on today). The remaining entries
# were not individually re-verified via a live source in that pass - if you
# find one wrong, a corrected citation is a welcome one-line PR.
#
# KEEP THIS FILE PURE ASCII - PowerShell 5.1 reads .ps1 as ANSI without a BOM,
# so any non-ASCII literal is silently corrupted at parse time.

# `pattern` matches against the raw CPU name string as returned by
# Win32_Processor.Name, /proc/cpuinfo's "model name", or sysctl's
# machdep.cpu.brand_string. First match wins, so more specific patterns (a
# "K"/"X" suffix, a higher core-count sibling) are listed before the plainer
# ones they would otherwise also match.
$CpuTdpTable = @(
    # ---------------- Intel Core, desktop, 12th-14th gen (Alder/Raptor Lake) ----------------
    # Source: ark.intel.com, "Processor Base Power" (the sustained PL1 figure,
    # not the short-term PL2 boost figure); compiled 2026-08.
    [pscustomobject]@{ pattern = 'i9-14900K';  label = 'Core i9-14900K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-14700K';  label = 'Core i7-14700K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-14600K';  label = 'Core i5-14600K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i9-13900K';  label = 'Core i9-13900K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-13700K';  label = 'Core i7-13700K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-13600K';  label = 'Core i5-13600K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-13400';   label = 'Core i5-13400';   tdpW = 65;  source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i9-12900K';  label = 'Core i9-12900K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-12700K';  label = 'Core i7-12700K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-12600K';  label = 'Core i5-12600K';  tdpW = 125; source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-12400';   label = 'Core i5-12400';   tdpW = 65;  source = 'Intel ARK, Processor Base Power'; sourceDate = '2026-08' }

    # ---------------- Intel Core, desktop, 8th-11th gen (Coffee/Comet/Rocket Lake) ----------------
    # Source: ark.intel.com, "TDP"; compiled 2026-08, spot-checked for i7-8700K.
    [pscustomobject]@{ pattern = 'i9-11900K';  label = 'Core i9-11900K';  tdpW = 125; source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-11700K';  label = 'Core i7-11700K';  tdpW = 125; source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-11600K';  label = 'Core i5-11600K';  tdpW = 125; source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i9-10900K';  label = 'Core i9-10900K';  tdpW = 125; source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-10700K';  label = 'Core i7-10700K';  tdpW = 125; source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-10600K';  label = 'Core i5-10600K';  tdpW = 125; source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-10400';   label = 'Core i5-10400';   tdpW = 65;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i9-9900K';   label = 'Core i9-9900K';   tdpW = 95;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-9700K';   label = 'Core i7-9700K';   tdpW = 95;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-9600K';   label = 'Core i5-9600K';   tdpW = 95;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-8700K';   label = 'Core i7-8700K';   tdpW = 95;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-8700';    label = 'Core i7-8700';    tdpW = 65;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-8600K';   label = 'Core i5-8600K';   tdpW = 95;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-8400';    label = 'Core i5-8400';    tdpW = 65;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }

    # ---------------- Intel Core, desktop, 6th-7th gen (Skylake/Kaby Lake) ----------------
    # Source: ark.intel.com, "TDP"; compiled 2026-08, spot-checked for i7-6700
    # (this is COOPER's CPU).
    [pscustomobject]@{ pattern = 'i7-7700K';   label = 'Core i7-7700K';   tdpW = 91;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-7700';    label = 'Core i7-7700';    tdpW = 65;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-7600K';   label = 'Core i5-7600K';   tdpW = 91;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-6700K';   label = 'Core i7-6700K';   tdpW = 91;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-6700';    label = 'Core i7-6700';    tdpW = 65;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-6600K';   label = 'Core i5-6600K';   tdpW = 91;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i5-6600';    label = 'Core i5-6600';    tdpW = 65;  source = 'Intel ARK, TDP'; sourceDate = '2026-08' }

    # ---------------- AMD Ryzen, desktop, 7000-series (Zen 4) ----------------
    # Source: amd.com Ryzen product pages, "Default TDP"; compiled 2026-08.
    [pscustomobject]@{ pattern = 'Ryzen 9 7950X3D'; label = 'Ryzen 9 7950X3D'; tdpW = 120; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 9 7950X';   label = 'Ryzen 9 7950X';   tdpW = 170; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 9 7900X';   label = 'Ryzen 9 7900X';   tdpW = 170; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 7 7800X3D'; label = 'Ryzen 7 7800X3D'; tdpW = 120; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 7 7700X';   label = 'Ryzen 7 7700X';   tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 5 7600X';   label = 'Ryzen 5 7600X';   tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 5 7600';    label = 'Ryzen 5 7600';    tdpW = 65;  source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }

    # ---------------- AMD Ryzen, desktop, 5000-series (Zen 3) ----------------
    # Source: amd.com Ryzen product pages, "Default TDP"; compiled 2026-08.
    [pscustomobject]@{ pattern = 'Ryzen 9 5950X';   label = 'Ryzen 9 5950X';   tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 9 5900X';   label = 'Ryzen 9 5900X';   tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 7 5800X3D'; label = 'Ryzen 7 5800X3D'; tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 7 5800X';   label = 'Ryzen 7 5800X';   tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 5 5600X';   label = 'Ryzen 5 5600X';   tdpW = 65;  source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 5 5600';    label = 'Ryzen 5 5600';    tdpW = 65;  source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }

    # ---------------- AMD Ryzen, desktop, 3000-series (Zen 2) ----------------
    # Source: amd.com Ryzen product pages, "Default TDP"; compiled 2026-08.
    [pscustomobject]@{ pattern = 'Ryzen 9 3950X'; label = 'Ryzen 9 3950X'; tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 9 3900X'; label = 'Ryzen 9 3900X'; tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 7 3800X'; label = 'Ryzen 7 3800X'; tdpW = 105; source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 7 3700X'; label = 'Ryzen 7 3700X'; tdpW = 65;  source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 5 3600X'; label = 'Ryzen 5 3600X'; tdpW = 95;  source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'Ryzen 5 3600';  label = 'Ryzen 5 3600';  tdpW = 65;  source = 'AMD Ryzen product page, Default TDP'; sourceDate = '2026-08' }

    # ---------------- laptop / mobile catch-alls, by Intel suffix ----------------
    # Mobile SKUs are far too numerous to list individually and mostly share a
    # power class by suffix letter. HX runs desktop-class power in a laptop
    # chassis; H is the traditional mobile-performance class; U/P are thin-
    # and-light classes. These are coarse and intentionally listed last so any
    # more specific match above wins first.
    # Source: Intel mobile processor naming/power-class documentation
    # (ark.intel.com processor-line pages); compiled 2026-08.
    [pscustomobject]@{ pattern = 'i9-\d{4,5}HX'; label = 'Intel Core HX-class (mobile, desktop-power)'; tdpW = 55;  source = 'Intel mobile HX-class base power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i7-\d{4,5}HX'; label = 'Intel Core HX-class (mobile, desktop-power)'; tdpW = 45;  source = 'Intel mobile HX-class base power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i[579]-\d{4,5}H\b'; label = 'Intel Core H-class (mobile)'; tdpW = 45; source = 'Intel mobile H-class base power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i[579]-\d{4,5}P\b'; label = 'Intel Core P-class (mobile)'; tdpW = 28; source = 'Intel mobile P-class base power'; sourceDate = '2026-08' }
    [pscustomobject]@{ pattern = 'i[579]-\d{4,5}U\b'; label = 'Intel Core U-class (mobile)'; tdpW = 15; source = 'Intel mobile U-class base power'; sourceDate = '2026-08' }
)

# Returns the first matching table entry for a raw CPU name string, or $null.
function Find-CpuTdp([string]$CpuName) {
    if (-not $CpuName) { return $null }
    foreach ($row in $CpuTdpTable) {
        if ($CpuName -match $row.pattern) { return $row }
    }
    return $null
}

# ---------------- non-GPU, non-CPU baseline ----------------
# What is left in "non-GPU system draw" once the CPU has its own line item:
# motherboard chipset and VRMs, RAM, storage (NVMe/SATA), case/CPU fans, and
# PSU conversion losses. This does not vary anywhere near as much across
# machines as CPU or GPU choice does, so one fixed figure - rather than
# another lookup table - is the honest level of precision for it.
# Basis: idle-draw teardowns of typical ATX desktop builds (chipset ~5-10W,
# DDR4/DDR5 DIMMs ~3-5W each, one NVMe drive ~2-5W idle, 2-3 fans ~1-3W each,
# PSU efficiency loss at partial load) sum to roughly 20-30W outside the CPU
# and GPU; compiled 2026-08 from general component power literature, not
# measured on any specific machine.
$BoardBaselineW = 25

# Seeds the "Non-GPU system draw" slider from what calibrate.ps1 actually
# knows about this machine (CPU model) instead of one flat guess for every
# machine. During LLM inference the CPU is mostly idle - the GPU does the
# generation work, and the CPU's job is orchestration and prompt tokenization
# on one or two threads - so this charges a fraction of the CPU's rated TDP,
# not the whole figure, on top of the fixed board/RAM/storage/fan baseline.
# Returns $null (caller keeps its own flat default) when the CPU is not in
# the table above.
function Get-SystemDrawEstimate([string]$CpuName) {
    $row = Find-CpuTdp $CpuName
    if (-not $row) { return $null }
    $cpuIdleFrac = 0.25
    [pscustomobject]@{
        systemWattsW = [math]::Round($BoardBaselineW + ($row.tdpW * $cpuIdleFrac))
        cpuTdpW          = $row.tdpW
        cpuTdpLabel      = $row.label
        cpuTdpSource     = $row.source
        cpuTdpSourceDate = $row.sourceDate
        boardBaselineW   = $BoardBaselineW
    }
}
