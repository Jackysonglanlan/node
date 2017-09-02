# !/bin/sh
#

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

########################################################
# 此脚本虽然可以运行，但是需要中途输入，还未实现自动化
# 新增服务器时，可参考此脚本，copy 命令即可
########################################################


######################### Handy Command ###############################

### disable centos/7 firewall
# systemctl stop firewalld.service #停止firewall
# systemctl disable firewalld.service #禁止firewall开机启动

### scp
#   scp local_file remote_username@remote_ip:remote_folder
#.  scp -r local_folder remote_username@remote_ip:remote_folder

########################################################


BACKUP_DIR=/home/deploy/backup
SERVER_DIR=/home/deploy/servers

_add_user(){
  sudo useradd deploy
  sudo passwd -l deploy
  sudo visudo
  # 1. COMMENT-OUT: Defaults    requiretty
  # 2. ADD:         deploy  ALL=(ALL)       NOPASSWD: ALL
  
  # SSH passwordless login
  su deploy
  cd /home/deploy
  mkdir .ssh
  chmod 700 .ssh
  cd .ssh
  touch authorized_keys
  chmod 600 authorized_keys
}

_install_yum_libs(){
  sudo yum install gcc gcc-c++
  sudo yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
  sudo yum install perl-ExtUtils-MakeMaker
  
  ### nginx
  cat > nginx.repo <<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF
  sudo mv nginx.repo /etc/yum.repos.d
  sudo yum install nginx
  
  ### git
  sudo yum remove git # remove old version
  # install new version
  curl -L -o git-2.7.3.tar.gz -C - https://www.kernel.org/pub/software/scm/git/git-2.7.3.tar.gz
  tar -zxf git-2.7.3.tar.gz
  cd git-2.7.3
  sudo make prefix=/usr/local/git install
  cd ..
  rm -rf git-2.7.3
  echo "export PATH=$PATH:/usr/local/git/bin" > git.sh
  sudo mv git.sh /etc/profile.d/
}

_download_servers(){
  mkdir $BACKUP_DIR
  cd $BACKUP_DIR
  curl -L -o nodejs.tar.gz -C - https://nodejs.org/dist/v6.10.2/node-v6.10.2-linux-x64.tar.gz
  curl -L -o redis.tar.gz -C - http://download.redis.io/releases/redis-3.2.8.tar.gz
  curl -L -o mongodb.tgz -C - https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.4.4.tgz
}

_install_servers(){
  mkdir $SERVER_DIR
  cd $SERVER_DIR
  
  # node
  tar -zxvf $BACKUP_DIR/nodejs.tar.gz
  mv node-v6.10.2-linux-x64 $SERVER_DIR/node-v6.10.2
  
  # redis
  tar -zxf $BACKUP_DIR/redis.tar.gz
  cd redis-3.2.8
  make PREFIX=$SERVER_DIR/redis-v3.2.8 install
  rm -rf redis-3.2.8
  touch $SERVER_DIR/redis-v3.2.8/redis.conf # cp config content
  
  # mongo
  tar -zxf $BACKUP_DIR/mongodb.tgz
  mv mongodb-linux-x86_64-rhel70-3.4.4 $SERVER_DIR/mongodb-v3.4.4
  touch $SERVER_DIR/mongodb-3.4.4/mongo.conf.yml # cp config content
  
  # server data dir
  mkdir -p $SERVER_DIR/data/{mongo,redis}
  mkdir -p $SERVER_DIR/logs/{mongo,redis}
  
  # add to path
  cat > servers.sh <<-EOF
  export NODE_HOME="$SERVER_DIR/node-v6.10.2"
  export MONGO_HOME="$SERVER_DIR/mongodb-v3.4.4"
  export REDIS_HOME="$SERVER_DIR/redis-v3.2.8"

  PATH=$PATH:$NODE_HOME/bin:$MONGO_HOME/bin:$REDIS_HOME/bin

  export PATH
EOF
  sudo mv servers.sh /etc/profile.d/
}

_config_systems(){
  # npm
  echo 'registry=https://registry.npm.taobao.org/' > ~/.npmrc
  npm i pm2 -g
  pm2 updatePM2
  
  # system limit
  cp /etc/security/limits.conf /etc/security/limits.conf.bak
  cat >> /etc/security/limits.conf <<-EOF
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
* hard  nproc   65535
* soft  nproc   65535
EOF
  
  # system core
  cp /etc/sysctl.conf /etc/sysctl.conf.bak
  cat >> /etc/sysctl.conf <<-EOF

# jacky.song
net.core.netdev_max_backlog =  16384
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.ip_local_port_range = 1024   65000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 2000  65535
net.ipv4.ip_default_ttl = 64
net.ipv4.neigh.default.gc_thresh1 = 128
net.ipv4.neigh.default.gc_thresh2 = 512
net.ipv4.neigh.default.gc_thresh3 = 4096
vm.swappiness=10
vm.vfs_cache_pressure = 250
vm.panic_on_oom = 1
vm.overcommit_memory = 1
kernel.shmmax = 4294967296
EOF
  
  # reload core config
  /sbin/sysctl -p
  
  # set ulimit
  ulimit -f unlimited #(file size)
  ulimit -t unlimited #(cpu time)
  ulimit -v unlimited #(virtual memory)
  ulimit -n 64000 #(open files)
  ulimit -m unlimited #(memory size)
  ulimit -u 64000 #(processes/threads)
  
  # server deploy dir
  sudo mkdir /var/www
  sudo chown deploy.deploy /var/www
}

# _start_servers(){
#   $SERVER_DIR/redis-v3.2.8/bin/redis-server redis.conf
#   $SERVER_DIR/mongodb-v3.4.4/bin/mongod -f mongo.conf.yml
# }


