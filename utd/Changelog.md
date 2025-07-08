NEW UPDATE IS COMING 🎉

# Changelog
version: v5.0

- removed some system files from the module that were causing bootloops on a few devices

- (hopefully) fully disabled the thermal HAL

- cleaned up and reworked some script logic for better flow

- fixed those annoying install errors on ksunext

# Changelog
version: v4.0

- Kills all thermal services and background daemons
- Disables all known thermal HAL binaries across partitions
- Locks thermal zones and GPU throttling paths
- Stops thermal-related init services and props
- Forces max CPU frequency and disables CPU/GPU power policies
- Overrides tzcpu/tzpmic limits and disables shutdown triggers
- Protects against vendor thermal protections and throttling
