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

random=$((RANDOM % 12))

if [ $random -eq 0 ]; then
    ui_print "- 8 Letters."
elif [ $random -eq 1 ]; then
    ui_print "- About You."
elif [ $random -eq 2 ]; then
    ui_print "- Apocalypse."
elif [ $random -eq 3 ]; then
    ui_print "- Here With Me."
elif [ $random -eq 4 ]; then
    ui_print "- I Love You So."
elif [ $random -eq 5 ]; then
    ui_print "- a thousand years."
elif [ $random -eq 6 ]; then
    ui_print "- we can't be friends."
elif [ $random -eq 7 ]; then
    ui_print "- Anything You Want."
elif [ $random -eq 8 ]; then
    ui_print "- Somebody's Pleasure."
elif [ $random -eq 9 ]; then
    ui_print "- Versace on the Floor."
elif [ $random -eq 10 ]; then
    ui_print "- The Winner Takes It All."
else
    ui_print "- If Ever You're in My Arms Again."
fi
