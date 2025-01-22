#!/system/bin/sh
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

ui_print " "
ui_print "* SnapFest Tweaks"
ui_print "* Version 1.1 (GIT@74437d7)"
ui_print "* @al4uu & @allprjkt"
ui_print " "
sleep 1

ui_print "- Device : $(getprop ro.product.manufacturer), $(getprop ro.product.device)"
sleep 1
ui_print "- SELinux Status : $(getenforce)"
sleep 1
ui_print "- Kernel Version : $(uname -r)"
sleep 1
ui_print " "
ui_print "- Installing.."

sleep 5

if [ -d /data/adb/modules/bumbu_racik ]; then
    ui_print "- Bumbu Racik module detected. Removing.."
    rm -rf /data/adb/modules/bumbu_racik
fi

unzip "$ZIPFILE" "system/*" -x "*.sha256" -d "$MODPATH/" >/dev/null 2>&1
unzip "$ZIPFILE" "action.sh" "snapfest.png" -d "$MODPATH/" >/dev/null 2>&1

cp -af "$TMPDIR"/action.sh "$MODPATH"/action.sh >/dev/null 2>&1

cp -f "$MODPATH"/snapfest.png /data/local/tmp/ >/dev/null 2>&1
chmod 644 /data/local/tmp/snapfest.png >/dev/null 2>&1

sleep 5

random=$((RANDOM % 9))

case $random in
  0) ui_print "- Snap Into Action !" ;;
  1) ui_print "- Leave Lag Behind !" ;;
  2) ui_print "- Snap the Lag Away !" ;;
  3) ui_print "- Optimize. Game. Win !" ;;
  4) ui_print "- Stability Meets Power !" ;;
  5) ui_print "- Rise with Snapdragon !" ;;
  6) ui_print "- Perform Like a Phoenix !" ;;
  7) ui_print "- Dominate with Precision !" ;;
  8) ui_print "- Frame Stability? LOCKED !" ;;
  *) ui_print "- Unleash Snapdragon Efficiency !" ;;
esac

ui_print " "