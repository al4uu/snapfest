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
        "setprop sys.use_fifo_ui 1 && "
        "setprop logcat.live disable && "
        "setprop persist.sys.ui.hw 1 && "
        "setprop ro.kernel.checkjni 0 && "
        "setprop profiler.launch false && "
        "setprop ro.min_pointer_dur 8 && "
        "setprop com.qc.hardware true && "
        "setprop debugtool.anrhistory 0 && "
        "setprop camera.debug.logfile 0 && "
        "setprop sys.lmk.reportkills false && "
        "setprop dalvik.vm.debug.alloc 0 && "
        "setprop dalvik.vm.checkjni false";

    system(cmd);
}

void reset_properties() {
    const char *cmd = 
        "resetprop -n rw.logger 0 && "
        "resetprop -n log.tag.all 0 && "
        "resetprop -n log.shaders 0 && "
        "resetprop -n config.stats 0 && "
        "resetprop -n logd.statistics 0 && "
        "resetprop -n ro.logd.size OFF && "
        "resetprop -n ro.debuggable 0 && "
        "resetprop -n sys.init_log_level 0";

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
