#!/bin/bash
set -e
exec /usr/bin/tini -- supervisord -n -c /etc/supervisord.conf 
