#
#!/bin/sh
#
#


# Usage:
#
# scripts/start.sh NODE_ENV
#
# NODE_ENV: dev or production
#

. $(dirname "$0")/lib/utils.sh

use_red_green_echo "start"

##### start #####

_set_env_value(){
  export NODE_ENV=$1
}
_set_env_value ${1:? "Missing NODE_ENV as 1st param"}

_start(){
  if [[ $NODE_ENV == 'dev' ]]; then
    node ./node_modules/.bin/nodemon --watch src --watch config --watch server.js server.js
  fi
  
  if [[ $NODE_ENV == 'production' ]]; then
    node ./node_modules/.bin/pm2 start ecosystem.json --env production
  fi
}

##### run #####

main(){
  _start
}


# main




