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
ro.hwui.render_ahead=true
ro.ui.pipeline=skiaglthreaded
persist.sys.egl.swapinterval=1
ro.vendor.perf.scroll_opt=true
persist.sys.purgeable_assets=1
dalvik.vm.execution-mode=int:jit
vendor.perf.framepacing.enable=1
dalvik.vm.dexopt.thermal-cutoff=0
dalvik.vm.dex2oat-filter=everything
persist.sys.debug.gr.swapinterval=1
ro.hwui.hardware.skiaglthreaded=true
persist.sys.dalvik.hyperthreading=true
dalvik.vm.image-dex2oat-filter=everything
ro.surface_flinger.set_idle_timer_ms=1000
ro.surface_flinger.set_touch_timer_ms=100
persist.sys.perf.topAppRenderThreadBoost.enable=true
"

reset_properties="
ro.iorapd.enable=false
persist.sys.perf.debug=false
ro.surface_flinger.protected_contents=true
persist.vendor.verbose_logging_enabled=false
ro.surface_flinger.has_wide_color_display=true
ro.surface_flinger.use_color_management=true
persist.sys.turbosched.enable.coreApp.optimizer=true
ro.surface_flinger.max_virtual_display_dimension=4096
ro.surface_flinger.running_without_sync_framework=true
ro.surface_flinger.force_hwc_copy_for_virtual_displays=true
persist.device_config.runtime_native_boot.iorap_perfetto_enable=false
persist.device_config.runtime_native_boot.iorap_readahead_enable=false
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
