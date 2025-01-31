#!/system/bin/sh

SERVICE_SCRIPT="/data/adb/modules/snapfest/service.sh"
MODULE_PROP="/data/adb/modules/snapfest/module.prop"

version=$(grep "^version=" "$MODULE_PROP" | cut -d'=' -f2)

if [ -z "$version" ]; then
  version="Unknown"
fi

service_pid=$(shuf -i 1000-9999 -n 1)

echo "* SnapFest $version"
echo "* Service PID : ($service_pid)"
echo ""
sleep 3
echo "- Restarting SnapFest Service.."

if [ -f "$SERVICE_SCRIPT" ]; then
  sh "$SERVICE_SCRIPT" &
  echo "- SnapFest Service has been restarted !"
  echo "- Service script executed with PID : ($!)"
else
  echo "- service.sh not found."
fi

exit 0
