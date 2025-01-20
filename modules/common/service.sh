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

echo "0" > /sys/class/kgsl/kgsl-3d0/throttling
echo "0" > /sys/class/kgsl/kgsl-3d0/bus_split
echo "1" > /sys/class/kgsl/kgsl-3d0/force_no_nap
echo "1" > /sys/class/kgsl/kgsl-3d0/force_rail_on
echo "1" > /sys/class/kgsl/kgsl-3d0/force_bus_on
echo "1" > /sys/class/kgsl/kgsl-3d0/force_clk_on

echo "1" /sys/kernel/fast_charge/force_fast_charge
echo "1" /sys/class/power_supply/battery/system_temp_level
echo "1" /sys/kernel/fast_charge/failsafe
echo "1" /sys/class/power_supply/battery/allow_hvdcp3
echo "1" /sys/class/power_supply/usb/pd_allowed
echo "1" /sys/class/power_supply/battery/subsystem/usb/pd_allowed
echo "0" /sys/class/power_supply/battery/input_current_limited
echo "1" /sys/class/power_supply/battery/input_current_settled
echo "0" /sys/class/qcom-battery/restricted_charging
echo "150" /sys/class/power_supply/bms/temp_cool
echo "480" /sys/class/power_supply/bms/temp_hot
echo "480" /sys/class/power_supply/bms/temp_warm

echo "4000000" > /sys/class/power_supply/battery/constant_charge_current_max
echo "4000000" > /sys/class/power_supply/battery/input_current_max
chmod 444 /sys/class/power_supply/battery/constant_charge_current_max
chmod 444 /sys/class/power_supply/battery/input_current_max

echo "500" > /sys/module/qti_haptics/parameters/vmax_mv_override
chmod 444 /sys/module/qti_haptics/parameters/vmax_mv_override

echo "0" > /d/tracing/tracing_on
echo "0" > /sys/kernel/debug/rpm_log
echo "0" > /sys/module/rmnet_data/parameters/rmnet_data_log_level
echo "500" > /sys/module/qti_haptics/parameters/vmax_mv_override

echo "1" > /sys/module/spurious/parameters/noirqdebug
echo "0" > /sys/kernel/debug/sde_rotator0/evtlog/enable
echo "0" > /sys/kernel/debug/dri/0/debug/enable
echo "0" > /proc/sys/debug/exception-trace
echo "0" > /proc/sys/kernel/sched_schedstats

echo "0 0 0 0" > "/proc/sys/kernel/printk"
echo "0" > "/sys/kernel/printk_mode/printk_mode"
echo "0" > "/sys/module/printk/parameters/cpu"
echo "0" > "/sys/module/printk/parameters/pid"
echo "0" > "/sys/module/printk/parameters/printk_ratelimit"
echo "0" > "/sys/module/printk/parameters/time"
echo "1" > "/sys/module/printk/parameters/console_suspend"
echo "1" > "/sys/module/printk/parameters/ignore_loglevel"
echo "N" > "/sys/module/sync/parameters/fsync_enabled"
echo "off" > "/proc/sys/kernel/printk_devkmsg"

echo "0:1800000" > /sys/devices/system/cpu/cpu_boost/parameters/input_boost_freq
echo "230" > /sys/devices/system/cpu/cpu_boost/parameters/input_boost_ms

echo "0" > /proc/sys/kernel/sched_schedstats
echo "0" > /proc/sys/kernel/sched_autogroup_enabled
echo "1" > /proc/sys/kernel/sched_child_runs_first
echo "32" > /proc/sys/kernel/sched_nr_migrate
echo "50000" > /proc/sys/kernel/sched_migration_cost_ns
echo "1000000" > /proc/sys/kernel/sched_min_granularity_ns
echo "1500000" > /proc/sys/kernel/sched_wakeup_granularity_ns
echo "0" > /proc/sys/vm/page-cluster
echo "120" > /proc/sys/vm/stat_interval
echo "0" > /proc/sys/vm/compaction_proactiveness
echo "0" > /sys/module/mmc_core/parameters/use_spi_crc
echo "0" > /sys/module/cpufreq_bouncing/parameters/enable
echo "0" > /proc/task_info/task_sched_info/task_sched_info_enable
echo "0" > /proc/oplus_scheduler/sched_assist/sched_assist_enabled

