#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>

#define PATH_MAX 4096

void write_to_file(const char *path, const char *value) {
    FILE *file = fopen(path, "w");
    if (file != NULL) {
        fprintf(file, "%s", value);
        fclose(file);
    } else {
        perror("Failed to open file");
    }
}

int file_exists(const char *path) {
    return access(path, F_OK) != -1;
}

void execute_command(const char *command) {
    system(command);
}

void list_thermal_services() {
    const char *init_paths[] = {"/system/etc/init", "/vendor/etc/init", "/odm/etc/init"};
    for (int i = 0; i < 3; i++) {
        DIR *dir = opendir(init_paths[i]);
        if (dir == NULL) {
            continue;
        }

        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_type == DT_REG) {
                char rc_path[PATH_MAX];
                snprintf(rc_path, sizeof(rc_path), "%s/%s", init_paths[i], entry->d_name);
                FILE *file = fopen(rc_path, "r");
                if (file) {
                    char line[256];
                    while (fgets(line, sizeof(line), file)) {
                        if (strstr(line, "service")) {
                            char *svc = strtok(line, " ");
                            if (svc) {
                                printf("Found thermal service: %s\n", svc);
                                char stop_command[256];
                                snprintf(stop_command, sizeof(stop_command), "stop %s", svc);
                                system(stop_command);
                                char start_command[256];
                                snprintf(start_command, sizeof(start_command), "start %s", svc);
                                system(start_command);
                            }
                        }
                    }
                    fclose(file);
                }
            }
        }
        closedir(dir);
    }
}

void stop_thermal_processes() {
    FILE *fp = popen("pgrep thermal", "r");
    if (fp == NULL) return;

    char pid[10];
    while (fgets(pid, sizeof(pid), fp)) {
        pid[strcspn(pid, "\n")] = 0;
        kill(atoi(pid), SIGSTOP);
    }
    fclose(fp);
}

void disable_thermal_zones() {
    DIR *dir = opendir("/sys/class/thermal");
    if (dir == NULL) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, "thermal_zone")) {
            char zone_path[PATH_MAX];
            snprintf(zone_path, sizeof(zone_path), "/sys/class/thermal/%s/mode", entry->d_name);
            if (file_exists(zone_path)) {
                write_to_file(zone_path, "disabled");
            }
        }
    }
    closedir(dir);
}

void reset_thermal_properties() {
    FILE *fp = popen("resetprop | grep 'thermal.*running' | awk -F '[][]' '{print $2}'", "r");
    if (fp == NULL) return;

    char prop[256];
    while (fgets(prop, sizeof(prop), fp)) {
        prop[strcspn(prop, "\n")] = 0;
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "resetprop %s freezed", prop);
        system(cmd);
    }
    fclose(fp);
}

void disable_thermal_throttling() {
    FILE *fp = popen("find /sys/ -type f -name \"*throttling*\"", "r");
    if (fp == NULL) return;

    char throttling_file[PATH_MAX];
    while (fgets(throttling_file, sizeof(throttling_file), fp)) {
        throttling_file[strcspn(throttling_file, "\n")] = 0;
        if (file_exists(throttling_file)) {
            write_to_file(throttling_file, "0");
        }
    }
    fclose(fp);
}

void disable_msm_thermal() {
    FILE *fp = popen("find /sys/ -name enabled | grep 'msm_thermal'", "r");
    if (fp == NULL) return;

    char msm_thermal_status[PATH_MAX];
    while (fgets(msm_thermal_status, sizeof(msm_thermal_status), fp)) {
        msm_thermal_status[strcspn(msm_thermal_status, "\n")] = 0;
        FILE *file = fopen(msm_thermal_status, "r");
        if (file) {
            char value[2];
            fgets(value, sizeof(value), file);
            fclose(file);

            if (strcmp(value, "Y") == 0) {
                write_to_file(msm_thermal_status, "N");
            } else if (strcmp(value, "1") == 0) {
                write_to_file(msm_thermal_status, "0");
            }
        }
    }
    fclose(fp);
}

void disable_log_files() {
    const char *log_patterns[] = {
        "debug_mask", "log_level*", "debug_level*", "*debug_mode", "enable_ramdumps", 
        "edac_mc_log*", "enable_event_log", "*log_level*", "*log_ue*", "*log_ce*", 
        "log_ecn_error", "snapshot_crashdumper", "seclog*", "compat-log", "*log_enabled", 
        "tracing_on", "mballoc_debug"
    };

    for (int i = 0; i < sizeof(log_patterns) / sizeof(log_patterns[0]); i++) {
        FILE *fp = popen("find /sys/ -type f -name \"*\" 2>/dev/null", "r");
        if (fp == NULL) continue;

        char log_file[PATH_MAX];
        while (fgets(log_file, sizeof(log_file), fp)) {
            log_file[strcspn(log_file, "\n")] = 0;
            if (file_exists(log_file) && strstr(log_file, log_patterns[i])) {
                write_to_file(log_file, "0");
            }
        }
        fclose(fp);
    }
}

void stop_services() {
    const char *services[] = {
        "mi_thermald", "traced", "tombstoned", "tcpdump", "cnss_diag", "statsd", "logcat",
        "logcatd", "logd", "idd-logreader", "idd-logreadermain", "stats", "dumpstate",
        "vendor.tcpdump", "vendor_tcpdump", "vendor.cnss_diag"
    };

    for (int i = 0; i < sizeof(services) / sizeof(services[0]); i++) {
        if (system("pgrep -x ") == 0) {
            char stop_command[256];
            snprintf(stop_command, sizeof(stop_command), "su -c \"stop %s\" >/dev/null 2>&1", services[i]);
            system(stop_command);
        }
    }
}

void kill_processes() {
    const char *processes[] = {
        "logd", "logcat", "logcatd", "logd.rc", "traced", "tombstoned"
    };

    for (int i = 0; i < sizeof(processes) / sizeof(processes[0]); i++) {
        if (system("pgrep -x ") == 0) {
            char kill_command[256];
            snprintf(kill_command, sizeof(kill_command), "killall -9 %s >/dev/null 2>&1", processes[i]);
            system(kill_command);
        }
    }
}

void remove_log_directories() {
    const char *paths[] = {
        "/data/anr", "/dev/log", "/data/tombstones", "/data/log_other_mode", "/data/system/dropbox",
        "/data/system/usagestats", "/data/log", "/sys/kernel/debug", "/storage/emulated/0/*.log",
        "/storage/emulated/0/Android/*.log"
    };

    for (int i = 0; i < sizeof(paths) / sizeof(paths[0]); i++) {
        if (access(paths[i], F_OK) == 0) {
            char rm_command[256];
            snprintf(rm_command, sizeof(rm_command), "rm -rf %s >/dev/null 2>&1", paths[i]);
            system(rm_command);
        }
    }
}

int main() {
    list_thermal_services();
    stop_thermal_processes();
    disable_thermal_zones();
    reset_thermal_properties();
    disable_thermal_throttling();
    disable_msm_thermal();
    disable_log_files();
    stop_services();
    kill_processes();
    remove_log_directories();

    return 0;
}
