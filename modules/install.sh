#!/system/bin/sh
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

DEVICE=$(getprop ro.product.manufacturer)
MODEL=$(getprop ro.product.device)
SELINUX=$(getenforce)
KERNEL=$(uname -r)

ui_print " "
ui_print "* SnapFest Tweaks"
ui_print "* Version 1.7 (GIT@ec8163b)"
ui_print "* @al4uu & @allprjkt"
ui_print " "

ui_print "- Device : $DEVICE ($MODEL)"
ui_print "- SELinux Status : $SELINUX"
ui_print "- Kernel Version : $KERNEL"
ui_print " "

detect_snapdragon() {
  if [ -d /sys/class/kgsl/kgsl-3d0/devfreq ] || [ -d /sys/devices/platform/kgsl-2d0.0/kgsl ]; then
    ui_print "- Detected Snapdragon SoC"
    return 0
  fi

  soc_info="$(grep -E "Hardware|Processor" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')"
  if echo "$soc_info" | grep -iqE "sm|qcom|qualcomm"; then
    ui_print "- Detected Snapdragon SoC"
    return 0
  fi

  prop_info="$(getprop ro.board.platform) $(getprop ro.hardware) $(getprop ro.hardware.chipname)"
  if echo "$prop_info" | grep -iqE "sm|qcom|qualcomm"; then
    ui_print "- Detected Snapdragon SoC"
    return 0
  fi

  return 1
}

if detect_snapdragon; then
  SOC=2
  ui_print "- Applying tweaks for Snapdragon"
else
  ui_print "! Unsupported SoC detected, only Snapdragon is supported"
  abort "! Installation aborted."
fi

remove_bumbu_racik() {
  path="$1"
  if [ -d "$path" ]; then
    ui_print "- Bumbu Racik module detected. Removing"
    rm -rf "$path" && ui_print "- Successfully removed Bumbu Racik" || {
      ui_print "! Failed to remove Bumbu Racik"
      abort "! Installation aborted."
    }
  fi
}

remove_bumbu_racik "/data/adb/modules_update/bumbu_racik"
remove_bumbu_racik "/data/adb/modules/bumbu_racik"

ui_print "- Extracting module files"
unzip -o "$ZIPFILE" "system/*" -d "$MODPATH/" >/dev/null 2>&1
unzip -o "$ZIPFILE" "action.sh" "snapfest.png" -d "$MODPATH/" >/dev/null 2>&1
cp -f "$MODPATH/snapfest.png" /data/local/tmp/ >/dev/null 2>&1
cp -af "$TMPDIR/action.sh" "$MODPATH/action.sh" >/dev/null 2>&1

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644 2>/dev/null
  set_perm $MODPATH/action.sh 0 0 0755 2>/dev/null
  set_perm $MODPATH/post-fs-data.sh 0 0 0755 2>/dev/null
  set_perm $MODPATH/service.sh 0 0 0755 2>/dev/null
  set_perm $MODPATH/uninstall.sh 0 0 0755 2>/dev/null
  set_perm "/data/local/tmp/snapfest.png" 0 0 0644 2>/dev/null
}

set_permissions

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
