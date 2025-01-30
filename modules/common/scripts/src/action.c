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
    const char *set_properties =
        "sys.use_fifo_ui=1\n"
        "logcat.live=disable\n"
        "persist.sys.ui.hw=1\n"
        "ro.kernel.checkjni=0\n"
        "profiler.launch=false\n"
        "ro.min_pointer_dur=8\n"
        "com.qc.hardware=true\n"
        "debugtool.anrhistory=0\n"
        "camera.debug.logfile=0\n"
        "sys.lmk.reportkills=false\n"
        "dalvik.vm.debug.alloc=0\n"
        "dalvik.vm.checkjni=false\n"
        "ro.min.fling_velocity=8000\n"
        "ro.hwui.render_ahead=true\n"
        "pm.dexopt.boot=everything\n"
        "persist.sys.lgospd.enable=0\n"
        "dev.pm.dyn_samplingrate=1\n"
        "profiler.debugmonitor=false\n"
        "persist.sys.scrollingcache=2\n"
        "persist.sys.pcsync.enable=0\n"
        "ro.kernel.android.checkjni=0\n"
        "ro.max.fling_velocity=20000\n"
        "dalvik.vm.jmiopts=forcecopy\n"
        "profiler.force_disable_ulog=1\n"
        "persist.android.strictmode=0\n"
        "pm.dexopt.install=everything\n"
        "ro.ui.pipeline=skiaglthreaded\n"
        "persist.sys.egl.swapinterval=1\n"
        "ro.vendor.perf.scroll_opt=true\n"
        "dalvik.vm.minidebuginfo=false\n"
        "persist.sys.use_16bpp_alpha=1\n"
        "ro.zygote.disable_gl_preload=1\n"
        "persist.sys.purgeable_assets=1\n"
        "dalvik.vm.deadlock-predict=off\n"
        "persist.sys.lmk.reportkills=false\n"
        "profiler.force_disable_err_rpt=1\n"
        "dalvik.vm.check-dex-sum=false\n"
        "persist.service.lgospd.enable=0\n"
        "dalvik.vm.verify-bytecode=false\n"
        "persist.service.pcsync.enable=0\n"
        "dalvik.vm.execution-mode=int:jit\n"
        "ro.hwui.use_skiaglthreaded=true\n"
        "pm.dexopt.first-boot=everything\n"
        "ro.hwui.disable_scissor_opt=false\n"
        "pm.dexopt.bg-dexopt=everything\n"
        "persist.sys.dalvik.multithread=true\n"
        "dalvik.vm.dex2oat64.enabled=true\n"
        "vendor.perf.framepacing.enable=1\n"
        "dalvik.vm.dexopt.thermal-cutoff=0\n"
        "dalvik.vm.dex2oat-filter=everything\n"
        "persist.sys.debug.gr.swapinterval=1\n"
        "profiler.hung.dumpdobugreport=false\n"
        "ro.hwui.hardware.skiaglthreaded=true\n"
        "persist.sys.dalvik.hyperthreading=true\n"
        "windowsmgr.max_event_per_sec=200\n"
        "ro.config.cpu_thermal_throttling=false\n"
        "dalvik.vm.dex2oat-minidebuginfo=false\n"
        "ro.vendor.qti.sys.fw.bservice_enable=true\n"
        "dalvik.vm.image-dex2oat-filter=everything\n"
        "ro.surface_flinger.set_idle_timer_ms=1000\n"
        "ro.surface_flinger.set_touch_timer_ms=100\n"
        "ro.surface_flinger.protected_contents=true\n"
        "persist.sys.gpu.working_thread_priority=true\n"
        "renderthread.skia.reduceopstasksplitting=true\n"
        "dalvik.vm.dexopt-flags=m=y,v=everything,o=everything\n"
        "persist.sys.perf.topAppRenderThreadBoost.enable=true\n"
        "renderthread.skiaglthreaded.reduceopstasksplitting=true\n";

    const char *reset_properties =
        "rw.logger=0\n"
        "log.tag.all=0\n"
        "log.shaders=0\n"
        "config.stats=0\n"
        "logd.statistics=0\n"
        "ro.logd.size=OFF\n"
        "ro.debuggable=0\n"
        "sys.init_log_level=0\n"
        "ro.logd.kernel=false\n"
        "persist.logd.limit=OFF\n"
        "log.tag.stats_log=OFF\n"
        "ro.logd.size.stats=64K\n"
        "ro.iorapd.enable=false\n"
        "persist.logd.size.radio=1M\n"
        "persist.logd.size.crash=1M\n"
        "persist.logd.size.radio=OFF\n"
        "ro.logdumpd.enabled=false\n"
        "media.stagefright.log-uri=0\n"
        "persist.logd.size.crash=OFF\n"
        "persist.logd.size.system=1M\n"
        "persist.sys.perf.debug=false\n"
        "persist.logd.size.system=OFF\n"
        "logd.logpersistd.enable=false\n"
        "tombstoned.max_anr_count=0\n"
        "db.log.slow_query_threshold=0\n"
        "persist.data.qmi.adb_logmask=0\n"
        "persist.ims.disableIMSLogs=true\n"
        "persist.service.logd.enable=false\n"
        "persist.ims.disableADBLogs=true\n"
        "db.log.slow_query_threshold=999\n"
        "vendor.debug.rs.qcom.verbose=0\n"
        "persist.vendor.radio.adb_log_on=0\n"
        "persist.ims.disableQXDMLogs=true\n"
        "persist.ims.disableDebugLogs=true\n"
        "ro.vendor.connsys.dedicated.log=0\n"
        "vendor.bluetooth.startbtlogger=false\n"
        "vendor.debug.rs.qcom.dump_setup=0\n"
        "vendor.debug.rs.qcom.dump_bitcode=0\n"
        "ro.surface_flinger.protected_contents=true\n"
        "persist.bluetooth.btsnooplogmode=disabled\n"
        "persist.vendor.radio.snapshot_enabled=false\n"
        "persist.vendor.verbose_logging_enabled=false\n"
        "ro.surface_flinger.has_wide_color_display=true\n"
        "ro.surface_flinger.use_color_management=true\n"
        "persist.vendor.sys.modem.logging.enable=false\n"
        "persist.sys.turbosched.enable.coreApp.optimizer=true\n"
        "ro.surface_flinger.max_virtual_display_dimension=4096\n"
        "ro.surface_flinger.running_without_sync_framework=true\n"
        "ro.surface_flinger.force_hwc_copy_for_virtual_displays=true\n"
        "persist.device_config.runtime_native_boot.iorap_perfetto_enable=false\n"
        "persist.device_config.runtime_native_boot.iorap_readahead_enable=false\n"
        "persist.device_config.surface_flinger_native_boot.SkiaTracingFeature_use_skia_tracing=true\n";

    for (const char *prop = set_properties; *prop; prop++) {
        char *prop_name = strtok((char *)prop, "=");
        char *prop_value = strtok(NULL, "\n");
        if (prop_name && prop_value) {
            setprop(prop_name, prop_value);
        }
    }

    for (const char *prop = reset_properties; *prop; prop++) {
        char *prop_name = strtok((char *)prop, "=");
        char *prop_value = strtok(NULL, "\n");
        if (prop_name && prop_value) {
            resetprop("-n", prop_name, prop_value);
        }
    }
}

void cleanup() {
    remove(MODPATH "/post-fs-data.sh");
}

int main() {
    create_dirs();
    write_config();
    write_sys_values();
    set_properties();
    cleanup();
    return 0;
}
