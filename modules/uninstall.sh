#!/system/bin/sh

[ -f /data/local/tmp/snapfest.png ] && rm -f /data/local/tmp/snapfest.png

find /data/dalvik-cache/ -type f -name "*.vdex" -o -name "*.odex" -o -name "*.art" -exec rm -f {} + > /dev/null 2>&1

find /data/user_de -type f -name '*shaders_cache*' -exec rm -f {} + > /dev/null 2>&1

find /data -type f -name '*shader*' -exec rm -f {} + > /dev/null 2>&1

settings delete global auto_sync
settings delete global ble_scan_always_enabled
settings delete global wifi_scan_always_enabled
settings delete global hotword_detection_enabled
settings delete global activity_starts_logging_enabled
settings delete global network_recommendations_enabled
settings delete secure adaptive_sleep
settings delete secure screensaver_enabled
settings delete secure send_action_app_error
settings delete system motion_engine
settings delete system master_motion
settings delete system air_motion_engine
settings delete system air_motion_wake_up
settings delete system send_security_reports
settings delete system intelligent_sleep_mode
settings delete system nearby_scanning_enabled
settings delete system nearby_scanning_permission_allowed
