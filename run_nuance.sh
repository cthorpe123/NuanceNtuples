#!/bin/bash

# Run a command using nuance image, assumes you have already
# setup colima with:
# colima start --profile x86 --arch x86_64 --memory 4
# docker context use colima-x86

docker load < nuance-image.tar

events=50
card=/cards/may07baseline_20070507.card

nuance_cmd='nuance /nuance/build/nuanceMc -i baseline_20070507/may07baseline_20070507.fzc'

mkdir -p output

echo "Running the nuance command:"
echo ${nuance_cmd}

for seed in $(seq 1 10);
do

  echo "Running with seed ${seed}"
  nohup  docker run --name docker_${seed} --rm -v ${PWD}/output:/output -v ${PWD}/cards:/cards -w /nuance/pkg/Nuance/v3/data $nuance_cmd -h /output/events_${seed}.hbook -nevt ${events} -r ${seed} ${card} >& Out.log &

  # Nuance always seems to complete by the time these commands are invoked (assumption that might break if we try more events)
  # assume if nuance is still going by this point it has started looping
  sleep 1
  docker stop docker_${seed}

  # Check if loop has happened - delete output file if it has
  error=$(tail -n 5 Out.log | grep 'x value outside physical range' | wc -l)
  if [ $error -gt 0 ]; then
    rm output/events_${seed}.hbook
  fi

  # Safeguard against lots of docker processes getting started
  processes=$(docker ps | wc -l)
  if [ $((processes-1)) -gt 0 ]; then
    echo "Multiple docker processes detected, stopping"
    exit
  fi

done
