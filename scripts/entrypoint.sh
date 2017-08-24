#!/usr/bin/env bash

sed -i "s#\${LAUNCHPAD_TRACKER_SEGMENT_TOKEN}#$LAUNCHPAD_TRACKER_SEGMENT_TOKEN#" /usr/share/nginx/html/docs/*.html

exec /run.sh