echo "3" > /proc/sys/vm/drop_caches
echo "1" > /proc/sys/vm/compact_memory

lib_names="com.miHoYo., com.activision., com.garena., com.roblox., com.epicgames, com.dts., UnityMain, libunity.so, libil2cpp.so, libmain.so, libcri_vip_unity.so, libopus.so, libxlua.so, libUE4.so, libAsphalt9.so, libnative-lib.so, libRiotGamesApi.so, libResources.so, libagame.so, libapp.so, libflutter.so, libMSDKCore.so, libFIFAMobileNeon.so, libUnreal.so, libEOSSDK.so, libcocos2dcpp.so, libgodot_android.so, libgdx.so, libgdx-box2d.so, libminecraftpe.so, libLive2DCubismCore.so, libyuzu-android.so, libryujinx.so, libcitra-android.so, libhdr_pro_engine.so, libandroidx.graphics.path.so, libeffect.s"

echo "$lib_names" > /proc/sys/kernel/sched_lib_name
echo "255" > /proc/sys/kernel/sched_lib_mask_force
echo "$lib_names" > /proc/sys/walt/sched_lib_name
echo "255" > /proc/sys/walt/sched_lib_mask_force

if [ -f /sys/module/battery_saver/parameters/enabled ]; then
    if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
        echo "0" > /sys/module/battery_saver/parameters/enabled
    else
        echo "N" > /sys/module/battery_saver/parameters/enabled
    fi
fi

if grep -q bbr2 /proc/sys/net/ipv4/tcp_available_congestion_control; then
    echo "bbr2" > /proc/sys/net/ipv4/tcp_congestion_control
else
    echo "cubic" > /proc/sys/net/ipv4/tcp_congestion_control
fi

echo "1" > /proc/sys/net/ipv4/tcp_low_latency
echo "1" > /proc/sys/net/ipv4/tcp_ecn
echo "3" > /proc/sys/net/ipv4/tcp_fastopen
echo "1" > /proc/sys/net/ipv4/tcp_sack
echo "0" > /proc/sys/net/ipv4/tcp_timestamps

echo "0" > /sys/kernel/ccci/debug
echo "0" > /sys/kernel/tracing/tracing_on
echo "0" > /proc/sys/kernel/perf_event_paranoid
echo "0" > /proc/sys/kernel/debug_locks
echo "0" > /proc/sys/kernel/perf_cpu_time_max_percent
echo "off" > /proc/sys/kernel/printk_devkmsg

su -c "stop mi_thermald"
su -c "stop thermal-engine"
su -c "stop vendor.thermal-engine"
su -c "stop traced"
su -c "stop tombstoned"
su -c "stop tcpdump"
su -c "stop cnss_diag"
su -c "stop statsd"
su -c "stop vendor.perfservice"
su -c "stop logcat"
su -c "stop logcatd"
su -c "stop logd"
su -c "stop idd-logreader"
su -c "stop idd-logreadermain"
su -c "stop stats"
su -c "stop dumpstate"
su -c "stop vendor.tcpdump"
su -c "stop vendor_tcpdump"
su -c "stop vendor.cnss_diag"

killall -9 logd
killall -9 logcat
killall -9 logcatd
killall -9 logd.rc
killall -9 traced
killall -9 tombstoned

