#!/bin/bash
##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Update Kodi's video library.
#
# This sends a jsonrpc call to Kodi's API to update the video library

##############################################################################
### OPTIONS                                                                ###

# IP address of Kodi
#host=127.0.0.1

# Port that Kodi is listening to for RPC calls
#port=8081

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

SUCCESS=93
ERROR=94
SKIP=95

kodi_running="$(/usr/bin/pgrep kodi.bin)"
if [[ -z $kodi_running ]]; then
    echo "[DETAIL] Kodi is not running; skipping update"
    exit $SKIP
fi

[[ -n $NZBPO_HOST ]] || { echo "[ERROR] Host not set"; exit $ERROR; }
[[ -n $NZBPO_PORT ]] || { echo "[ERROR] Port not set"; exit $ERROR; }

curl --connect-timeout 5 \
     --data-binary \
        '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' \
     -H 'content-type: application/json;' \
     http://${NZBPO_HOST}:${NZBPO_PORT}/jsonrpc 1>/dev/null 2>&1

ret_val="$?"

if [[ $ret_val -eq 0 ]]; then
    exit $SUCCESS
else
    echo "[ERROR] curl returned: $ret_val"
    exit $ERROR
fi

