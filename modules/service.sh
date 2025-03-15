#!/system/bin/sh

ROOT_METHOD="Unknown"
ROOT_VERSION="Unknown"
BOARD_PLATFORM="Unknown"

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

BOARD_PLATFORM=$(getprop ro.board.platform | tr '[:lower:]' '[:upper:]')

MODDIR="/data/adb/modules/snapfest"
MODULE_PROP="${MODDIR}/module.prop"
BACKUP_PROP="${MODULE_PROP}.orig"

if [ -f "$MODULE_PROP" ] && [ ! -f "$BACKUP_PROP" ]; then
    cp "$MODULE_PROP" "$BACKUP_PROP"
fi

if [ -f "$MODULE_PROP" ]; then
    sed -i "s/^description=.*/description=[ 😋 SnapFest is running on ${BOARD_PLATFORM} | ✅ ${ROOT_METHOD} (${ROOT_VERSION}) ] Special performance module designed for Snapdragon devices !/" "$MODULE_PROP"
fi

while [ -z "$(resetprop sys.boot_completed)" ]; do
    sleep 5
done

find /sys/devices/system/cpu -maxdepth 1 -name 'cpu?' | while IFS= read -r cpu; do
  echo performance > "$cpu/cpufreq/scaling_governor"
done

for path in /sys/class/devfreq/*.ufshc /sys/class/devfreq/mmc*; do
    if [ -w "$path/governor" ]; then
        echo "performance" > "$path/governor"
    fi

    if [ -f "$path/available_frequencies" ]; then
        freq=$(cat "$path/available_frequencies" | tr ' ' '\n' | sort -nr | head -n 1)
        [ -n "$freq" ] && chmod 644 "$path/max_freq" && echo "$freq" > "$path/max_freq" && chmod 444 "$path/max_freq"
        [ -n "$freq" ] && chmod 644 "$path/min_freq" && echo "$freq" > "$path/min_freq" && chmod 444 "$path/min_freq"
    fi
done &

for path in /sys/devices/system/cpu/*/cpufreq; do
    cpu_maxfreq=$(cat "$path/cpuinfo_max_freq")
    
    for freq in scaling_max_freq scaling_min_freq; do
        target="$path/$freq"
        if [ -f "$target" ]; then
            chmod 644 "$target" >/dev/null 2>&1
            echo "$cpu_maxfreq" > "$target" 2>/dev/null
            chmod 444 "$target" >/dev/null 2>&1
        fi
    done
done &

for path in /sys/class/devfreq/*cpu-ddr-latfloor* /sys/class/devfreq/*cpu*-lat /sys/class/devfreq/*cpu-cpu-ddr-bw /sys/class/devfreq/*cpu-cpu-llcc-bw /sys/class/devfreq/*gpubw*; do
    if [ -e "$path/governor" ]; then
        echo "performance" > "$path/governor"
    fi
done &

for path in /sys/class/devfreq/*cpu*-lat /sys/class/devfreq/*cpu*-bw /sys/class/devfreq/*llccbw* /sys/class/devfreq/*bus_llcc* /sys/class/devfreq/*bus_ddr* /sys/class/devfreq/*l3-* /sys/class/devfreq/*memlat* /sys/class/devfreq/*cpubw* /sys/class/devfreq/*gpubw* /sys/class/devfreq/*kgsl-ddr-qos*; do
    [ ! -d "$path" ] && continue
    freq=$(cat "$path/available_frequencies" | tr ' ' '\n' | sort -nr | head -n 1)
    [ -n "$freq" ] && chmod 644 "$path/max_freq" && echo "$freq" > "$path/max_freq" && chmod 444 "$path/max_freq"
    [ -n "$freq" ] && chmod 644 "$path/min_freq" && echo "$freq" > "$path/min_freq" && chmod 444 "$path/min_freq"
done &

for component in LLCC L3 DDR DDRQOS; do
    base_path="/sys/devices/system/cpu/bus_dcvs/$component"
    [ ! -d "$base_path" ] && continue
    freq_file="$base_path/available_frequencies"
    [ ! -f "$freq_file" ] && continue

    freq=$(cat "$freq_file" | tr ' ' '\n' | sort -nr | head -n 1)
    [ -z "$freq" ] && continue

    for path in "$base_path"/*/max_freq "$base_path"/*/min_freq; do
        [ -e "$path" ] && chmod 644 "$path" && echo "$freq" > "$path" && chmod 444 "$path"
    done &
done

gpu_path="/sys/class/kgsl/kgsl-3d0/devfreq"
if [ -d "$gpu_path" ] && [ -f "$gpu_path/available_frequencies" ]; then
    freq=$(cat "$gpu_path/available_frequencies" | tr ' ' '\n' | sort -nr | head -n 1)
    [ -n "$freq" ] && chmod 644 "$gpu_path/min_freq" && echo "$freq" > "$gpu_path/min_freq" && chmod 444 "$gpu_path/min_freq"
    [ -n "$freq" ] && chmod 644 "$gpu_path/max_freq" && echo "$freq" > "$gpu_path/max_freq" && chmod 444 "$gpu_path/max_freq"
fi

target_freq=$(cat /sys/class/devfreq/mmc*/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)

