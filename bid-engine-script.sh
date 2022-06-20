#!/bin/bash
data_in=$(jq .)
cpu_total=$(echo "$data_in" | jq 'map(.cpu * .count) | add')
memory_gb=$(echo "$data_in" | jq -r '(map(.memory * .count) | add) / pow(1024; 3)')
hd_gb=$(echo "$data_in" | jq -r '([.[].storage[] | select(.class == "ephemeral").size // 0] | add) / pow(1024; 3)')
cpu_total_threads=$(echo $cpu_total | awk '{print $1/1000}')
usd_per_akt=$(curl -s -X GET "https://api.coingecko.com/api/v3/coins/akash-network/tickers" -H  "accept: application/json" | jq '.tickers[] | select(.market.name == "Osmosis").converted_last.usd' | head -n1)

#Price in USD
TARGET_MEMORY="0.10"
TARGET_HD="0.10"
TARGET_CPU="2.78"

#Chia Madmax Plotter
chia_madmax_cpu=8
chia_madmax_cpu_max=32
chia_madmax_memory=6
chia_madmax_memory_max=32
chia_madmax_storage=512
chia_madmax_storage_max=3200

#Chia Bladebit Plotter
chia_bladebit_cpu=32
chia_bladebit_cpu_max=256
chia_bladebit_memory=420
chia_bladebit_memory_max=512
chia_bladebit_storage=512
chia_bladebit_storage_max=3200

#Bladebit
if (( $(echo "$memory_gb >= $chia_bladebit_memory" | bc -l) && \
  $(echo "$memory_gb <= $chia_bladebit_memory_max" | bc -l) && \
  $(echo "$cpu_total_threads >= $chia_bladebit_cpu" | bc -l) && \
  $(echo "$cpu_total_threads <= $chia_bladebit_cpu_max" | bc -l) && \
  $(echo "$hd_gb >= $chia_bladebit_storage" | bc -l) && \
  $(echo "$hd_gb <= $chia_bladebit_storage_max" | bc -l) )); then
TARGET_CPU="13.09"
total_cost_usd_target=$(bc -l <<<"($cpu_total_threads * $TARGET_CPU)")
#MadMax
elif (( $(echo "$memory_gb >= $chia_madmax_memory" | bc -l) && \
  $(echo "$memory_gb <= $chia_madmax_memory_max" | bc -l) && \
  $(echo "$cpu_total_threads >= $chia_madmax_cpu" | bc -l) && \
  $(echo "$cpu_total_threads <= $chia_madmax_cpu_max" | bc -l) && \
  $(echo "$hd_gb >= $chia_madmax_storage" | bc -l) && \
  $(echo "$hd_gb <= $chia_madmax_storage_max" | bc -l) )); then
TARGET_CPU="5.09"
total_cost_usd_target=$(bc -l <<<"($cpu_total_threads * $TARGET_CPU)")
else
#Normal Deployment
total_cost_usd_target=$(bc -l <<<"(($cpu_total_threads * $TARGET_CPU) + ($memory_gb * $TARGET_MEMORY) + ($hd_gb * $TARGET_HD))")
fi

total_cost_akt_target=$(bc -l <<<"(${total_cost_usd_target}/$usd_per_akt)")
total_cost_uakt_target=$(bc -l <<<"(${total_cost_akt_target}*1000000)")
cost_per_block=$(bc -l <<<"(${total_cost_uakt_target}/425940.524781341)")
total_cost_uakt=$(echo "$cost_per_block" | jq 'def ceil: if . | floor == . then . else . + 1.0 | floor end; .|ceil')
echo $total_cost_uakt
