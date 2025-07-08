while [ -z "$(getprop sys.boot_completed)" ]; do
	sleep 1
done

lock_val() {
	val="$1"
	shift
	for p in "$@"; do
		[ ! -f "$p" ] && continue
		chown root:root "$p"
		chmod 644 "$p"
		echo "$val" > "$p"
		chmod 444 "$p"
	done
}

thermal_service() {
    find /system/etc/init /vendor/etc/init /odm/etc/init -type f | xargs grep -h "^service" | awk '{print $2}' | grep thermal
}

thermal_kill() {
    for service in $(thermal_service); do
        stop "$service"
    done

    for therm in \
        android.hardware.thermal-service.mediatek \
        android.hardware.thermal@2.0-service.mtk \
        android.hardware.thermal@2.0-service \
        vendor.mediatek.hardware.thermal@1.0-service \
        vendor.mediatek.hardware.mtkpower@1.0-service \
        hardware.thermal@2.0-service \
        thermalloadalgod \
        thermal_manager \
        thermal-engine \
        thermal \
        thermal-hal \
        thermald \
        mi_thermald \
        vendor.thermal-engine \
        vendor.thermal_manager \
        vendor.thermal-manager \
        vendor.thermal-hal-2-0 \
        vendor.thermal-hal-2-0.mtk \
        vendor.thermal-symlinks \
        thermal_mnt_hal_service \
        thermalservice \
        sec-thermal-1-0 \
        vendor.thermal-hal-1-0 \
        android.thermal-hal \
        vendor-thermal-1-0
    do
        killall -9 "$therm"
		for pid in $(pidof "$therm"); do
			kill -9 "$pid"
		done
	done

    for thermal_proc in $(pgrep -f thermal); do
        kill -9 "$thermal_proc"
    done
}

thermal_kill

