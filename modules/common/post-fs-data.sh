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

MODPATH=/data/adb/modules/snapfest

mkdir -p "$MODPATH"/system/lib/egl
mkdir -p "$MODPATH"/system/lib64/egl
mkdir -p "$MODPATH"/system/vendor/lib/egl
mkdir -p "$MODPATH"/system/vendor/lib64/egl

model=$(cat /sys/class/kgsl/kgsl-3d0/gpu_model)
config="0 1 $model"

echo "$config" > "$MODPATH"/system/lib/egl/egl.cfg
echo "$config" > "$MODPATH"/system/lib64/egl/egl.cfg
echo "$config" > "$MODPATH"/system/vendor/lib/egl/egl.cfg
echo "$config" > "$MODPATH"/system/vendor/lib64/egl/egl.cfg

echo "0" > /sys/block/sda/queue/iostats
echo "0" > /sys/block/loop1/queue/iostats
echo "0" > /sys/block/loop2/queue/iostats
echo "0" > /sys/block/loop3/queue/iostats
echo "0" > /sys/block/loop4/queue/iostats
echo "0" > /sys/block/loop5/queue/iostats
echo "0" > /sys/block/loop6/queue/iostats
echo "0" > /sys/block/loop7/queue/iostats
echo "0" > /sys/block/dm-0/queue/iostats
echo "0" > /sys/block/loop0/queue/iostats
echo "0" > /sys/block/mmcblk1/queue/iostats
echo "0" > /sys/block/mmcblk0/queue/iostats
echo "0" > /sys/block/mmcblk0rpmb/queue/iostats

echo "N" > /sys/module/kernel/parameters/initcall_debug
echo "0" > /sys/module/printk/parameters/console_suspend
echo "bbr" > /sys/module/tcp_bbr/parameters/tcp_congestion_control

set_properties="
sys.use_fifo_ui=1
logcat.live=disable
persist.sys.ui.hw=1
ro.kernel.checkjni=0
profiler.launch=false
ro.min_pointer_dur=8
com.qc.hardware=true
debugtool.anrhistory=0
camera.debug.logfile=0
sys.lmk.reportkills=false
dalvik.vm.debug.alloc=0
dalvik.vm.checkjni=false
ro.min.fling_velocity=8000
ro.hwui.render_ahead=true
pm.dexopt.boot=everything
persist.sys.lgospd.enable=0
dev.pm.dyn_samplingrate=1
profiler.debugmonitor=false
persist.sys.scrollingcache=2
persist.sys.pcsync.enable=0
ro.kernel.android.checkjni=0
ro.max.fling_velocity=20000
dalvik.vm.jmiopts=forcecopy
profiler.force_disable_ulog=1
persist.android.strictmode=0
pm.dexopt.install=everything
ro.ui.pipeline=skiaglthreaded
persist.sys.egl.swapinterval=1
ro.vendor.perf.scroll_opt=true
dalvik.vm.minidebuginfo=false
persist.sys.use_16bpp_alpha=1
ro.zygote.disable_gl_preload=1
persist.sys.purgeable_assets=1
dalvik.vm.deadlock-predict=off
persist.sys.lmk.reportkills=false
profiler.force_disable_err_rpt=1
dalvik.vm.check-dex-sum=false
persist.service.lgospd.enable=0
dalvik.vm.verify-bytecode=false
persist.service.pcsync.enable=0
dalvik.vm.execution-mode=int:jit
ro.hwui.use_skiaglthreaded=true
pm.dexopt.first-boot=everything
ro.hwui.disable_scissor_opt=false
pm.dexopt.bg-dexopt=everything
persist.sys.dalvik.multithread=true
dalvik.vm.dex2oat64.enabled=true
vendor.perf.framepacing.enable=1
dalvik.vm.dexopt.thermal-cutoff=0
dalvik.vm.dex2oat-filter=everything
persist.sys.debug.gr.swapinterval=1
profiler.hung.dumpdobugreport=false
ro.hwui.hardware.skiaglthreaded=true
persist.sys.dalvik.hyperthreading=true
windowsmgr.max_event_per_sec=200
ro.config.cpu_thermal_throttling=false
dalvik.vm.dex2oat-minidebuginfo=false
ro.vendor.qti.sys.fw.bservice_enable=true
dalvik.vm.image-dex2oat-filter=everything
ro.surface_flinger.set_idle_timer_ms=1000
ro.surface_flinger.set_touch_timer_ms=100
ro.surface_flinger.protected_contents=true
persist.sys.gpu.working_thread_priority=true
renderthread.skia.reduceopstasksplitting=true
dalvik.vm.dexopt-flags=m=y,v=everything,o=everything
persist.sys.perf.topAppRenderThreadBoost.enable=true
renderthread.skiaglthreaded.reduceopstasksplitting=true
"

reset_properties="
rw.logger=0
log.tag.all=0
log.shaders=0
config.stats=0
logd.statistics=0
ro.logd.size=OFF
ro.debuggable=0
sys.init_log_level=0
ro.logd.kernel=false
persist.logd.limit=OFF
log.tag.stats_log=OFF
ro.logd.size.stats=64K
ro.iorapd.enable=false
persist.logd.size.radio=1M
persist.logd.size.crash=1M
persist.logd.size.radio=OFF
ro.logdumpd.enabled=false
media.stagefright.log-uri=0
persist.logd.size.crash=OFF
persist.logd.size.system=1M
persist.sys.perf.debug=false
persist.logd.size.system=OFF
logd.logpersistd.enable=false
tombstoned.max_anr_count=0
db.log.slow_query_threshold=0
persist.data.qmi.adb_logmask=0
persist.ims.disableIMSLogs=true
persist.service.logd.enable=false
persist.ims.disableADBLogs=true
db.log.slow_query_threshold=999
vendor.debug.rs.qcom.verbose=0
persist.vendor.radio.adb_log_on=0
persist.ims.disableQXDMLogs=true
persist.ims.disableDebugLogs=true
ro.vendor.connsys.dedicated.log=0
vendor.bluetooth.startbtlogger=false
vendor.debug.rs.qcom.dump_setup=0
vendor.debug.rs.qcom.dump_bitcode=0
ro.surface_flinger.protected_contents=true
persist.bluetooth.btsnooplogmode=disabled
persist.vendor.radio.snapshot_enabled=false
persist.vendor.verbose_logging_enabled=false
ro.surface_flinger.has_wide_color_display=true
ro.surface_flinger.use_color_management=true
persist.vendor.sys.modem.logging.enable=false
persist.sys.turbosched.enable.coreApp.optimizer=true
ro.surface_flinger.max_virtual_display_dimension=4096
ro.surface_flinger.running_without_sync_framework=true
ro.surface_flinger.force_hwc_copy_for_virtual_displays=true
persist.device_config.runtime_native_boot.iorap_perfetto_enable=false
persist.device_config.runtime_native_boot.iorap_readahead_enable=false
persist.device_config.surface_flinger_native_boot.SkiaTracingFeature_use_skia_tracing=true
"

for prop in $set_properties; do
    prop_name="${prop%%=*}"
    prop_value="${prop#*=}"
    setprop "$prop_name" "$prop_value"
done

for prop in $reset_properties; do
    prop_name="${prop%%=*}"
    prop_value="${prop#*=}"
    resetprop -n "$prop_name" "$prop_value"
done

rm "$MODPATH"/post-fs-data.sh
