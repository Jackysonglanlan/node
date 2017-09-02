# !/bin/sh
#

#####
## 应用初始化脚本，执行所有需要在应用启动之前需要做的事情
## 该脚本在 npm hook 中使用，具体见 package.json 的 “HOOKs” 段
#####

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

. $(dirname "$0")/../lib/utils.sh

use_red_green_echo "init"

BASE_DIR=${1:?'Missing $1 as BASE_DIR'}

INIT_HAS_RUN_FILE_NAME="init_has_run_mark_file.log" # use .log suffix to avoid git trace

###### private

_check_if_init_process_has_run(){
  if [[ -e $INIT_HAS_RUN_FILE_NAME ]]; then
    yellow 'init process has already run, quit...'
    exit 0
  fi
}

_invoke_node_init(){
  yellow 'running init.js by node...'
  node $BASE_DIR/scripts/init/init.js
}

_make_tmp_dir(){
  yellow 'making tmp dirs...'
  mkdir -p tmp/{demo,}
}

_make_logs_dir(){
  yellow 'making logs dirs...'
  mkdir -p logs/{error,nginx,pm2,pids}
}

_done_init_process(){
  # create a mark file to show that init process is done.
  touch $INIT_HAS_RUN_FILE_NAME
  green 'done'
}

# other init things
# _TODO(){
#   #
# }

###### public

green 'running init scripts...'

run(){
  _check_if_init_process_has_run
  _invoke_node_init
  _make_tmp_dir
  _make_logs_dir
  _done_init_process
}

run

#