power_temp() {
	for power_supply in /sys/class/power_supply/*; do
		lock_val "150" "$power_supply/temp_cool"
		lock_val "480" "$power_supply/temp_hot"
		lock_val "460" "$power_supply/temp_warm"
	done
}

power_temp

gpu_limits() {
	if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
		lock_val "ignore_batt_oc 1" /proc/gpufreq/gpufreq_power_limited
		lock_val "ignore_batt_percent 1" /proc/gpufreq/gpufreq_power_limited
		lock_val "ignore_low_batt 1" /proc/gpufreq/gpufreq_power_limited
		lock_val "ignore_thermal_protect 1" /proc/gpufreq/gpufreq_power_limited
		lock_val "ignore_pbm_limited 1" /proc/gpufreq/gpufreq_power_limited
	fi
    
    for gpu_path in \
        /sys/class/kgsl/kgsl-3d0/throttling \
        /sys/class/kgsl/kgsl-3d0/devfreq/thermal_governor \
        /proc/gpufreqv2/gpufreq_opp_limit
    do
        if [ -f "$gpu_path" ]; then
            echo "0" > "$gpu_path"
        fi
    done
}

gpu_limits

cpu_performance() {
    if [ -f /sys/devices/virtual/thermal/thermal_message/cpu_limits ]; then
        for cpu in $(ls -d /sys/devices/system/cpu/cpu[0-9]* | sed 's/.*cpu//'); do
            maxfreq_path="/sys/devices/system/cpu/cpu$cpu/cpufreq/cpuinfo_max_freq"
            if [ -f "$maxfreq_path" ]; then
                maxfreq=$(cat "$maxfreq_path")
                [ -n "$maxfreq" ] && [ "$maxfreq" -gt 0 ] && echo "cpu$cpu $maxfreq" > /sys/devices/virtual/thermal/thermal_message/cpu_limits
            fi
        done
    fi

    if [ -d /proc/ppm ]; then
	    for idx in $(cat /proc/ppm/policy_status | grep -E 'PWR_THRO|THERMAL' | awk -F'[][]' '{print $2}'); do	
	        lock_val "$idx 0" /proc/ppm/policy_status
	        lock_val "0" /proc/ppm/enabled
	        lock_val "0" > /sys/kernel/eara_thermal/enable
	    done
    fi
}

cpu_performance

thermal_protections() {
	if [ -f "/proc/mtk_batoc_throttling/battery_oc_protect_stop" ]; then
		lock_val "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop
	fi

	lock_val "0" /sys/kernel/msm_thermal/enabled
	lock_val "N" /sys/module/msm_thermal/parameters/enabled
	lock_val "0" /sys/module/msm_thermal/core_control/enabled
	lock_val "0" /sys/module/msm_thermal/vdd_restriction/enabled
}

thermal_protections

apply_tzcpu_override() {
    if [ -f /proc/driver/thermal/tzcpu ]; then
       	t_limit="125"
	    no_cooler="0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler"
	    lock_val "1 ${t_limit}000 0 mtktscpu-sysrst $no_cooler 200" /proc/driver/thermal/tzcpu
	    lock_val "1 ${t_limit}000 0 mtktspmic-sysrst $no_cooler 1000" /proc/driver/thermal/tzpmic
	    lock_val "1 ${t_limit}000 0 mtktsbattery-sysrst $no_cooler 1000" /proc/driver/thermal/tzbattery
	    lock_val "1 ${t_limit}000 0 mtk-cl-kshutdown00 $no_cooler 2000" /proc/driver/thermal/tzpa
	    lock_val "1 ${t_limit}000 0 mtktscharger-sysrst $no_cooler 2000" /proc/driver/thermal/tzcharger
	    lock_val "1 ${t_limit}000 0 mtktswmt-sysrst $no_cooler 1000" /proc/driver/thermal/tzwmt
	    lock_val "1 ${t_limit}000 0 mtktsAP-sysrst $no_cooler 1000" /proc/driver/thermal/tzbts
	    lock_val "1 ${t_limit}000 0 mtk-cl-kshutdown01 $no_cooler 1000" /proc/driver/thermal/tzbtsnrpa
	    lock_val "1 ${t_limit}000 0 mtk-cl-kshutdown02 $no_cooler 1000" /proc/driver/thermal/tzbtspa
    fi
}

apply_tzcpu_override

thermal_zone() {
    for zone in $(find /sys/devices/virtual/thermal -type f); do
        chmod 000 "$zone"
    done
}

thermal_zone

thermal_hal() {
	mount -o remount,rw /vendor 2>/dev/null
	mount -o remount,rw /system 2>/dev/null
	mount -o remount,rw /system_ext 2>/dev/null
	mount -o remount,rw /odm 2>/dev/null
	mount -o remount,rw /my_product 2>/dev/null

	SEARCH_PATHS="/vendor/bin /vendor/bin/hw /system/bin /system_ext/bin /odm/bin /my_product/bin"
	for dir in $SEARCH_PATHS; do
		for file in "$dir"/*thermal*@*service* "$dir"/*thermal*service* 2>/dev/null; do
			[ -f "$file" ] || continue
			echo "[+] Disabling HAL: $file"
			mount -o bind /dev/null "$file"
			chmod 000 "$file"
		done
	done
}

thermal_hal

cmd thermalservice override-status 0
chmod 000 /sys/devices/*.mali/tmu
chmod 000 /sys/devices/*.mali/throttling*
chmod 000 /sys/devices/*.mali/tripping
chmod 000 /proc/mtktz/*
chmod 000 /proc/thermal
chmod 000 /dev/thermal_manager
chmod 000 /dev/thermal

thermal_props() {
    for prop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc.); do
        setprop "$prop" stopped
    done

    for prop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc_); do
        setprop "$prop" destroyed
    done
}

thermal_props

module_description() {
	MODULE_PROP="/data/adb/modules/TDestroyer/module.prop"
	thermal_count=$(pgrep -iE 'thermal|temp|throttl' | wc -l)
	if [ "$thermal_count" = "0" ]; then
		sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ ⚔️ THERMAL HAS BEEN DESTROYED ] /g" "$MODULE_PROP"
	else
		sed -Ei "s/^description=.*/description=[ ⚠️ WARNING: $thermal_count THERMAL PROCESSES STILL RUNNING ]/g" "$MODULE_PROP"
	fi
}

module_description