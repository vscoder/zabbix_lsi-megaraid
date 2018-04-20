#!/bin/sh

MEGACLI='/usr/bin/sudo /usr/local/sbin/MegaCli'
ZABBIX_SENDER='/usr/local/bin/zabbix_sender'
CONFIG='/usr/local/etc/zabbix32/zabbix_agentd.conf'

# LOG=/tmp/lsimegaraid_discovery_trapper.log
# echo $(date +"%Y-%m%d %H:%M:%S") $0 $@ >> $LOG

usage() {
	cat <<-_EOF
	WARNING: Correctly setup 'Hostname=' in config is REQUIRED!

	INFO: Get info about all arrays;
	 Examples:
	    Discovery is default action:
	        ./$(basename $0)                            - physdiscovery disks for all arrays.
	        ./$(basename $0) discovery                  - physdiscovery disks for all arrays.
	        ./$(basename $0) discovery virtdiscovery    - virtdiscovery disks for all arrays.
	    Data sending to zabbix-server:
	        ./$(basename $0) trapper    - send data to zabbix for all arrays.

	03.2015 - metajiji@gmail.com
	04.2018 - koloskov@flexline.ru
_EOF
}

LC_ALL=""
LANG="en_US.UTF-8"

discover_adp() {
	local TYPE=${1:-'physdiscovery'}  # Set Default value to physdiscovery.
	local ARRAY_NUM=${2:-'0'}  # Default value of array number is 0.
	if [ "$TYPE" == "virtdiscovery" ]; then
		$MEGACLI -LDInfo -LAll -a$ARRAY_NUM -NoLog | awk -v adp=$ARRAY_NUM '
			BEGIN {
				f = 0
			}
			/Virtual Drive:/ {
				if (f == 1 || adp > 0) out = out",\n"
				out = out "\t\t{\n"
				out = out "\t\t\t\"{#ADPNUM}\": \"Adp" adp "\",\n"
				out = out "\t\t\t\"{#VIRTNUM}\": \"VirtualDrive"$3"\"\n"
				out = out "\t\t}"
				f = 1
			}
			END {
				if (f == 0) {
					print "{}"
				} else {
					print out
				}
			}'
	elif [ "$TYPE" == 'physdiscovery' ]; then
		$MEGACLI -PDlist -a$ARRAY_NUM -NoLog | awk -F ': ' -v adp=$ARRAY_NUM '
			BEGIN {
				f = 0
			}
			/Slot Number:/ {
				if (f == 1 || adp > 0) out = out ",\n"
				out = out "\t\t{\n"
				out = out "\t\t\t\"{#ADPNUM}\": \"Adp" adp "\",\n"
				out = out "\t\t\t\"{#PHYSNUM}\":\"DriveSlot"$2"\"\n"
				out = out "\t\t}"
				f = 1
			}
			END {
				if (f == 0) {
					print "{}"
				} else {
					print out
				}
			}'
	else
		>&2 echo 'ERROR  : Discovery TYPE "'$TYPE'" is not correct!'
		echo '{}'  # Return empty json, if TYPE is not correct.
	fi
}

discovery() {
	local TYPE=${1:-'physdiscovery'}  # Set Default value to physdiscovery.
	local ADP_COUNT=$($MEGACLI -AdpAllInfo -aALL -NoLog | grep "^Adapter" | wc -l | tr -d '[:space:]')
	local MAX_ADP=$(($ADP_COUNT-1))
	if [ $ADP_COUNT -eq 0 ]; then echo "No adapters found."; exit 1; fi
	printf "{\n\t\"data\":[\n"
	for ARRAY_NUM in $(seq 0 $MAX_ADP)
	do
		discover_adp $TYPE $ARRAY_NUM
	done
	printf "\n\t]\n}\n"
}

trap_adp() {
	local ARRAY_NUM=${1:-'0'}  # Default value of array number is 0.
	($MEGACLI -PDlist -a$ARRAY_NUM -NoLog | awk -F':' -v adp=$ARRAY_NUM '
		function ltrim(s) {sub(/^[ \t]+/, "", s);return s}
		function rtrim(s) {sub(/[ \t]+$/, "", s);return s}
		function trim(s)  {return rtrim(ltrim(s))}
		/Slot Number/              {slotcounter += 1; slot[slotcounter] = trim($2)}
		/Firmware state/           {state[slotcounter]        = trim($2)}
		/S.M.A.R.T/                {smart[slotcounter]        = trim($2)}
		/Inquiry Data/             {inquiry[slotcounter]      = trim($2)}
		/Media Error Count/        {mediaerror[slotcounter]   = trim($2)}
		/Other Error Count/        {othererror[slotcounter]   = trim($2)}
		/Drive Temperature/        {temperature[slotcounter]  = trim($2)}
		/Predictive Failure Count/ {failurecount[slotcounter] = trim($2)}
		END {
			for (i = 1; i <= slotcounter; i += 1) {
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,state] %s\n",        slot[i], state[i])
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,smart] %s\n",        slot[i], smart[i])
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,inquiry] %s\n",      slot[i], inquiry[i])
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,mediaerror] %d\n",   slot[i], mediaerror[i])
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,othererror] %d\n",   slot[i], othererror[i])
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,temperature] %d\n",  slot[i], temperature[i])
				printf ("- lsimegaraid.data[Adp" adp ",DriveSlot%d,failurecount] %d\n", slot[i], failurecount[i])
			}
		}'; [ $? -gt 1 ] && echo 'ERROR  : MegaCli failed while getting phusical drives data!' && exit 1

	${MEGACLI} -LDInfo -LAll -a$ARRAY_NUM -NoLog | awk -F':' -v adp=$ARRAY_NUM '
		function ltrim(s) {sub(/^[ \t]+/, "", s);return s}
		function rtrim(s) {sub(/[ \t]+$/, "", s);return s}
		function trim(s)  {return rtrim(ltrim(s))}
		/Virtual Drive:/  {drivecounter += 1; slot[drivecounter] = trim($2)}
		/State/           {state[drivecounter]    = trim($2)}
		/Bad Blocks/      {badblock[drivecounter] = trim($2)}
		END {
			for (i = 1; i <= drivecounter; i += 1) {
				printf ("- lsimegaraid.data[Adp" adp ",VirtualDrive%d,state] %s\n", slot[i], state[i])
				printf ("- lsimegaraid.data[Adp" adp ",VirtualDrive%d,badblock] %s\n", slot[i], badblock[i]?badblock[i]:"Unknown")
			}
		}'; [ $? -gt 1 ] && echo 'ERROR  : MegaCli failed while getting virtual drives data!' && exit 1
	) | $ZABBIX_SENDER --config $CONFIG -vv --input-file - >/dev/null 2>&1
	[ $? -gt 1 ] && echo 0 && exit 1
}

trapper() {
	local ADP_COUNT=$($MEGACLI -AdpAllInfo -aALL -NoLog | grep "^Adapter" | wc -l | tr -d '[:space:]')
	local MAX_ADP=$(($ADP_COUNT-1))
	if [ $ADP_COUNT -eq 0 ]; then echo "No adapters found."; exit 1; fi
	for ARRAY_NUM in $(seq 0 $MAX_ADP)
	do
		trap_adp $ARRAY_NUM
	done
	echo 1 # 1 - Ok | 0 - Fail
}

case "$1" in
	help|usage|-h|--help) usage ;;
	discovery) discovery $2 ;;
	trapper) trapper ;;
	*) discovery ;;
esac
