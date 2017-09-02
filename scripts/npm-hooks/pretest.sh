#
#!/bin/sh

. $(dirname "$0")/../lib/utils.sh

use_red_green_echo "pretest"

_set_env_value(){
  export NODE_ENV=$1
}
_set_env_value ${1:? "Missing NODE_ENV as 1st param"}

npm_install_if_needed package.json

./scripts/init/init.sh $PWD

green "clean test logs..."

rm -f logs/*.log
rm -f logs/{error,nginx,pm2}/*.*
