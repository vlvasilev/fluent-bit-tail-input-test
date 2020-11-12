#!/bin/bash

kubeconfig=$1
i=1
while [ $i -le 100 ]
do
  echo "Test $i started"
  rm -rf "test-$i"
  mkdir "test-$i"

  kubectl --kubeconfig=$kubeconfig -n garden delete pod --all --force --grace-period=0
  kubectl --kubeconfig=$kubeconfig delete ns garden --force --grace-period=0

  echo "Apply logging"
  kubectl --kubeconfig=$kubeconfig -n garden apply -f logging-stack.yaml

  sleep 10
  echo "Apply loggers" 
  kubectl --kubeconfig=$kubeconfig -n garden apply -f logger.yaml

  timestamp=$(date +%s)
  end_timestamp=$(($timestamp + 900))
  fluent_bit_pods=$(kubectl --kubeconfig=$kubeconfig -n garden get pod -l app=fluent-bit |  awk 'NR>1 {print $1}')
  while [ $timestamp -lt $end_timestamp ]
  do
    number_of_logs=0
    echo "Get the total number of logs"
    for flb_pod in $fluent_bit_pods;
    do
        echo $flb_pod
        temp_result=$(kubectl --kubeconfig=$kubeconfig -n garden exec $flb_pod sh -- -c  "cd /logs; cat \$(ls  | grep logger) | wc -l")
        number_of_logs=$(($number_of_logs + $temp_result))
        echo "Fluent-bit $flb_pod has $temp_result logs"
    done
    echo "Check the total log count"
    if [ "$number_of_logs" -eq "500000" ]
    then
        echo "Recieve all of the 500000 logs"
        break
    fi
    echo "Recieve only $number_of_logs logs"
    timestamp=$(date +%s)
  done

  echo "Get fluent-bit information"
  for flb_pod in $fluent_bit_pods;
  do
    mkdir -p "test-$i/$flb_pod/file_out-$flb_pod"
    echo "Store file output in test-$i/$flb_pod/file_out-$flb_pod"
    kubectl --kubeconfig=$kubeconfig cp garden/$flb_pod:logs "test-$i/$flb_pod/file_out-$flb_pod"
    for file in $(ls test-$i/$flb_pod/file_out-$flb_pod | grep logger)
    do 
        logs_num=$(cat "test-$i/$flb_pod/file_out-$flb_pod/$file" | wc -l)
        if [ ! "$logs_num" -eq "5000" ]
        then 
            cp "test-$i/$flb_pod/file_out-$flb_pod/$file" "test-$i/$flb_pod/$file"
        fi
    done
  done

  kubectl --kubeconfig=$kubeconfig -n garden delete pod --all --force --grace-period=0
  kubectl --kubeconfig=$kubeconfig delete ns garden --force --grace-period=0

  ((i++))
  sleep 180
done