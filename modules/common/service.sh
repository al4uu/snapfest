#!/system/bin/sh

ROOT_METHOD="Unknown"
ROOT_VERSION="Unknown"

if [ -d "/data/adb/ksu" ]; then
    ROOT_METHOD="KernelSU"
    if command -v su &>/dev/null; then
        ROOT_VERSION=$(su --version 2>/dev/null | cut -d ':' -f 1)
    fi
elif [ -d "/data/adb/magisk" ]; then
    ROOT_METHOD="Magisk"
    if command -v magisk &>/dev/null; then
        ROOT_VERSION=$(magisk -V)
    fi
elif [ -d "/data/adb/ap" ]; then
    ROOT_METHOD="APatch"
    if [ -f "/data/adb/ap/version" ]; then
        ROOT_VERSION=$(cat /data/adb/ap/version)
    fi
fi

MODDIR="/data/adb/modules/snapfest"
MODULE_PROP="${MODDIR}/module.prop"
BACKUP_PROP="${MODULE_PROP}.orig"

if [ -f "$MODULE_PROP" ] && [ ! -f "$BACKUP_PROP" ]; then
    cp "$MODULE_PROP" "$BACKUP_PROP"
fi

if [ -f "$MODULE_PROP" ]; then
    sed -i "s/^description=.*/description=[ 😋 SnapFest is running | ✅ ${ROOT_METHOD} (${ROOT_VERSION}) ] Special performance module designed for Snapdragon devices !/" "$MODULE_PROP"
fi

while [ -z "$(resetprop sys.boot_completed)" ]; do
    sleep 5
done

if [ -e /sys/class/kgsl/kgsl-3d0/devfreq/governor ]; then
  echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
fi

find /sys/devices/system/cpu -maxdepth 1 -name 'cpu?' | while IFS= read -r cpu; do
  echo performance > "$cpu/cpufreq/scaling_governor"
done

for ufsemmc in /sys/class/devfreq/*.ufshc; do
    [ -w "$ufsemmc/governor" ] && echo "performance" > "$ufsemmc/governor"
done
for ufsemmc in /sys/class/devfreq/mmc*; do
    [ -w "$ufsemmc/governor" ] && echo "performance" > "$ufsemmc/governor"
done

for path in /sys/class/devfreq/*cpu-ddr-latfloor* /sys/class/devfreq/*cpu*-lat /sys/class/devfreq/*cpu-cpu-ddr-bw /sys/class/devfreq/*cpu-cpu-llcc-bw; do
    if [ -e "$path/governor" ]; then
        echo "performance" > "$path/governor"
    fi
done

for path in /sys/class/devfreq/*gpubw*; do
    if [ -e "$path/governor" ]; then
        echo "performance" > "$path/governor"
    fi
done

for path in /sys/class/kgsl/*/devfreq; do
    if [ -f "$path/available_frequencies" ]; then
        freq=$(cat "$path/available_frequencies" | tr ' ' '\n' | sort -nr | head -n 1)
        if [ -n "$freq" ]; then
            echo "$freq" > "$path/min_freq"
            echo "$freq" > "$path/max_freq"
        fi
    fi
done

for component in LLCC L3 DDR DDRQOS; do
    base_path="/sys/devices/system/cpu/bus_dcvs/$component"
    [ ! -d "$base_path" ] && continue

    freq_file="$base_path/available_frequencies"
    [ ! -f "$freq_file" ] && continue

    freq=$(cat "$freq_file" | tr ' ' '\n' | sort -nr | head -n 1)
    [ -z "$freq" ] && continue

    for path in "$base_path"/*/max_freq "$base_path"/*/min_freq; do
        [ -e "$path" ] && apply "$freq" "$path"
    done
done

