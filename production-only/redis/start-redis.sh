# !/bin/sh
#

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

#####
## for production server 101.37.14.72
#####


~/install/redis-3.2.8/bin/redis-server ~/install/redis-3.2.8/redis.conf
