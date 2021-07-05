#!/bin/bash

podno=$1
ite=$2

# make sure all redis pods are ready
ready_redis_pods_num=`kubectl get statefulset | grep redis | awk '{ print $2}' | cut -d "/" -f 1`
target_redis_pods_num=`kubectl get statefulset | grep redis | awk '{ print $2}' | cut -d "/" -f 2`
while [ ${ready_redis_pods_num} -lt ${target_redis_pods_num} ]
do
  sleep 5
  ready_redis_pods_num=`kubectl get statefulset | grep redis | awk '{ print $2}' | cut -d "/" -f 1`
  target_redis_pods_num=`kubectl get statefulset | grep redis | awk '{ print $2}' | cut -d "/" -f 2`
done

# make sure all memtier pods are ready
ready_memtier_pods_num=`kubectl get deployment | grep memtier | awk '{ print $2}' | cut -d "/" -f 1`
target_memtier_pods_num=`kubectl get deployment | grep memtier | awk '{ print $2}' | cut -d "/" -f 2`
while [ ${ready_memtier_pods_num} -lt ${target_memtier_pods_num} ]
do
  sleep 5
  ready_memtier_pods_num=`kubectl get deployment | grep memtier | awk '{ print $2}' | cut -d "/" -f 1`
  target_memtier_pods_num=`kubectl get deployment | grep memtier | awk '{ print $2}' | cut -d "/" -f 2`
done

params="-p 6379 --threads 8 --clients 1 --test-time 60 --ratio 1:10 --data-size 1024 --key-pattern S:S --random-data"
#params="-p 6379 --threads 8 --clients 1 --test-time 300 --ratio 1:10 --data-size 1024 --key-pattern S:S --random-data"
servers=`kubectl get pods | grep memtier | awk '{print $1}'`
echo $servers
mkdir -p ${LOCALTEMP}/result-aof-${podno}-${ite}
let redisno=0
for svr in $servers
do
  #echo $svr
  #echo "kubectl exec $svr -- memtier_benchmark -s redis-${redisno}.redis ${params}"
  kubectl exec $svr -- memtier_benchmark -s redis-${redisno}.redis ${params} > ${LOCALTEMP}/result-aof-${podno}-${ite}/result-aof-${redisno}.txt &
  let redisno++
  if [[ ${redisno} == ${podno} ]]; then
    break;
  fi
done

sleep 5
benchmark_process_num=`ps aux | grep "kubectl exec memtier" | grep -v "grep" | wc -l`
while [ $benchmark_process_num -gt 0 ]
do
  sleep 5 
  benchmark_process_num=`ps aux | grep "kubectl exec memtier" | grep -v "grep" | wc -l`
done
