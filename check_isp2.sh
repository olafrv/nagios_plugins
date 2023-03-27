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
# sudo ./check_isp2.sh -n "Telekom"

usage() { echo "Usage: $0 -n <string>" 1>&2; exit 1; }

if [ "$#" -ne 4 ]; then
  usage
fi

while getopts "H:n:" flag
do
    case "${flag}" in
        n) text=${OPTARG};; # ISP name? (case-insensitive)
        H) ip=${OPTARG};; # Public IP?
    esac
done

shift $((OPTIND-1))

ip="/$H"
isp=$(curl -s http://ip-api.com/json | jq -r "[.as,.query] | @csv")
if echo $isp | grep -i $text >/dev/null
then
        echo "OK - $isp"
        exit 0
else
        echo "ERROR - $isp"
        exit 2
fi