for block in /sys/block/*; do
    queue="$block/queue"
    if [ -d "$queue" ]; then
        if [ -f "$queue/scheduler" ]; then
            sched=$(cat "$queue/scheduler")
            found=0
            for algo in cfq noop kyber bfq mq-deadline none; do
                if echo "$sched" | grep -q "$algo"; then
                    echo "$algo" > "$queue/scheduler"
                    found=1
                    break
                fi
            done
            [ "$found" -eq 0 ] && echo "mq-deadline" > "$queue/scheduler"
        fi

        echo "0" > "$queue/add_random"
        echo "0" > "$queue/iostats"
        echo "32" > "$queue/read_ahead_kb"
        echo "64" > "$queue/nr_requests"
    fi
done

for mmc_tweak in /sys/class/devfreq/mmc*; do
    [ -e "$mmc_tweak" ] || continue
    echo "$target_freq" > "$mmc_tweak/min_freq"
    echo "100" > "$mmc_tweak/up_threshold"
    echo "20" > "$mmc_tweak/down_threshold"
    echo "10" > "$mmc_tweak/polling_interval"
done

for mmc_host in /sys/class/devfreq/mmc*/clk_scaling; do
    [ -e "$mmc_host" ] || continue
    echo "90" > "$mmc_host/up_threshold"
    echo "15" > "$mmc_host/down_threshold"
    echo "50" > "$mmc_host/polling_interval"
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
        echo "100000000" > "$gpu/idle_timer"
    fi
    if [ -e "$gpu/max_pwrlevel" ]; then
        echo "0" > "$gpu/max_pwrlevel"
    fi
    if [ -e "$gpu/snapshot/dump" ]; then
        echo "0" > "$gpu/snapshot/dump"
    fi
    if [ -e "$gpu/snapshot/snapshot_crashdumper" ]; then
        echo "0" > "$gpu/snapshot/snapshot_crashdumper"
    fi
done

find /sys/ -type f -name "*throttling*" | while IFS= read -r throttling; do
    [ -w "$throttling" ] && echo 0 > "$throttling" 2>/dev/null
done

lib_names="com.miHoYo. com.activision. com.garena. com.roblox. com.proxima com.tencent com.epicgames com.dts. UnityMain UnityGfxDeviceW libunity.so libil2cpp.so libfb.so libmain.so libcri_vip_unity.so libopus.so libxlua.so libUE4.so libAsphalt9.so libnative-lib.so libRiotGamesApi.so libResources.so libagame.so libapp.so libflutter.so libMSDKCore.so libFIFAMobileNeon.so libUnreal.so libEOSSDK.so libcocos2dcpp.so libgodot_android.so libgdx.so libgdx-box2d.so libminecraftpe.so libLive2DCubismCore.so libyuzu-android.so libryujinx.so libcitra-android.so libhdr_pro_engine.so libandroidx.graphics.path.so libeffect.so"

paths=(
    "/proc/sys/kernel/sched_lib_name"
    "/proc/sys/kernel/sched_lib_mask_force"
    "/proc/sys/walt/sched_lib_name"
    "/proc/sys/walt/sched_lib_mask_force"
)

