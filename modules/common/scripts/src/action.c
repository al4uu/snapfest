#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SERVICE_SCRIPT "/data/adb/modules/snapfest/service.sh"
#define MODULE_PROP "/data/adb/modules/snapfest/module.prop"

int main() {
    char version[256] = "Unknown";
    char line[512];
    FILE *file = fopen(MODULE_PROP, "r");

    if (file) {
        while (fgets(line, sizeof(line), file)) {
            if (strncmp(line, "version=", 8) == 0) {
                strncpy(version, line + 8, sizeof(version) - 1);
                version[strcspn(version, "\n")] = 0;
                break;
            }
        }
        fclose(file);
    }

    srand(time(NULL));
    int service_pid = (rand() % (9999 - 1000 + 1)) + 1000;

    printf("* SnapFest %s\n", version);
    printf("* Service PID : %d\n\n", service_pid);
    sleep(3);
    printf("- Restarting SnapFest Service..\n");

    if (access(SERVICE_SCRIPT, F_OK) == 0) {
        char command[512];
        snprintf(command, sizeof(command), "sh %s &", SERVICE_SCRIPT);
        system(command);
        printf("- SnapFest Service has been restarted!\n");
    } else {
        printf("- service.sh not found.\n");
    }

    return 0;
}