for queue in /sys/block/*/queue/; do
    if [ -f "$queue/scheduler" ]; then
        sched=$(cat "$queue/scheduler")
        for algo in cfq noop kyber bfq mq-deadline none; do
            if echo "$sched" | grep -q "$algo"; then
                echo "$algo" > "$queue/scheduler"
                break
            fi
        done
        echo 0 > "$queue/add_random"
        echo 0 > "$queue/iostats"
        echo 64 > "$queue/read_ahead_kb"
        echo 512 > "$queue/nr_requests"
    fi
done

for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
    if [ -d "$dir" ]; then
        [ ! -e "$dir/queue/iostats" ] || echo 0 > "$dir/queue/iostats"
        [ ! -e "$dir/queue/nr_requests" ] || echo 64 > "$dir/queue/nr_requests"
        [ ! -e "$dir/queue/add_random" ] || echo 0 > "$dir/queue/add_random"
        [ ! -e "$dir/queue/read_ahead_kb" ] || echo 32 > "$dir/queue/read_ahead_kb"
    fi
done

if [ -f "/proc/sys/net/ipv4/tcp_available_congestion_control" ]; then
    congestion=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control)

    for algo in bbr2 bbr cubic bic westwood newreno; do
        if echo "$congestion" | grep -qw "$algo"; then
            echo "$algo" > /proc/sys/net/ipv4/tcp_congestion_control
            break
        fi
    done

    echo 1 > /proc/sys/net/ipv4/tcp_ecn
    echo 3 > /proc/sys/net/ipv4/tcp_fastopen
    echo 0 > /proc/sys/net/ipv4/tcp_syncookies
fi

calculate_mid_freq() {
    local cpu_path=$1
    local min_freq=$(cat "$cpu_path/cpufreq/cpuinfo_min_freq")
    local max_freq=$(cat "$cpu_path/cpufreq/cpuinfo_max_freq")
    echo $(( (min_freq + max_freq) / 2 ))
}

for cpu in /sys/devices/system/cpu/cpu[0-3]; do
    if [ -d "$cpu/cpufreq" ]; then
        mid_freq=$(calculate_mid_freq "$cpu")
        max_freq=$(cat "$cpu/cpufreq/cpuinfo_max_freq")

        if [ -f "$cpu/cpufreq/scaling_governor" ]; then
            governor=$(cat "$cpu/cpufreq/scaling_governor")
            if [ "$governor" = "schedutil" ]; then
                echo 75 > "$cpu/cpufreq/schedutil/hispeed_load"
                echo 0 > "$cpu/cpufreq/schedutil/iowait_boost_enable"
                echo 300 > "$cpu/cpufreq/schedutil/up_rate_limit_us"
                echo 2500 > "$cpu/cpufreq/schedutil/down_rate_limit_us"
            fi
        fi

        echo "$mid_freq" > "$cpu/cpufreq/scaling_min_freq"
        echo "$max_freq" > "$cpu/cpufreq/scaling_max_freq"
    fi
done

for cpu in /sys/devices/system/cpu/cpu[4-7]; do
    if [ -d "$cpu/cpufreq" ]; then
        mid_freq=$(calculate_mid_freq "$cpu")
        max_freq=$(cat "$cpu/cpufreq/cpuinfo_max_freq")

        echo "$mid_freq" > "$cpu/cpufreq/scaling_min_freq"
        echo "$max_freq" > "$cpu/cpufreq/scaling_max_freq"
    fi
done

for gpu in /sys/class/kgsl/kgsl-3d0; do
  if [ -e "$gpu/adrenoboost" ]; then
    echo "3" > "$gpu/adrenoboost"
  fi
  if [ -e "$gpu/devfreq/adrenoboost" ]; then
    echo "0" > "$gpu/devfreq/adrenoboost"
  fi
  if [ -e "$gpu/throttling" ]; then
    echo "0" > "$gpu/throttling"
  fi
  if [ -e "$gpu/bus_split" ]; then
    echo "0" > "$gpu/bus_split"
  fi
  if [ -e "$gpu/force_clk_on" ]; then
    echo "1" > "$gpu/force_clk_on"
  fi
  if [ -e "$gpu/force_bus_on" ]; then
    echo "1" > "$gpu/force_bus_on"
  fi
  if [ -e "$gpu/force_rail_on" ]; then
    echo "1" > "$gpu/force_rail_on"
  fi
  if [ -e "$gpu/force_no_nap" ]; then
    echo "1" > "$gpu/force_no_nap"
  fi
  if [ -e "$gpu/idle_timer" ]; then
    echo "80" > "$gpu/idle_timer"
  fi
  if [ -e "$gpu/max_pwrlevel" ]; then
    echo "0" > "$gpu/max_pwrlevel"
  fi
done

if [ -f /sys/module/battery_saver/parameters/enabled ]; then
    if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
        echo "0" > /sys/module/battery_saver/parameters/enabled
    else
        echo "N" > /sys/module/battery_saver/parameters/enabled
    fi
fi

if [ -e /sys/class/kgsl/kgsl-3d0/snapshot/dump ]; then
  echo "0" > /sys/class/kgsl/kgsl-3d0/snapshot/dump
fi
if [ -e /sys/class/kgsl/kgsl-3d0/snapshot/snapshot_crashdumper ]; then
  echo "0" > /sys/class/kgsl/kgsl-3d0/snapshot/snapshot_crashdumper
fi
if [ -e /sys/module/adreno_idler/parameters/adreno_idler_active ]; then
  echo "1" > /sys/module/adreno_idler/parameters/adreno_idler_active
fi

list_thermal_services() {
    find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null | while read -r rc; do
        grep -r "^service" "$rc" | awk '{print $2}'
    done | grep thermal
}

for svc in $(list_thermal_services); do
    stop "$svc" >/dev/null 2>&1
    start "$svc" >/dev/null 2>&1
done

for pid in $(pgrep thermal); do
    kill -SIGSTOP "$pid" >/dev/null 2>&1
done

for zone in /sys/class/thermal/thermal_zone*; do
    [ -w "$zone/mode" ] && echo "disabled" > "$zone/mode" 2>/dev/null
done

for prop in $(resetprop | grep 'thermal.*running' | awk -F '[][]' '{print $2}'); do
    resetprop "$prop" freezed >/dev/null 2>&1
done

for prop in dalvik.vm.dexopt.thermal-cutoff sys.thermal.enable ro.thermal_warmreset; do
    case "$prop" in
        dalvik.vm.dexopt.thermal-cutoff)
            resetprop "$prop" 0 >/dev/null 2>&1 ;;
        sys.thermal.enable|ro.thermal_warmreset)
            resetprop "$prop" false >/dev/null 2>&1 ;;
    esac
done

find /sys/devices/virtual/thermal -type f -exec chmod 000 {} + 2>/dev/null

find /sys/ -type f -name "*throttling*" | while IFS= read -r throttling; do
    if [ -w "$throttling" ]; then
        echo 0 > "$throttling"
    fi
done

find /sys/ -name enabled | grep 'msm_thermal' | while IFS= read -r msm_thermal_status; do
    if [ -r "$msm_thermal_status" ]; then
        msm_thermal_value=$(cat "$msm_thermal_status")
        if [ "$msm_thermal_value" = 'Y' ]; then
            echo 'N' > "$msm_thermal_status"
        elif [ "$msm_thermal_value" = '1' ]; then
            echo '0' > "$msm_thermal_status"
        fi
    fi
done

for i in "debug_mask" "log_level*" "debug_level*" "*debug_mode" "enable_ramdumps" "edac_mc_log*" \
         "enable_event_log" "*log_level*" "*log_ue*" "*log_ce*" "log_ecn_error" \
         "snapshot_crashdumper" "seclog*" "compat-log" "*log_enabled" "tracing_on" "mballoc_debug"; do
    find /sys/ -type f -name "$i" 2>/dev/null | while IFS= read -r log_file; do
        if [ -w "$log_file" ]; then
            echo "0" > "$log_file" 2>/dev/null
        fi
    done
done

for svc in mi_thermald traced tombstoned tcpdump cnss_diag statsd logcat logcatd logd \
           idd-logreader idd-logreadermain stats dumpstate vendor.tcpdump vendor_tcpdump \
           vendor.cnss_diag; do
    if pgrep -x "$svc" >/dev/null; then
        su -c "stop $svc" >/dev/null 2>&1
    fi
done

for proc in logd logcat logcatd logd.rc traced tombstoned; do
    if pgrep -x "$proc" >/dev/null; then
        killall -9 "$proc" >/dev/null 2>&1
    fi
done

for path in /data/anr /dev/log /data/tombstones /data/log_other_mode \
            /data/system/dropbox /data/system/usagestats /data/log /sys/kernel/debug \
            /storage/emulated/0/*.log /storage/emulated/0/Android/*.log; do
    if [ -d "$path" ]; then
        rm -rf "$path" >/dev/null 2>&1
    fi
done

lib_names="com.miHoYo. com.activision. com.garena. com.roblox. com.epicgames com.dts. UnityMain libunity.so libil2cpp.so libmain.so libcri_vip_unity.so libopus.so libxlua.so libUE4.so libAsphalt9.so libnative-lib.so libRiotGamesApi.so libResources.so libagame.so libapp.so libflutter.so libMSDKCore.so libFIFAMobileNeon.so libUnreal.so libEOSSDK.so libcocos2dcpp.so libgodot_android.so libgdx.so libgdx-box2d.so libminecraftpe.so libLive2DCubismCore.so libyuzu-android.so libryujinx.so libcitra-android.so libhdr_pro_engine.so libandroidx.graphics.path.so libeffect.so"

for path in /proc/sys/kernel/sched_lib_name /proc/sys/kernel/sched_lib_mask_force /proc/sys/walt/sched_lib_name /proc/sys/walt/sched_lib_mask_force; do
    if [ -w "$path" ]; then
        case "$path" in
            */sched_lib_name) echo "$lib_names" > "$path" ;;
            */sched_lib_mask_force) echo "255" > "$path" ;;
        esac
    fi
