#!/system/bin/sh

rm -rf /data/local/tmp/snapfest.png

find /data/dalvik-cache/ -type f \( -name "*.vdex" -o -name "*.odex" -o -name "*.art" \) -delete

find /data/user_de -name '*shaders_cache*' -type f | grep code_cache | while IFS= read -r i; do
    rm -rf "$i"
done

find /data -type f -name '*shader*' | while IFS= read -r i; do
 rm -f "$i"
done
