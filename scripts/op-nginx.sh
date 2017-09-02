#
#! /bin/sh
#
#
# Usage:
#   NODE_ENV=dev ./op-nginx.sh upstreamTo localhost:5001,localhost:5002
#
# NODE_ENV is the nginx environment value, like "dev", "inner.test", "production"
# $1: public method
# $2: parameter of that public method
#
# see https://github.com/punkave/mechanic

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

. $(dirname "$0")/lib/utils.sh

${NODE_ENV:? 'Missing NODE_ENV !!!'}

use_red_green_echo "op-nginx:$NODE_ENV"

_invokeMechanic(){
  # 说明:
  # 1. 每次执行 mechanic 都需要传 --data 读取我们的配置, 否则会读取默认的 mechanic.json
  # 2. update 指令: 重新装载 mechanic.json 和 template.conf, 生成新的 nginx 配置, 然后执行 nginx -s reload 生效
  
  # if [[ $NODE_ENV == 'dev' ]]; then
  #   node ./production-only/nginx/mechanic/lib/index --data=production-only/nginx/mechanic/config/nginx-conf.dev.json $@
  #   return
  # fi
  
  node ./production-only/nginx/mechanic/lib/index --data=production-only/nginx/mechanic/config/nginx-conf.$NODE_ENV.json $@
}

_update_server_yqj_wit_work(){
  _invokeMechanic update yqj-wit-work $@
}

_callMechanic(){
  _invokeMechanic $@
}

#########################
##### public methods ####
#########################

##
# $1: list of backend servers, like "localhost:5001,localhost:5002,localhost:5003"
#
upstreamTo(){
  _update_server_yqj_wit_work --backends="$1"
}

start(){
  _callMechanic start
}

reload(){
  _callMechanic refresh
}


# 外部直接传 方法名+参数 实现动态调用, 比如: ./op-nginx.sh upstreamTo localhost:5001,localhost:5002
$1 ${2:-}

green 'operate nginx done!'
