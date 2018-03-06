#!/bin/bash

###
# Autor: Olaf Reitmaier <olafrv@gmail.com>
#
# Implementacion en BASH del Plugin para Nagios para Chequeo de Cluster de Peacemaker:
# https://exchange.nagios.org/directory/Plugins/Clustering-and-High-2DAvailability/Check-CRM/details
#
# A diferencia del script en Perl no incluye el chequeo de 'constraints' de Peacemaker.
#
# Sintaxis: check_crm.sh
#
# Resultado: retorna un codigo de estado de Nagios: 
#  - 0 con su respectivo mensaje (i.e. "STATUS: OK")
#  - 1 si una alerta (WARNING) con un mensaje descriptivo
#  - 2 si hay un error critico (CRITICAL) con un mensaje descritivo
##

R_OK=0
R_WARNING=1
R_CRITICAL=2

C_SUDO='/usr/bin/sudo'
C_MONC='/usr/sbin/crm_mon -1 -r -f'

F_OUT="/tmp/check_crm.tmp"

[ ! -e "$F_OUT" ] || rm -f "$F_OUT";
DELETED=$?
if [ $DELETED -ne 0 ]
then
	echo "Can't write output file: $F_OUT"
	exit $R_CRITICAL
fi

R_CODE=$R_OK;
R_MSGS="STATUS:"

$C_SUDO $C_MONC 2>&1 > "$F_OUT"
EXECUTED=$?

if [ $EXECUTED -ne 0 ]
then
	echo "Running $C_SUDO $C_MONC failed";
	exit $R_CRITICAL;
elif grep -i "Connection to cluster failed" "$F_OUT" > /dev/null
then
	echo "Connection to cluster failed";
	exit $R_CRITICAL;
elif grep -i "Failed actions" "$F_OUT" > /dev/null
then
	R_MSGS="$R_MSGS Detected failed actions or failed actions not cleaned up";
	R_CODE=$R_WARNING;
elif ! grep -i "partition with quorum" "$F_OUT" > /dev/null
then 
	R_MSGS="$R_MSGS Cluster quorum is lost"
	R_CODE=$R_CRITICAL;
elif egrep -i "offline|stopped|standby|fail-count|unmanaged|not installed" "$F_OUT" > /dev/null
then
	R_MSGS="$R_MSGS There are cluster nodes and/or resources with problems"
	R_CODE=$R_CRITICAL;
fi

if [ $R_CODE == $R_OK ]; then R_MSGS="STATUS: OK"; fi

echo $R_MSGS
exit $R_CODE

