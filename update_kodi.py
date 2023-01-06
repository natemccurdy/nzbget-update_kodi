#!/usr/bin/env python3
##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Update Kodi's video library
#
# This script sends a jsonrpc call to Kodi's API to update the video library.
#
# NOTE: Requires that Kodi's Web Interface is enabled: http://kodi.wiki/view/Web_interface
#
# NOTE: Requires Python 3+
#
#
# Web-site: http://github.com/natemccurdy/nzbget-update_kodi
#
# Version: 2.0.0

# fmt: off
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

# Require previous scripts to succeed before updating Kodi (yes, no).
#
# Setting this to 'yes' will check the exit status of all prior extension
# scripts. If any of them failed, Kodi will not be updated. This is useful when
# used in combination with VideoSort. For example, if VideoSort fails, there's
# no need to update Kodi. When this is set to 'yes', make sure to order this
# extension after VideoSort.
#require_prior_scripts=no
#
### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################
pass  # https://github.com/psf/black/issues/1245
# fmt: on

import os  # noqa: E402
import sys  # noqa: E402
from urllib.request import Request, urlopen  # noqa: E402
from urllib.error import HTTPError, URLError  # noqa: E402


SUCCESS = 93
FAILURE = 94
NONE = 95

HOST = os.getenv("NZBPO_HOST")
PORT = os.getenv("NZBPO_PORT")


def info(msg: str):
    print(f"[INFO] {msg}")


def warning(msg: str):
    print(f"[WARNING] {msg}")


def error(msg: str):
    print(f"[ERROR] {msg}")


def detail(msg: str):
    print(f"[DETAIL] {msg}")


def check_download_success():
    if os.getenv("NZBPP_TOTALSTATUS") != "SUCCESS":
        warning(f"The download of {os.getenv('NZBPP_NZBNAME')} has failed; skipping update.")
        sys.exit(NONE)


def check_prior_scripts():
    if os.getenv("NZBPP_SCRIPTSTATUS") != "SUCCESS":
        warning("Prior extension scripts did not succeed; skipping update.")
        sys.exit(NONE)


def main():
    check_download_success()
    if os.getenv("NZBPO_REQUIRE_PRIOR_SCRIPTS") == "yes":
        check_prior_scripts()

    kodi_url = f"http://{HOST}:{PORT}/jsonrpc"
    rpc_command = '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}'
    timeout = 5

    request = Request(url=kodi_url, data=rpc_command.encode("utf-8"))
    request.add_header("Content-Type", "application/json; charset=utf-8")

    detail(f"Sending Kodi video library update to: {request.full_url}")

    try:
        with urlopen(request, timeout=timeout) as response:
            result = response.read().decode()
    except HTTPError as e:
        error(f"Can't connect to {request.full_url} - {e.code} - {e.reason}")
        sys.exit(FAILURE)
    except URLError as e:
        error(f"Can't connect to {request.full_url} - {e.reason}")
        sys.exit(FAILURE)
    else:
        info(f"Kodi video library update successful - {result}")
        sys.exit(SUCCESS)


if __name__ == "__main__":
    main()
