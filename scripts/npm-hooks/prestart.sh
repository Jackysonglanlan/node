#
#!/bin/sh

. $(dirname "$0")/../lib/utils.sh

use_red_green_echo "prestart"

_set_env_value(){
  export NODE_ENV=$1
}
_set_env_value ${1:? "Missing NODE_ENV as 1st param"}

_check_dependencies(){
  out=$(node src/health/health-check-console.js)
  
  if [[ $out == "1 - "* ]]; then
    red "-----------------"
    red ${out:1}
    red "-----------------"
    exit 1
  fi
  
  echo
  green "-------------------------------"
  green "All dependencies are OK..."
  green "-------------------------------"
  echo
}

_invoke_init_script(){
  echo
  green "-------------------------------"
  green "Invoke init scripts..."
  green "-------------------------------"
  
  ./scripts/init/init.sh $PWD
  echo
}

run(){
  npm_install_if_needed package.json
  # _check_dependencies
  _invoke_init_script
}

run