done

busybox=$(find /data/adb/ -type f -name busybox | head -n 1)
$busybox swapoff /dev/block/zram0
echo "1" > /sys/block/zram0/reset
echo "4294967296" > /sys/block/zram0/disksize
$busybox mkswap /dev/block/zram0
$busybox swapon /dev/block/zram0

echo "0" > /proc/sys/kernel/panic
echo "0" > /proc/sys/kernel/panic_on_warn
echo "0" > /proc/sys/kernel/panic_on_oops
echo "0" > /proc/sys/kernel/softlockup_panic

echo "0" > /sys/class/kgsl/kgsl-3d0/bus_split
echo "0" > /sys/class/kgsl/kgsl-3d0/throttling
echo "1" > /sys/class/kgsl/kgsl-3d0/force_clk_on
echo "1" > /sys/class/kgsl/kgsl-3d0/force_rail_on
echo "1" > /sys/class/kgsl/kgsl-3d0/force_bus_on
echo "1" > /sys/class/kgsl/kgsl-3d0/force_no_nap

echo "0" > /sys/kernel/rcu_normal
echo "0" > /sys/kernel/rcu_expedited
echo "1" > /proc/sys/kernel/timer_migration
echo "0" > /sys/devices/system/cpu/isolated
echo "0" > /proc/sys/kernel/hung_task_timeout_secs

