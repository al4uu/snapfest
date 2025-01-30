#!/system/bin/sh
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

ui_print " "
ui_print "* SnapFest Tweaks"
ui_print "* Version 1.2 (GIT@a284a56)"
ui_print "* @al4uu & @allprjkt"
ui_print " "
sleep 1

ui_print "- Device : $(getprop ro.product.manufacturer) ($(getprop ro.product.device))"
sleep 1
ui_print "- SELinux Status : $(getenforce)"
sleep 1
ui_print "- Kernel Version : $(uname -r)"
ui_print " "

sleep 1

if [ -d /data/adb/modules/bumbu_racik ]; then
    ui_print "- Bumbu Racik module detected. Removing"
    rm -rf /data/adb/modules/bumbu_racik
fi

sleep 2

ui_print "- Extracting module files"
unzip "$ZIPFILE" "system/*" -x "*.sha256" -d "$MODPATH/" >/dev/null 2>&1
unzip "$ZIPFILE" "action.sh" "snapfest.png" -d "$MODPATH/" >/dev/null 2>&1

sleep 2

ui_print "- SnapFest preferences setup"
cp -f "$MODPATH"/snapfest.png /data/local/tmp/ >/dev/null 2>&1
cp -af "$TMPDIR"/action.sh "$MODPATH"/action.sh >/dev/null 2>&1
set_perm "$MODPATH/action.sh" 0 0 0755 0755
set_perm "/data/local/tmp/snapfest.png" 0 0 0644 0644

sleep 1

random=$((RANDOM % 9))

if [ $random -eq 0 ]; then
    ui_print "- Snap Into Action !"
elif [ $random -eq 1 ]; then
    ui_print "- Leave Lag Behind !"
elif [ $random -eq 2 ]; then
    ui_print "- Snap the Lag Away !"
elif [ $random -eq 3 ]; then
    ui_print "- Optimize. Game. Win !"
elif [ $random -eq 4 ]; then
    ui_print "- Stability Meets Power !"
elif [ $random -eq 5 ]; then
    ui_print "- Rise with Snapdragon !"
elif [ $random -eq 6 ]; then
    ui_print "- Perform Like a Phoenix !"
elif [ $random -eq 7 ]; then
    ui_print "- Dominate with Precision !"
elif [ $random -eq 8 ]; then
    ui_print "- Frame Stability? LOCKED !"
else
    ui_print "- Unleash Snapdragon Efficiency !"
fi

ui_print " "