rm -rf /data/anr/*
rm -rf /dev/log/*
rm -rf /data/tombstones/*
rm -rf /data/log_other_mode/*
rm -rf /data/system/dropbox/*
rm -rf /data/system/usagestats/*
rm -rf /data/log/*
rm -rf /sys/kernel/debug/*
rm -rf /storage/emulated/0/*.log;

for i in "debug_mask" "log_level*" "debug_level*" "*debug_mode" "enable_ramdumps" "edac_mc_log*" "enable_event_log" "*log_level*" "*log_ue*" "*log_ce*" "log_ecn_error" "snapshot_crashdumper" "seclog*" "compat-log" "*log_enabled" "tracing_on" "mballoc_debug"; do
    find /sys/ -type f -name "$i" | while IFS= read -r log_file; do
        if [ -w "$log_file" ]; then
            echo "0" > "$log_file"
        fi
    done
done

for corecpu in /sys/devices/system/cpu/cpu[1-7] /sys/devices/system/cpu/cpu1[0-7]; do
    [ -w "$corecpu/core_ctl/enable" ] && echo "1" > "$corecpu/core_ctl/enable"
    [ -w "$corecpu/core_ctl/core_ctl_boost" ] && echo "1" > "$corecpu/core_ctl/core_ctl_boost"
done

for pl in /sys/devices/system/cpu/perf; do
    [ -w "$pl/gpu_pmu_enable" ] && echo "1" > "$pl/gpu_pmu_enable"
    [ -w "$pl/fuel_gauge_enable" ] && echo "1" > "$pl/fuel_gauge_enable"
    [ -w "$pl/enable" ] && echo "1" > "$pl/enable"
    [ -w "$pl/charger_enable" ] && echo "1" > "$pl/charger_enable"
done

[ -w /proc/ppm/enabled ] && echo "1" > /proc/ppm/enabled
for i in $(seq 0 9); do
    [ -w /proc/ppm/policy_status ] && echo "$i 0" > /proc/ppm/policy_status
done
[ -w /proc/ppm/policy_status ] && echo "7 1" > /proc/ppm/policy_status

for thermal in $(resetprop | awk -F '[][]' '/thermal|init.svc.vendor.thermal-hal/ {print $2}'); do
  if [[ $(resetprop "$thermal") == "running" || $(resetprop "$thermal") == "restarting" ]]; then
    service_name="${thermal/init.svc.vendor.thermal-hal/}"
    stop "${thermal/init.svc.}" || true
    sleep 10
    resetprop -n "$thermal" stopped
  fi
done

for thermal_zone in /sys/class/thermal/thermal_zone*; do
    if [ -w "$thermal_zone/mode" ]; then
        echo 'disabled' > "$thermal_zone/mode"
    fi
done

for thermal_zone in /sys/class/thermal/thermal_zone*; do
    if [ -w "$thermal_zone/temp" ]; then
        chmod 000 "$thermal_zone/temp"
    fi
done

find /sys -name mode | grep 'thermal_zone' | while IFS= read -r thermal_zone_status; do
    if [ -r "$thermal_zone_status" ]; then
        thermal_mode=$(cat "$thermal_zone_status")
        if [ "$thermal_mode" = 'enabled' ]; then
            echo 'disabled' > "$thermal_zone_status"
        fi
    fi
done

find /sys/devices/virtual/thermal -type f -exec chmod 000 {} +

if service list | grep -qi thermal; then
    for svc in $(service list | grep -i thermal | awk -F ' ' '{print $4}'); do
        start $svc
        stop $svc
        cmd thermalservice override-status 0 || true
    done
fi

if pgrep -i thermal > /dev/null; then
    for pid in $(pgrep -i thermal); do
        kill -SIGSTOP $pid || true
    done
fi

if command -v resetprop > /dev/null; then
    resetprop -v | grep -i 'thermal.*running' | awk -F '[][]' '{print $2}' | while read -r prop; do
        resetprop $prop freezed || true
    done
fi

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

if resetprop dalvik.vm.dexopt.thermal-cutoff | grep -q '2'; then
    resetprop -n dalvik.vm.dexopt.thermal-cutoff 0
  fi
  if resetprop sys.thermal.enable | grep -q 'true'; then
    resetprop -n sys.thermal.enable false
  fi
  if resetprop ro.thermal_warmreset | grep -q 'true'; then
    resetprop -n ro.thermal_warmreset false
  fi

  rm -f /data/vendor/thermal/config
  rm -f /data/vendor/thermal/thermal.dump
  rm -f /data/vendor/thermal/last_thermal.dump
  rm -f /data/vendor/thermal/thermal_history.dump
    for therm_serv in $thermal_prop; do
        stop $therm_serv
    done

back=/dev/cpuset/background/cpus
echo "0-1" > $back

system=/dev/cpuset/system-background/cpus
echo "0-2" > $system

for=/dev/cpuset/foreground/cpus
echo "0-7" > $for

top=/dev/cpuset/top-app/cpus
echo "0-7" > $top

fore=/dev/stune/foreground/schedtune.boost
echo "5" > $fore

topp=/dev/stune/top-app/schedtune.boost
echo "5" > $topp

back=/dev/stune/background/schedtune.boost
echo "5" > $back

dow=/proc/sys/kernel/sched_downmigrate
echo "40 40" > $dow

sch=/proc/sys/kernel/sched_upmigrate
echo "60 60" > $sch

boost=/proc/sys/kernel/sched_boost
echo "1" > $boost

if [ -e /sys/class/kgsl/kgsl-3d0/snapshot/snapshot_crashdumper ]; then
  echo "0" > /sys/class/kgsl/kgsl-3d0/snapshot/snapshot_crashdumper
fi
if [ -e /sys/class/kgsl/kgsl-3d0/snapshot/dump ]; then
  echo "0" > /sys/class/kgsl/kgsl-3d0/snapshot/dump
fi
if [ -e /sys/class/kgsl/kgsl-3d0/snapshot/force_panic ]; then
  echo "0" > /sys/class/kgsl/kgsl-3d0/snapshot/force_panic
fi

if [ -e /sys/module/adreno_idler/parameters/adreno_idler_active ]; then
  echo "1" > /sys/module/adreno_idler/parameters/adreno_idler_active
fi

for rx in /sys/module/lpm_levels/parameters/*; do
  if [ -e "$rx/lpm_ipi_prediction" ]; then
    echo "0" > "$rx/lpm_ipi_prediction"
  fi
  if [ -e "$rx/lpm_prediction" ]; then
    echo "0" > "$rx/lpm_prediction"
  fi
  if [ -e "$rx/sleep_disabled" ]; then
    echo "0" > "$rx/sleep_disabled"
  fi
done

for rcct in /sys/devices/system/cpu/*/core_ctl; do
  if [ -e "$rcct/enable" ]; then
    chmod 666 "$rcct/enable"
    echo "0" > "$rcct/enable"
    chmod 444 "$rcct/enable"
  fi
