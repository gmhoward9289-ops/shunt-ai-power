# Changelog

All notable changes to APCAM (`shunt`) are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Spec-based wattage estimation fallback**
  ([#19](https://github.com/gmhoward9289-ops/apcam-ai-power-meter/pull/19)) —
  when no power sensor is available, `calibrate.ps1` detects the GPU model
  (`Win32_VideoController` / `lspci` / `system_profiler`), looks it up in a new
  curated `data/gpu-tdp.ps1` table, and derives a wide idle/active band from the
  rated TDP. Labelled `powerSource: "spec-estimate"` throughout `machine.json`
  and the dashboard so it is never presented as a measurement. On by default;
  opt out with `-NoSpecEstimate`.

### Fixed

- **Nested `ssh`/`scp` in `refresh.ps1` no longer wedge a scheduled run**
  ([#30](https://github.com/gmhoward9289-ops/apcam-ai-power-meter/pull/30)) —
  Win32-OpenSSH hangs at exit when its stdio are live PowerShell pipeline pipes
  and it is running as a descendant of an inbound `sshd` session. The remote
  leg's `& ssh` and `& scp` calls did exactly that, so the first run fired by a
  remote scheduler completed the local collect, hung on the ssh back to the
  other machine, and was killed by the scheduler's timeout — leaving an empty
  stderr and a log that simply stops mid-run. Both calls now go through a new
  `Invoke-SshTool` helper that redirects stdout/stderr to per-run temp files and
  stdin from an empty file that EOFs immediately. Runs started by hand were
  never affected, which is why this survived weeks of manual use.

- **`build.ps1` resolves relative paths against PowerShell's location, not
  .NET's** ([#20](https://github.com/gmhoward9289-ops/apcam-ai-power-meter/pull/20))
  — `[System.IO.File]::ReadAllText`/`WriteAllText` resolve a relative path
  against the process's .NET working directory, which `Set-Location` never
  updates. A relative `-Dataset` or `-Template` could pass every `Test-Path`
  check and still read or write the wrong file, or fail pointing at a directory
  the user never navigated to. `$Template`, `$OutFile` and every `$Dataset` path
  are now resolved once up front via `GetUnresolvedProviderPathFromPSPath`.
- **History sort order is total, so reruns are reproducible**
  ([#14](https://github.com/gmhoward9289-ops/apcam-ai-power-meter/pull/14)) —
  `Hashtable.Values` enumeration order is randomized per process and
  `Sort-Object` is stable, so sorting on timestamp alone left same-second ties
  in that random order and a rerun over identical logs could reorder events in
  `dataset.json`. `collect.ps1` and `llamacpp.ps1` now break ties with the rest
  of the dedupe key.

### Changed

- Dashboard retitled to `Dashboard · APCAM Power Meter`
  ([#26](https://github.com/gmhoward9289-ops/apcam-ai-power-meter/pull/26)).

## [1.2.0] - 2026-08-01

### Added

- **Slider settings persist across reloads**
  ([#15](https://github.com/gmhoward9289-ops/shunt-ai-power/pull/15)) — rate,
  system draw and CO2 sliders are stored in `localStorage`, keyed per machine.
  Every access is fenced, so a `file://` page without storage falls back to the
  previous reset-on-reload behaviour rather than erroring.
- **Location picker for the electricity rate** — seeds the rate slider from the
  EIA average residential price (Apr 2026 vintage, embedded so the page stays
  offline). Labelled as a location-wide average rather than a bill; the slider
  stays free to override.

## [1.1.0] - 2026-07-31

Cross-platform support and two new backend adapters, on top of dashboard/UX and
correctness fixes.

### Added

- **Linux and macOS support** — GPU vendor dispatch and wall-power import.
  Previously Windows + NVIDIA only.
- **Runtime adapters for llama.cpp server and vLLM**, alongside the existing
  Ollama collector, selected with `-Source`
  ([#11](https://github.com/gmhoward9289-ops/shunt-ai-power/pull/11)).
- **Multi-machine merge and Prometheus metrics export** — aggregate telemetry
  from more than one host.
- **Idle-policy advisor, hosted-API cost reference, and hardware amortization**
  — analysis surfaces layered on the measured-power model.
- **CGNAT client class, multi-GPU calibrate, CO2 slider, and CSV export.**
- **Parser regression fixtures and CI**
  ([#7](https://github.com/gmhoward9289-ops/shunt-ai-power/pull/7)).
- `CONTRIBUTING.md`.

### Fixed

- **pwsh 7 dedupe** affecting run-2 raw counts, with regression fixtures.
- **Wall-power wording** now reflects `-PlugUrl`, and `build.ps1` defaults
  resolve correctly on Unix.
- Dashboard colour-scheme pass over the page chrome.

### Security

- CI hardened: `pii_scan` now refuses to run against a shallow clone (exit 2)
  rather than passing vacuously on a truncated history
  ([#13](https://github.com/gmhoward9289-ops/shunt-ai-power/pull/13)).

## [1.0.0] - 2026-07-31

Initial release. APCAM (AI Power Calculation And Monitoring) works out what a
local LLM habit actually costs in electricity, from *measured* GPU wattage
rather than a spec-sheet estimate, and renders it as a single self-contained
HTML dashboard.

### Added

- **Measured, not guessed** — `calibrate.ps1` samples `nvidia-smi` through one
  real inference to capture the GPU's idle → sustained power envelope.
- **Ollama log parsing** (`collect.ps1`) for request timing, generation rate and
  per-model attribution, handling non-contiguous task IDs and shared-weights
  model tags rather than naively zipping them in order.
- **Privacy-conscious capture** — client addresses are reduced at capture time
  into localhost / LAN / external buckets, never raw IPs. All captured telemetry
  (`dataset.json`, `history.json`, `machine.json`, `dashboard.html`) is
  gitignored; only a synthetic sample dataset ships in the repo.
- **Optional twice-daily scheduled refresh** via `install-task.ps1`, running as
  the invoking user with an interactive token — no stored password, no
  elevation.

### Platform support at 1.0.0

Built and tested on Windows + NVIDIA (Ollama 0.32.5). Partial support for
non-NVIDIA Windows GPUs via manual power entry in `machine.json`. Linux and
macOS were not supported until 1.1.0 — the log parsing was portable, but the
entry point and power readout were not.

[Unreleased]: https://github.com/gmhoward9289-ops/shunt-ai-power/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/gmhoward9289-ops/shunt-ai-power/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/gmhoward9289-ops/shunt-ai-power/releases/tag/v1.0.0
