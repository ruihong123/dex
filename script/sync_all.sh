#!/bin/bash
home_dir="/users/Ruihong/dex/"
nmemory="10"
ncompute="10"
nmachines="20"
nshard="10"
numa_node=("0" "1")
port=$((10000+RANDOM%1000))
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
SRC_HOME=$bin/..
BIN_HOME=$bin/../release
core_dump_dir="/mnt/core_dump"
function run_bench() {
  communication_port=()
#	memory_port=()
	memory_server=()
  memory_shard=()

#	compute_port=()
	compute_server=()
	compute_shard=()
#	machines=()
	i=0
  n=0
  while [ $n -lt $nmemory ]
  do
    memory_server+=("node-$i")
    i=$((i+1))
    n=$((n+1))
  done
  n=0
  i=$((nmachines-1))
  while [ $n -lt $ncompute ]
  do

    compute_server+=("node-$i")
    i=$((i-1))
    n=$((n+1))
  done
  echo "here are the sets up"
  echo $?
  echo compute servers are ${compute_server[@]}
  echo memoryserver is ${memory_server[@]}
#  echo ${machines[@]}
  n=0
  while [ $n -lt $nshard ]
  do
    communication_port+=("$((port+n))")
    n=$((n+1))
  done
  n=0
  while [ $n -lt $nshard ]
  do
    # if [[ $i == "2" ]]; then
    # 	i=$((i-1))
    # 	continue
    # fi
    compute_shard+=(${compute_server[$n%$ncompute]})
    memory_shard+=(${memory_server[$n%$nmemory]})
    n=$((n+1))
  done
  echo compute shards are ${compute_shard[@]}
  echo memory shards are ${memory_shard[@]}
  echo communication ports are ${communication_port[@]}
#  test for download and compile the codes
  n=0

  for node in ${memory_shard[@]}
  do
    echo "Rsync the $node rsync -a $home_dir $node:$home_dir"
#    ssh -o StrictHostKeyChecking=no $node "sudo apt-get install -y libnuma-dev numactl htop libmemcached-dev libboost-all-dev" &
    rsync -a $home_dir $node:$home_dir
    ssh -o StrictHostKeyChecking=no $node "pkill -f newbench" &
#    ssh -o StrictHostKeyChecking=no $node "sudo apt install libtbb-dev -y" &

    ssh -o StrictHostKeyChecking=no $node "rm $home_dir/scripts/log*" &
    ssh ${ssh_opts} $node "echo '$core_dump_dir/core$compute' | sudo tee /proc/sys/kernel/core_pattern" &
  done

  for node in ${compute_shard[@]}
  do
    echo "Rsync the $node rsync -a $home_dir $node:$home_dir"
#    ssh -o StrictHostKeyChecking=no $node "sudo apt-get install -y libnuma-dev numactl htop libmemcached-dev libboost-all-dev" &
    rsync -a $home_dir $node:$home_dir
    ssh -o StrictHostKeyChecking=no $node "pkill -f newbench" &
#    ssh -o StrictHostKeyChecking=no $node "sudo apt install libtbb-dev -y" &

    ssh -o StrictHostKeyChecking=no $node "rm $home_dir/scripts/log*" &
    ssh ${ssh_opts} $node "echo '$core_dump_dir/core$compute' | sudo tee /proc/sys/kernel/core_pattern" &



  done
  read -r -a memcached_node <<< $(head -n 1 $SRC_HOME/memcached_ip.conf)
  echo "restart memcached on ${memcached_node[0]}"
  ssh -o StrictHostKeyChecking=no ${memcached_node[0]} "sudo service memcached restart"


	}
	run_bench