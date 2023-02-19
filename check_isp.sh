#!/bin/bash
#
# Useful for:
#   https://docs.librenms.org/Extensions/Services/
#
# Returns:
#   0 = Ok
#   1 = Warning
#   2 = Critical
#
# Examples:
# sudo ./check_isp.sh -H 8.8.8.8 -g 192.168.2.1 -h 4

usage() { echo "Usage: $0 -H <target-host> -g <ip> -h <hops>" 1>&2; exit 1; }

if [ "$#" -ne 6 ]; then
  usage
fi

while getopts "H:g:h:" flag
do
    case "${flag}" in
        H) tg=${OPTARG};; # mtr target host IPv4 or name
        g) gw=${OPTARG};; # expected gw IPv4 at hop position
        h) hp=${OPTARG};; # hop position to check from mtr output
    esac
done

shift $((OPTIND-1))

gw_mtr=$(mtr -n -c 3 -l -r -C $tg | tee -a /tmp/check_isp.log | sed 1,1d | head -n $hp | tail -n 1 | cut -d',' -f 6)
if [ "$gw" == "$gw_mtr" ]
then
	echo "OK - Hop #$hp to '$tg' is '$gw_mtr'"
	exit 0
else
	echo "ERROR - Hop #$hp to '$tg' is '$gw_mtr' instead of '$gw'"
	exit 2
fi

