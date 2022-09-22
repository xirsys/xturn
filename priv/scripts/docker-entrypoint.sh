#!/bin/sh
set -e

# Launch the OTP release and replace the caller as Process #1 in the container
XTURN_SERVER_IP=$(/usr/local/bin/detect-external-ip.sh) exec /opt/$APP_NAME/bin/$APP_NAME "$@"