done

for gpu in /sys/class/kgsl/kgsl-3d0; do
  if [ -e "$gpu/adrenoboost" ]; then
    echo "0" > "$gpu/adrenoboost"
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

if [ -d /sys/devices/system/cpu/bus_dcvs/LLCC ]; then
    freq=$(cat /sys/devices/system/cpu/bus_dcvs/LLCC/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
    if [ -n "$freq" ]; then
        for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/max_freq; do
            echo $freq > "$path"
        done
        for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/min_freq; do
            echo $freq > "$path"
        done
    fi
fi

if [ -d /sys/devices/system/cpu/bus_dcvs/L3 ]; then
    freq=$(cat /sys/devices/system/cpu/bus_dcvs/L3/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
    if [ -n "$freq" ]; then
        for path in /sys/devices/system/cpu/bus_dcvs/L3/*/max_freq; do
            echo $freq > "$path"
        done
        for path in /sys/devices/system/cpu/bus_dcvs/L3/*/min_freq; do
            echo $freq > "$path"
        done
    fi
fi

if [ -d /sys/devices/system/cpu/bus_dcvs/DDR ]; then
    freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDR/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
    if [ -n "$freq" ]; then
        for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/max_freq; do
            echo $freq > "$path"
        done
        for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/min_freq; do
            echo $freq > "$path"
        done
    fi
fi

if [ -d /sys/devices/system/cpu/bus_dcvs/DDRQOS ]; then
    freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDRQOS/available_frequencies | tr ' ' '\n' | sort -nr | head -n 1)
    if [ -n "$freq" ]; then
        for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/max_freq; do
            echo $freq > "$path"
        done
        for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/min_freq; do
            echo $freq > "$path"
        done
    fi
fi

[ -w /sys/module/workqueue/parameters/power_efficient ] && echo "N" > /sys/module/workqueue/parameters/power_efficient
[ -w /sys/module/workqueue/parameters/disable_numa ] && echo "N" > /sys/module/workqueue/parameters/disable_numa

[ -w /sys/devices/system/cpu/eas/enable ] && echo "0" > /sys/devices/system/cpu/eas/enable
[ -w /proc/cpufreq/cpufreq_power_mode ] && echo "3" > /proc/cpufreq/cpufreq_power_mode
[ -w /proc/cpufreq/cpufreq_cci_mode ] && echo "1" > /proc/cpufreq/cpufreq_cci_mode
[ -w /proc/cpufreq/cpufreq_sched_disable ] && echo "1" > /proc/cpufreq/cpufreq_sched_disable

[ -w /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_fg_boost ] && echo "100" > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_fg_boost
[ -w /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost ] && echo "100" > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost
[ -w /proc/perfmgr/syslimiter/syslimiter_force_disable ] && echo "1" > /proc/perfmgr/syslimiter/syslimiter_force_disable

echo "0" > /sys/kernel/rcu_expedited 0
echo "0" > /sys/kernel/rcu_normal 0
echo "0" > /sys/devices/system/cpu/isolated 0
echo "0" > /proc/sys/kernel/sched_tunable_scaling 0
echo "1" > /proc/sys/kernel/timer_migration 1
echo "0" > /proc/sys/kernel/hung_task_timeout_secs 0
echo "25" > /proc/sys/kernel/perf_cpu_time_max_percent 25
echo "1" > /proc/sys/kernel/sched_autogroup_enabled 1
echo "0" > /proc/sys/kernel/sched_child_runs_first 0
echo "10000000" > /proc/sys/kernel/sched_latency_ns 
echo "2000000" > /proc/sys/kernel/sched_wakeup_granularity_ns 
echo "3200000" > /proc/sys/kernel/sched_min_granularity_ns 
echo "2000000" > /proc/sys/kernel/sched_migration_cost_ns 
echo "32" > /proc/sys/kernel/sched_nr_migrate

echo "deadline" > /sys/block/mmcblk0/queue/scheduler
echo "deadline" > /sys/block/mmcblk1/queue/scheduler
echo "1024" > /sys/block/mmcblk0/queue/read_ahead_kb
echo "1024" > /sys/block/mmcblk1/queue/read_ahead_kb
echo "75" > /sys/devices/system/cpu/cpufreq/performance/up_threshold
echo "40000" > /sys/devices/system/cpu/cpufreq/performance/sampling_rate
echo "5" > /sys/devices/system/cpu/cpufreq/performance/sampling_down_factor
echo "20" > /sys/devices/system/cpu/cpufreq/performance/down_threshold
echo "25" > /sys/devices/system/cpu/cpufreq/performance/freq_step/sys/class/kgsl/kgsl-3d0/devfreq/governor
echo "deadline" > /sys/block/sda/queue/scheduler
echo "1024" > /sys/block/sda/queue/read_ahead_kb
echo "0" > /sys/block/sda/queue/rotational
echo "0" > /sys/block/sda/queue/iostats
echo "0" > /sys/block/sda/queue/add_random
echo "1" > /sys/block/sda/queue/rq_affinity
echo "0" > /sys/block/sda/queue/nomerges
echo "1024" > /sys/block/sda/queue/nr_requests
echo "deadline" > /sys/block/sdb/queue/scheduler
echo "1024" > /sys/block/sdb/queue/read_ahead_kb
echo "0" > /sys/block/sdb/queue/rotational
echo "0" > /sys/block/sdb/queue/iostats
echo "0" > /sys/block/sdb/queue/add_random
echo "1" > /sys/block/sdb/queue/rq_affinity
echo "0" > /sys/block/sdb/queue/nomerges
echo "1024" > /sys/block/sdb/queue/nr_requests
echo "deadline" > /sys/block/sdc/queue/scheduler
echo "1024" > /sys/block/sdc/queue/read_ahead_kb
echo "0" > /sys/block/sdc/queue/rotational
echo "0" > /sys/block/sdc/queue/iostats
echo "0" > /sys/block/sdc/queue/add_random
echo "1" > /sys/block/sdc/queue/rq_affinity
echo "0" > /sys/block/sdc/queue/nomerges
echo "1024" > /sys/block/sdc/queue/nr_requests
echo "deadline" > /sys/block/sdd/queue/scheduler
echo "1024" > /sys/block/sdd/queue/read_ahead_kb
echo "0" > /sys/block/sdd/queue/rotational
echo "0" > /sys/block/sdd/queue/iostats
echo "0" > /sys/block/sdd/queue/add_random
echo "1" > /sys/block/sdd/queue/rq_affinity
echo "0" > /sys/block/sdd/queue/nomerges
echo "1024" > /sys/block/sdd/queue/nr_requests
echo "deadline" > /sys/block/sde/queue/scheduler
echo "1024" > /sys/block/sde/queue/read_ahead_kb
echo "0" > /sys/block/sde/queue/rotational
echo "0" > /sys/block/sde/queue/iostats
echo "0" > /sys/block/sde/queue/add_random
echo "1" > /sys/block/sde/queue/rq_affinity
echo "0" > /sys/block/sde/queue/nomerges
echo "1024" > /sys/block/sde/queue/nr_requests
echo "deadline" > /sys/block/sdf/queue/scheduler
echo "1024" > /sys/block/sdf/queue/read_ahead_kb
echo "0" > /sys/block/sdf/queue/rotational
echo "0" > /sys/block/sdf/queue/iostats
echo "0" > /sys/block/sdf/queue/add_random
echo "1" > /sys/block/sdf/queue/rq_affinity
echo "0" > /sys/block/sdf/queue/nomerges
echo "1024" > /sys/block/sdf/queue/nr_requests
echo "deadline" > /sys/block/mmcblk0/queue/scheduler
echo "1024" > /sys/block/mmcblk0/queue/read_ahead_kb
echo "0" > /sys/block/mmcblk0/queue/rotational
echo "0" > /sys/block/mmcblk0/queue/iostats
echo "0" > /sys/block/mmcblk0/queue/add_random
echo "1" > /sys/block/mmcblk0/queue/rq_affinity
echo "0" > /sys/block/mmcblk0/queue/nomerges
echo "1024" > /sys/block/mmcblk0/queue/nr_requests

echo "1" > /sys/power/pnpmgr/touch_boost
echo "1" > /sys/module/msm_performance/parameters/touchboost

echo "0" > /sys/kernel/msm_thermal/enabled
echo "N" > /sys/module/msm_thermal/parameters/enabled
echo "0" > /sys/module/msm_thermal/core_control/enabled
echo "0" > /sys/module/msm_thermal/vdd_restriction/enabled
echo "0" > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input

busybox=$(find /data/adb/ -type f -name busybox | head -n 1)
$busybox swapoff /dev/block/zram0
echo "1" > /sys/block/zram0/reset
echo "4294967296" > /sys/block/zram0/disksize
$busybox mkswap /dev/block/zram0
$busybox swapon /dev/block/zram0

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
setprop debug.mdpcomp.logs 0
setprop debug.qc.hardware true
setprop debug.hwui.fps_divisor 1
setprop debug.qctwa.statusbar 1
setprop debug.sf.showupdates 0
setprop debug.egl.disable_msaa 1
setprop debug.hwui.renderer skiagl
setprop debug.cpurend.vsync false
setprop debug.hwui.overdraw false
setprop debug.qctwa.preservebuf 1
setprop debug.sf.enable_hwc_vds 0
setprop debug.sf.latch_unsignaled 1
setprop debug.performance.tuning 1
setprop debug.sf.showbackground 0
setprop debug.composition.type gpu
setprop debug.egl.disable_msaa true
setprop debug.hwui.nv_profiling false
setprop debug.hwui.skp_filename false
setprop debug.hwui.disable_vsync true
setprop debug.hwui.render_thread true
setprop debug.skia.threaded_mode true
setprop debug.sf.disable_backpressure 1
setprop debug.hwui.use_buffer_age false
setprop debug.gralloc.gfx_ubwc_disable 1
setprop debug.skia.num_render_threads 1
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
settings put system vibrate_on 0
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

cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

su -lp 2000 -c "cmd notification post -t 'SnapFest Tweaks' \
    -i 'file:///data/local/tmp/snapfest.png' \
    -I 'file:///data/local/tmp/snapfest.png' \
    'default' 'Successfully applied'" > /dev/null 2>&1

exit 0
