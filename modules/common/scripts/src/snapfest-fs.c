#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#define MODPATH "/data/adb/modules/snapfest"

void create_dirs() {
    const char *dirs[] = {
        MODPATH "/system/lib/egl",
        MODPATH "/system/lib64/egl",
        MODPATH "/system/vendor/lib/egl",
        MODPATH "/system/vendor/lib64/egl"
    };

    for (size_t i = 0; i < sizeof(dirs) / sizeof(dirs[0]); i++) {
        mkdir(dirs[i], 0755);
    }
}

void write_config() {
    FILE *file;
    char model[128] = "Unknown";
    FILE *gpu_file = fopen("/sys/class/kgsl/kgsl-3d0/gpu_model", "r");
    
    if (gpu_file) {
        fgets(model, sizeof(model), gpu_file);
        fclose(gpu_file);
    }
    
    char config[256];
    snprintf(config, sizeof(config), "0 1 %s", model);

    const char *paths[] = {
        MODPATH "/system/lib/egl/egl.cfg",
        MODPATH "/system/lib64/egl/egl.cfg",
        MODPATH "/system/vendor/lib/egl/egl.cfg",
        MODPATH "/system/vendor/lib64/egl/egl.cfg"
    };

    for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); i++) {
        file = fopen(paths[i], "w");
        if (file) {
            fputs(config, file);
            fclose(file);
        }
    }
}

void write_sys_values() {
    const char *sys_paths[] = {
        "/sys/block/sda/queue/iostats",
        "/sys/block/loop1/queue/iostats",
        "/sys/block/loop2/queue/iostats",
        "/sys/block/loop3/queue/iostats",
        "/sys/block/loop4/queue/iostats",
        "/sys/block/loop5/queue/iostats",
        "/sys/block/loop6/queue/iostats",
        "/sys/block/loop7/queue/iostats",
        "/sys/block/dm-0/queue/iostats",
        "/sys/block/loop0/queue/iostats",
        "/sys/block/mmcblk1/queue/iostats",
        "/sys/block/mmcblk0/queue/iostats",
        "/sys/block/mmcblk0rpmb/queue/iostats",
        "/sys/module/kernel/parameters/initcall_debug",
        "/sys/module/printk/parameters/console_suspend",
        "/sys/module/tcp_bbr/parameters/tcp_congestion_control"
    };

    const char *values[] = {
        "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "N", "0", "bbr"
    };

    for (size_t i = 0; i < sizeof(sys_paths) / sizeof(sys_paths[0]); i++) {
        FILE *file = fopen(sys_paths[i], "w");
        if (file) {
            fputs(values[i], file);
            fclose(file);
        }
    }
}

void set_properties() {
    const char *cmd = 
        "setprop sys.ui.hw 1 && "
        "setprop ro.kernel.checkjni 0 && "
        "setprop profiler.launch false && "
        "setprop com.qc.hardware true && "
        "setprop camera.debug.logfile 0 && "
        "setprop dalvik.vm.debug.alloc 0 && "
        "setprop dalvik.vm.checkjni false && "
        "setprop ro.hwui.render_ahead true && "
        "setprop pm.dexopt.boot everything && "
        "setprop dev.pm.dyn_samplingrate 1 && "
        "setprop dalvik.vm.jmiopts forcecopy && "
        "setprop pm.dexopt.install everything && "
        "setprop ro.ui.pipeline skiaglthreaded && "
        "setprop persist.sys.egl.swapinterval 1 && "
        "setprop ro.vendor.perf.scroll_opt true && "
        "setprop persist.sys.use_16bpp_alpha 1 && "
        "setprop persist.sys.purgeable_assets 1 && "
        "setprop dalvik.vm.deadlock-predict off && "
        "setprop dalvik.vm.check-dex-sum false && "
        "setprop dalvik.vm.verify-bytecode false && "
        "setprop dalvik.vm.execution-mode int:jit && "
        "setprop ro.hwui.use_skiaglthreaded true && "
        "setprop pm.dexopt.first-boot everything && "
        "setprop ro.hwui.disable_scissor_opt false && "
        "setprop pm.dexopt.bg-dexopt everything && "
        "setprop persist.sys.dalvik.multithread true && "
        "setprop dalvik.vm.dex2oat64.enabled true && "
        "setprop vendor.perf.framepacing.enable 1 && "
        "setprop dalvik.vm.dexopt.thermal-cutoff 0 && "
        "setprop dalvik.vm.dex2oat-filter everything && "
        "setprop persist.sys.debug.gr.swapinterval 1 && "
        "setprop ro.hwui.hardware.skiaglthreaded true && "
        "setprop persist.sys.dalvik.hyperthreading true && "
        "setprop dalvik.vm.dex2oat-minidebuginfo false && "
        "setprop dalvik.vm.image-dex2oat-filter everything && "
        "setprop ro.surface_flinger.set_idle_timer_ms 1000 && "
        "setprop ro.surface_flinger.set_touch_timer_ms 100 && "
        "setprop persist.sys.gpu.working_thread_priority true && "
        "setprop dalvik.vm.dexopt-flags m=y,v=everything,o=everything && "
        "setprop persist.sys.perf.topAppRenderThreadBoost.enable true && "
        "setprop renderthread.skiaglthreaded.reduceopstasksplitting true && ";

    system(cmd);
}

void reset_properties() {
    const char *cmd = 
        "resetprop -n rw.logger 0 && "
        "resetprop -n sys.use_fifo_ui 1 && "
        "resetprop -n ro.min_pointer_dur 8 && "
        "resetprop -n ro.iorapd.enable false && "
        "resetprop -n hwui.disable_vsync true && "
        "resetprop -n ro.min.fling_velocity 8000 && "
        "resetprop -n persist.sys.lgospd.enable 0 && "
        "resetprop -n persist.sys.scrollingcache 2 && "
        "resetprop -n persist.sys.pcsync.enable 0 && "
        "resetprop -n persist.sys.perf.debug false && "
        "resetprop -n ro.max.fling_velocity 20000 && "
        "resetprop -n hwui.render_dirty_regions false && "
        "resetprop -n persist.sys.composition.type gpu && "
        "resetprop -n windowsmgr.max_event_per_sec 200 && "
        "resetprop -n ro.surface_flinger.protected_contents true && "
        "resetprop -n ro.surface_flinger.has_wide_color_display true && "
        "resetprop -n ro.surface_flinger.use_color_management true && "
        "resetprop -n vendor.debug.renderengine.backend skiaglthreaded && "
        "resetprop -n ro.surface_flinger.max_virtual_display_dimension 4096 && "
        "resetprop -n ro.surface_flinger.running_without_sync_framework true && "
        "resetprop -n ro.surface_flinger.force_hwc_copy_for_virtual_displays true && "
        "resetprop -n persist.device_config.runtime_native_boot.iorap_perfetto_enable false && "
        "resetprop -n persist.device_config.runtime_native_boot.iorap_readahead_enable false && "
        "resetprop -n persist.device_config.surface_flinger_native_boot.SkiaTracingFeature_use_skia_tracing true && ";

    system(cmd);
}

void cleanup() {
    remove(MODPATH "/post-fs-data.sh");
}

int main() {
    create_dirs();
    write_config();
    write_sys_values();
    set_properties();
    reset_properties();
    cleanup();
    return 0;
}
