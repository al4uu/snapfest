# CL - SnapFest
- `Dirty Flash` work in `Manager` or `Direct install`.
- Do a `Clean Flash` of this `module` if you're on a version below `2.0`.
- After installing this `module` and rebooting, go straight to the `home screen` and wait for the `SnapFest notification` to pop up.

## 2.2 (2025-03-15)
- Update `code` logic.
- Increase `touch sampling rate`.
- Add `verify.sh` to automate `integrity` checks.
- Optimize `library` handling, add `UnityGfxDeviceW` & `libfb.so`, improve `script` logic.
- Drop other `properties` Tweaks.
- Drop support for `Network Tweaks`.

## 2.1 (2025-03-15)
- Simplify `network` tweaks.
- Bring back `Touch Boost` tweaks.
- Drop unnecessary `GPU governor` set.
- Drop `CPU` `mid-freq` scaling config.
- Merge apply logic to set `CPU max/min freq`.
- Disable `TTWU_QUEUE` to reduce wake-up latency.
- Refine `MMC` and `I/O` settings for enhanced performance.
- Replace old script with `eMMC` and `UFS` max perf-tuning.
- Update `Dynamic Description` to include `BOARD_PLATFORM` using `getprop`.
- Replace old boost script with max freq tuning for `CPU, GPU, Bus, and Memory`.

## 2.0 (2025-03-13)
- Delete `C` Source.
- Drop `ThermVX` (`thermal tweak`).
- Drop some of the `properties` tweak.
- Switch from `install.sh` to `customize.sh` to simplify `installation` process.
- `action.sh` : Simplified path handling using `MODPATH`.

## 1.8 (2025-03-08)
- Optimize `mmc` devfreq scaling to improve `I/O` performance.
- Replace `single-loop` stop with `two-loop` for better `thermal service` termination.
- Refactor `TCP` configuration into structured logic.
- Refactor `/sys/class/kgsl/kgsl-3d0` script to unify `GPU` tuning logic.
- Refactor `msm_thermal` and `thermal_messege/sconfig` handling with checks for stability.

## 1.7.1 (2025-03-05)
- Drop `Dynamic` Description in `post-fs-data`
- Drop `battery` saver tweak (`MIUI/HyperOS` issue)
- Drop `cpufreq` and `cpu_limits` tweak in `thermal_message` (ML & other `games` freeze issue)

## 1.7 (2025-03-04)
- Integrate `ThermVX` (`thermal tweaks`) into `SnapFest`.
- Dropped/reverted the `temp_throttle` tweak and enabled all `CPU` cores.
- Fix issue where `app/game` gets stuck on startup (`black/white screen`).

## 1.6 (2025-02-27)
- Drop unstable `SurfaceFlinger` and touch-related `props`.
- Drop `pnpmgr` and `msm` touch boost tweaks.
- Disable `msm_thermal` `temp_throttle` for better CPU performance.
- Fix syntax error in `CPU` online detection.

## 1.5 (2025-02-22)
- Enable all `CPU` cores.
- Add more package names and fix `sched_lib` write issues.
- Refactor thermal: Disable `zone`, apply `step_wise` policy.
- Implement `Snapdragon` detection refactor `permission` handling.
- Optimize GPU Governor to `msm-adreno-tz` and set max available `frequency`.

## 1.4 (2025-02-06)
- Improved `UI` Speed.
- Removed unused `system` settings.
- Reworked performance `properties`.
- Fix screen `Flicker` on some `Devices`.

## 1.3 (2025-01-31)
- Redo `set_properties` and `reset_properties`.
- Fine-tuned Kill `Logger` and `properties` tweaks.
- Updated and Fixed `C` source `code`, removed `compiled` files from the repo.

## 1.2 (2025-01-30)
- Refactored code `logic` and `structure`.
- Revamped `SurfaceFlinger` and reworked `core` logic.
- Fixing random `reboots`, `vibration`, and `flickering`.

## 1.1 (2025-01-22)
- Refactor `installer` logic.
- Stop all `thermal-related` services.
- Rewrite `PPM` script for improved `thermal` control and `policy` optimization.

## 1.0 (2025-01-20)
- Initial release GitHub.
- Optimize `props` for system stability.
- Optimize `scheduling` and `memory` parameters.
- Refactor battery saver module disabling logic.
- Disable `debugging` and stop system `services`.
- Extract `thermal-engine` from OnePlus 7T `hotdogb`.
- Refactor `CPU` Governor and `Thermal` Handling logic.
- Update `scheduler` and system optimizations to improve performance.
- Update logic `code` in `uninstall.sh` to clean `cache` and `shader` files.
- Refine `networking` tweaks script for direct `sysctl` parameter modifications.
- Set `read_ahead _kb` to `32` for `mmcblk0` and `mmcblk1` to optimize `I/0` performance.
