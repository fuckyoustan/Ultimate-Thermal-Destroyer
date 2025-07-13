TIME TO UPDATE DUDE 🎉

# Changelog
version: v7.1

- fix some code
- more aggressive in specific thermal
- more wildly search for files with the keywords “therm” and “throtl” and "temp" on /system /vendor /sys /dev /proc

# Changelog
version: v7.0

- make the script thoroughly search for “thermal” and “throttling” related files in the path /system /vendor /sys etc.
- expected to run on all chipsets

# Changelog
version: v6.0

- fix typo in some code hehe
- more aggressive in searching for thermal files on /system and /vendor

# Changelog
version: v5.0

- removed some system files from the module that were causing bootloops on a few devices

- (hopefully) fully disabled the thermal HAL

- cleaned up and reworked some script logic for better flow

- fixed those annoying install errors on ksunext

# Important
- I recommend uninstalling the previous module first.

---

# Changelog
version: v4.0

- Kills all thermal services and background daemons
- Disables all known thermal HAL binaries across partitions
- Locks thermal zones and GPU throttling paths
- Stops thermal-related init services and props
- Forces max CPU frequency and disables CPU/GPU power policies
- Overrides tzcpu/tzpmic limits and disables shutdown triggers
- Protects against vendor thermal protections and throttling