for path in "${paths[@]}"; do
    if [ -f "$path" ]; then
        chmod +w "$path" 2>/dev/null
        if [[ "$path" == */sched_lib_name ]]; then
            echo "$lib_names" > "$path" 2>/dev/null
        elif [[ "$path" == */sched_lib_mask_force ]]; then
            echo "255" > "$path" 2>/dev/null
        fi
        chmod 444 "$path" 2>/dev/null
    fi
done

for svc in logd traced statsd; do
    if getprop init.svc.$svc | grep -q "running"; then
        su -c "stop $svc"
    fi
done

for touch in /sys/module/msm_performance/parameters/touchboost /sys/power/pnpmgr/touch_boost /proc/perfmgr/tchbst/kernel/tb_enable /sys/devices/virtual/touch/touch_boost /sys/module/msm_perfmon/parameters/touch_boost_enable /sys/devices/platform/goodix_ts.0/switch_report_rate; do
    if [ -f "$touch" ]; then
        chmod 644 "$touch" >/dev/null 2>&1
        echo "1" > "$touch" 2>/dev/null
        chmod 444 "$touch" >/dev/null 2>&1
    fi
done

[ -e /sys/module/adreno_idler/parameters/adreno_idler_active ] && echo "1" > /sys/module/adreno_idler/parameters/adreno_idler_active
[ -e /sys/devices/system/cpu/cpu_boost/sched_boost_on_input ] && echo "0" > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input

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

echo "0" > /sys/kernel/rcu_normal
echo "0" > /sys/kernel/rcu_expedited
echo "1" > /proc/sys/kernel/timer_migration
echo "0" > /sys/devices/system/cpu/isolated
echo "0" > /proc/sys/kernel/hung_task_timeout_secs

echo "1" > /dev/stune/top-app/schedtune.boost
echo "0" > /dev/stune/top-app/schedtune.prefer_idle
echo "NEXT_BUDDY" > /sys/kernel/debug/sched_features
echo "NO_TTWU_QUEUE" > /sys/kernel/debug/sched_features

echo "0" > /sys/kernel/ccci/debug
echo "0" > /sys/kernel/debug/rpm_log
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
setprop debug.hwui.level 2
setprop debug.sf.showfps 0
setprop debug.sf.showcpu 0
setprop debug.sf.showupdates 0
setprop debug.hwui.renderer skiagl
setprop debug.performance.tuning 1
setprop debug.sf.showbackground 0
setprop debug.hwui.skip_empty_damage true
setprop debug.hwui.render_dirty_regions false
setprop debug.sf.early_phase_offset_ns 500000
setprop debug.sf.early_gl_phase_offset_ns 3000000
setprop debug.sf.early_app_phase_offset_ns 500000
setprop debug.sf.early_gl_app_phase_offset_ns 15000000
setprop debug.sf.high_fps_early_phase_offset_ns 6100000
setprop debug.sf.high_fps_early_gl_phase_offset_ns 650000
setprop debug.sf.high_fps_late_app_phase_offset_ns 100000
setprop debug.sf.phase_offset_threshold_for_next_vsync_ns 6100000

settings put global auto_sync 0
settings put global ble_scan_always_enabled 0
settings put global wifi_scan_always_enabled 0
settings put global hotword_detection_enabled 0
settings put global activity_starts_logging_enabled 0
settings put secure adaptive_sleep 0
settings put secure screensaver_enabled 0
settings put secure send_action_app_error 0
settings put system motion_engine 0
settings put system master_motion 0
settings put system air_motion_engine 0
settings put system air_motion_wake_up 0
settings put system send_security_reports 0
settings put system intelligent_sleep_mode 0
settings put system nearby_scanning_enabled 0
settings put system nearby_scanning_permission_allowed 0

pm disable com.qualcomm.qti.cne
pm disable com.qualcomm.location.XT

cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

su -lp 2000 -c "cmd notification post -t 'SnapFest Tweaks' \
    -i 'file:///data/local/tmp/snapfest.png' \
    -I 'file:///data/local/tmp/snapfest.png' \
    'default' 'Successfully applied'" > /dev/null 2>&1

exit 0