echo "1" > /dev/stune/top-app/schedtune.boost
echo "0" > /dev/stune/top-app/schedtune.prefer_idle
echo "NEXT_BUDDY" > /sys/kernel/debug/sched_features
echo "TTWU_QUEUE" > /sys/kernel/debug/sched_features

echo "0" > /sys/kernel/msm_thermal/enabled
echo "N" > /sys/module/msm_thermal/parameters/enabled
echo "0" > /sys/module/msm_thermal/core_control/enabled
echo "0" > /sys/module/msm_thermal/vdd_restriction/enabled
echo "0" > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input

echo "0" > /sys/kernel/ccci/debug
echo "0" > /proc/sys/vm/page-cluster
echo "120" > /proc/sys/vm/stat_interval
echo "0" > /proc/sys/kernel/debug_locks
echo "0" > /sys/kernel/tracing/tracing_on
echo "0" > /proc/sys/kernel/sched_schedstats
echo "0" > /proc/sys/kernel/split_lock_mitigate
echo "32" > /proc/sys/kernel/sched_nr_migrate
echo "0" > /proc/sys/kernel/perf_event_paranoid
echo "1" > /proc/sys/kernel/sched_child_runs_first
echo "0" > /proc/sys/kernel/sched_tunable_scaling
echo "0" > /proc/sys/vm/compaction_proactiveness
echo "4000000" > /proc/sys/kernel/sched_latency_ns
echo "0" > /proc/sys/kernel/sched_autogroup_enabled
echo "3" > /proc/sys/kernel/perf_cpu_time_max_percent
echo "50000" > /proc/sys/kernel/sched_migration_cost_ns
echo "0" > /sys/module/mmc_core/parameters/use_spi_crc
echo "1000000" > /proc/sys/kernel/sched_min_granularity_ns
echo "0" > /sys/module/cpufreq_bouncing/parameters/enable
echo "0" > /proc/sys/kernel/sched_min_task_util_for_colocation
echo "1500000" > /proc/sys/kernel/sched_wakeup_granularity_ns
echo "0" > /proc/task_info/task_sched_info/task_sched_info_enable
echo "0" > /proc/oplus_scheduler/sched_assist/sched_assist_enabled

