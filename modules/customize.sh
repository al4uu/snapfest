SKIPUNZIP=1

print_info() {
  ui_print "- Device : $(getprop ro.product.manufacturer) ($(getprop ro.product.device))"
  ui_print "- SELinux : $(getenforce)"
  ui_print "- Linux Kernel : $(uname -r)"
}

print_info

detect_installer() {
  if [ -d "/data/adb/ksu" ]; then
    ROOT_METHOD="KernelSU"
    if command -v su &>/dev/null; then
        ROOT_VERSION=$(su --version 2>/dev/null | cut -d ':' -f 1)
    fi
    ui_print "- Installing From : $ROOT_METHOD ($ROOT_VERSION)"
  
  elif [ -d "/data/adb/magisk" ]; then
    ROOT_METHOD="Magisk"
    if command -v magisk &>/dev/null; then
        ROOT_VERSION=$(magisk -V)
    fi
    ui_print "- Installing From : $ROOT_METHOD ($ROOT_VERSION)"
  
  elif [ -d "/data/adb/ap" ]; then
    ROOT_METHOD="APatch"
    if [ -f "/data/adb/ap/version" ]; then
        ROOT_VERSION=$(cat /data/adb/ap/version)
    fi
    ui_print "- Installing From : $ROOT_METHOD ($ROOT_VERSION)"
  
  else
    ui_print "- Unknown installer"
  fi
}

detect_installer

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
  for path in "/data/adb/modules_update/bumbu_racik" "/data/adb/modules/bumbu_racik"; do
    if [ -d "$path" ]; then
      ui_print "- Bumbu Racik module detected. Removing..."
      if rm -rf "$path"; then
        ui_print "- Successfully removed Bumbu Racik"
      else
        abort "! Failed to remove Bumbu Racik. Installation aborted."
      fi
    fi
  done
}

remove_bumbu_racik

extracting_module() {
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'action.sh' -d "$MODPATH" > /dev/null 2>&1
  unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" > /dev/null 2>&1
  unzip -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" > /dev/null 2>&1
  unzip -o "$ZIPFILE" 'post-fs-data.sh' -d "$MODPATH" > /dev/null 2>&1
  unzip -o "$ZIPFILE" 'module.prop' -d "$MODPATH" > /dev/null 2>&1
  unzip -o "$ZIPFILE" 'snapfest.png' -d "/data/local/tmp" > /dev/null 2>&1
}

extracting_module

set_permissions() {
  ui_print "- Setting permissions"
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  for file in action.sh service.sh post-fs-data.sh uninstall.sh; do
    set_perm "$MODPATH/$file" 0 0 0755
  done
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
