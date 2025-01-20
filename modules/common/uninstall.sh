#!/system/bin/sh

[ -f /data/local/tmp/snapfest.png ] && rm -f /data/local/tmp/snapfest.png

find /data/dalvik-cache/ -type f -name "*.vdex" -o -name "*.odex" -o -name "*.art" -exec rm -f {} + > /dev/null 2>&1

find /data/user_de -type f -name '*shaders_cache*' -exec rm -f {} + > /dev/null 2>&1

find /data -type f -name '*shader*' -exec rm -f {} + > /dev/null 2>&1