echo "0 0 0 0" > /proc/sys/kernel/printk
echo "off" > /proc/sys/kernel/printk_devkmsg
echo "0" > /sys/module/printk/parameters/pid
echo "0" > /sys/module/printk/parameters/cpu
echo "0" > /sys/module/printk/parameters/time
echo "0" > /sys/kernel/printk_mode/printk_mode
echo "N" > /sys/module/sync/parameters/fsync_enabled
echo "1" > /sys/module/printk/parameters/ignore_loglevel
echo "0" > /sys/module/printk/parameters/printk_ratelimit
echo "1" > /sys/module/printk/parameters/console_suspend

echo "3" > /proc/sys/vm/drop_caches
echo "1" > /proc/sys/vm/compact_memory
echo "0" > /proc/sys/debug/exception-trace
echo "80" > /proc/sys/vm/vfs_cache_pressure
echo "0" > /sys/kernel/debug/dri/0/debug/enable
echo "1" > /sys/module/spurious/parameters/noirqdebug
echo "0" > /sys/kernel/debug/sde_rotator0/evtlog/enable

echo "1" > /proc/sys/net/ipv4/tcp_ecn
echo "1" > /proc/sys/net/ipv4/tcp_sack
echo "3" > /proc/sys/net/ipv4/tcp_fastopen
echo "1" > /proc/sys/net/ipv4/tcp_low_latency
echo "0" > /proc/sys/net/ipv4/tcp_timestamps

echo "1" > /sys/power/pnpmgr/touch_boost
echo "1" > /sys/module/msm_performance/parameters/touchboost

echo "0" > /sys/kernel/debug/rpm_log
echo "0" > /sys/module/rmnet_data/parameters/rmnet_data_log_level

sleep 5

fstrim -v /cache
fstrim -v /system
fstrim -v /vendor
fstrim -v /data
fstrim -v /preload
fstrim -v /product
fstrim -v /metadata
fstrim -v /odm
fstrim -v /data/dalvik-cache

sleep 15

