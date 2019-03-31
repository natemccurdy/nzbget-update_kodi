#!/bin/bash
##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Update Kodi's video library.
#
# This script sends a jsonrpc call to Kodi's API to update the video library.
#
# It also requires that the web interface be enabled in Kodi. Instructions
# for that can be found here:
#     http://kodi.wiki/view/Web_interface
#
# Info about update_kodi:
# Web-site: http://github.com/natemccurdy/nzbget-update_kodi.
# PP-Script Version: 1.1.2.
#
# NOTE: This script only runs on *nix based hosts with BASH.
#       It also requires that curl is installed and is in the $PATH.

##############################################################################
### OPTIONS                                                                ###

# The hostname or IP address of the host running Kodi.
#
# This can be a remote host or a local host. e.g. 192.168.1.50 or localhost
#host=127.0.0.1

# The port that Kodi is listening to for API calls.
#
# This should be the port number that you see on the 'Web Server' page in
# Kodi's settings.
#port=8081

# Whether to force an update or not (yes, no).
#
# If Kodi is on the same host as NZBGet, we can check to see that Kodi is
# running before trying to hit its API. This way, we get a clean "Skip" in
# NZBGET instead of an "ERROR". If you want to disable this check and
# always try to hit the API, set this to 'yes'.
#force_update=no

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

SUCCESS=93
ERROR=94
SKIP=95

# Check that the required options have been set before continuing
[[ -n $NZBPO_HOST ]] || { echo "[ERROR] Host not set"; exit $ERROR; }
[[ -n $NZBPO_PORT ]] || { echo "[ERROR] Port not set"; exit $ERROR; }

kodi_is_local () {
  hostname="$(hostname)"
  case "$NZBPO_HOST" in
    localhost|127.0.0.1|$hostname) return 0;;
    *)                             return 1;;
  esac
}

kodi_is_running_locally () {
  if pgrep -i kodi 1>/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

if [[ $NZBPO_FORCE_UPDATE == 'no' ]]; then
  if kodi_is_local && ! kodi_is_running_locally; then
    echo "[DETAIL] Kodi is not running so we can't update it; skipping update."
    exit $SKIP
  fi
fi

if ! which curl 1>/dev/null 2>&1; then
  echo '[ERROR] Can not find curl. update_kodi requires curl to be installed and in $PATH.'
  exit $ERROR
fi

curl --connect-timeout 5 \
  --data-binary \
  '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' \
  -H 'content-type: application/json;' \
  http://${NZBPO_HOST}:${NZBPO_PORT}/jsonrpc 1>/dev/null 2>&1

curl_return_value="$?"

case $curl_return_value in
  0)
    exit $SUCCESS ;;
  6)
    echo "[ERROR] Couldn't resolve host: ${NZBPO_HOST}"
    exit $ERROR ;;
  7)
    echo "[ERROR] Could not connect to the Kodi API endpoint at ${NZBPO_HOST}:${NZBPO_PORT}."
    echo "[ERROR] Is Kodi running and is 'Allow remote control via HTTP' enabled?"
    exit $ERROR ;;
  *)
    echo "[ERROR] Unknown error occured. Curl returned: ${curl_return_value}"
    exit $ERROR ;;
esac
