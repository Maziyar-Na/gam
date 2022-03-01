#!/usr/bin/env bash
bench='/mnt/proj/FAAST/gam/dht/benchmark'
master="10.10.1.1"
log_dir="/mnt/proj/FAAST/gam/dht/log"

mk_dat_dir() {
    for ((id = 1; id <= 4; id++)); do
        if [ "$id" -ne 3 ]; then
            node="10.10.1."$id
            ssh $node "if [ ! -d $log_dir ]; then mkdir -p $log_dir; fi"
        fi
    done
}

kill_all() {
    for ((id = 1; id <= 4; id++)); do
        if [ "$id" -ne 3 ]; then
            node="10.10.1."$id
            ssh $node "sudo killall benchmark"
        fi
    done
    sleep 1
}

run_client() {
    local nc=$1
    local nt=$2
    local ratio=$3
    local cid=0
    is_master=1
    for ((id = 1; id < 5; id++)); do
        if [ "$id" -ne 3 ]; then
            node="10.10.1."$id
            log_file="$log_dir/$node"_"$nc"_"$nt"_"$ratio"_"$cid".dat
            if [ "$is_master" -eq 1 ]; then
                master=$node
            fi
            echo "run client at $node  with master $master"
            if [ "$cid" -eq 0 ]; then
                cmd="ssh $node \"sudo $bench --is_master $is_master --ip_master $master --ip_worker $node --no_client $nc --get_ratio $ratio --no_thread $nt --client_id $cid 1>$log_file &\""
                eval $cmd
                is_master=0
            else
                cmd="ssh $node \"sudo $bench --is_master $is_master --ip_master $master --ip_worker $node --no_client $nc --get_ratio $ratio --no_thread $nt --client_id $cid >$log_file &\""
                eval $cmd
            fi
            ((cid++))
        fi
        sleep 1
    done
}


clients=3
#ratios=(100 99 90 50 0)
ratios=(100)
mk_dat_dir
for ((thread = 1; thread<=1; thread++)); do
    for ratio in "${ratios[@]}"; do
        #kill_all
        echo "run benchmark with $clients clients $thread threads and $ratio get_ratio "
        run_client $clients $thread $ratio
    done
done