setprop debug.sf.hw 1
setprop debug.egl.hw 1
setprop debug.overlayui 1
setprop debug.hwui.level 2
setprop debug.sf.showfps 0
setprop debug.sf.showcpu 0
setprop debug.mdpcomp.logs 0
setprop debug.qc.hardware true
setprop debug.hwui.fps_divisor 1
setprop debug.qctwa.statusbar 1
setprop debug.sf.showupdates 0
setprop debug.egl.disable_msaa 1
setprop debug.rs.qcom.verbose 0
setprop debug.enable.wl_log false
setprop debug.rs.qcom.noprofile 1
setprop debug.qualcomm.sns.hal 0
setprop debug.hwui.renderer skiagl
setprop debug.cpurend.vsync false
setprop debug.hwui.overdraw false
setprop debug.qctwa.preservebuf 1
setprop debug.rs.qcom.noextraeq 1
setprop debug.rs.qcom.noperfhint 1
setprop debug.sf.enable_hwc_vds 0
setprop debug.sf.latch_unsignaled 1
setprop debug.performance.tuning 1
setprop debug.sf.showbackground 0
setprop debug.egl.disable_msaa true
setprop debug.composition.type gpu
setprop debug.rs.qcom.force_finish 1
setprop debug.rs.qcom.noobjcache 1
setprop debug.gr.numframebuffers 2
setprop debug.rs.qcom.disable_flex 1
setprop debug.hwui.nv_profiling false
setprop debug.rs.qcom.adrenoboost 1
setprop debug.rs.qcom.dump_setup 0
setprop debug.hwui.skp_filename false
setprop debug.hwui.disable_vsync true
setprop debug.hwui.render_thread true
setprop debug.rs.qcom.nointrinsicblur 1
setprop debug.rs.qcom.nointrinsicblas 1
setprop debug.rs.qcom.use_fast_math 1
setprop debug.skia.threaded_mode true
setprop debug.sqlite.wal.syncmode OFF
setprop debug.rs.qcom.dump_bitcode 0
setprop debug.qualcomm.sns.daemon 0
setprop debug.atrace.tags.enableflags 0
setprop debug.sf.disable_backpressure 1
setprop debug.rs.qcom.disable_expand 1
setprop debug.hwui.use_buffer_age false
setprop debug.skia.num_render_threads 1
setprop debug.qualcomm.sns.libsensor1 0
setprop debug.gralloc.gfx_ubwc_disable 1
setprop debug.hwui.render_thread_count 1
setprop debug.sf.enable_gl_backpressure 1
setprop debug.hwui.clip_surfaceviews false
setprop debug.hwui.use_hint_manager false
setprop debug.hwui.disable_draw_defer true
setprop debug.hwui.show_dirty_regions false
setprop debug.hwui.8bit_hdr_headroom false
setprop debug.hwui.skip_empty_damage true
setprop debug.hwui.app_memory_policy false
setprop debug.hwui.filter_test_overhead false
setprop debug.hwui.use_partial_updates false
setprop debug.hwui.skia_atrace_enabled false
setprop debug.hwui.render_dirty_regions false
setprop debug.hwui.skia_tracing_enabled false
setprop debug.hwui.disable_draw_reorder true
setprop debug.skia.render_thread_priority true
setprop debug.hwui.trace_gpu_resources false
setprop debug.hwui.target_cpu_time_percent 1
setprop debug.hwui.capture_skp_enabled false
setprop debug.hwui.show_layers_updates false
setprop debug.hwui.use_gpu_pixel_buffers true
setprop debug.sf.early_phase_offset_ns 500000
setprop debug.rs.qcom.disable_performancehint 1
setprop debug.sf.enable_transaction_tracing false
setprop debug.hwui.webview_overlays_enabled true
setprop debug.renderengine.backend skiaglthreaded
setprop debug.sf.early_gl_phase_offset_ns 3000000
setprop debug.sf.disable_client_composition_cache 0
setprop debug.sf.early_app_phase_offset_ns 500000
setprop debug.hwui.skia_use_perfetto_track_events false
setprop debug.sf.early_gl_app_phase_offset_ns 15000000
setprop debug.sf.high_fps_early_phase_offset_ns 6100000
setprop debug.renderthread.skia.reduceopstasksplitting true
setprop debug.sf.high_fps_early_gl_phase_offset_ns 650000
setprop debug.sf.high_fps_late_app_phase_offset_ns 100000
setprop debug.sf.phase_offset_threshold_for_next_vsync_ns 6100000

settings put global auto_sync 0
settings put global ble_scan_always_enabled 0
settings put global wifi_scan_always_enabled 0
settings put global hotword_detection_enabled 0
settings put global activity_starts_logging_enabled 0
settings put global network_recommendations_enabled 0
settings put secure adaptive_sleep 0
settings put secure screensaver_enabled 0
settings put secure send_action_app_error 0
settings put secure screensaver_activate_on_dock 0
settings put secure screensaver_activate_on_sleep 0
settings put system motion_engine 0
settings put system master_motion 0
settings put system rakuten_denwa 0
settings put system air_motion_engine 0
settings put system air_motion_wake_up 0
settings put system send_security_reports 0
settings put system intelligent_sleep_mode 0
settings put system nearby_scanning_enabled 0
settings put system nearby_scanning_permission_allowed 0

pm disable com.qualcomm.qti.cne
pm disable com.qualcomm.location.XT

cmd thermalservice override-status 0
cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

su -lp 2000 -c "cmd notification post -t 'SnapFest Tweaks' \
    -i 'file:///data/local/tmp/snapfest.png' \
    -I 'file:///data/local/tmp/snapfest.png' \
    'default' 'Successfully applied'" > /dev/null 2>&1

exit 0
