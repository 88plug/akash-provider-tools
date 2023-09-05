#!/bin/bash

# Detect and limit GPU power

# Set the default power limit in milliwatts
POWER_LIMIT=200

# List all the NVIDIA GPU IDs
GPU_IDS=$(nvidia-smi --query-gpu=index --format=csv,noheader,nounits | awk '{ print $1 }')

# Apply the power limit to all GPUs
for GPU_ID in $GPU_IDS; do

    GPU_NAME=$(nvidia-smi -i $GPU_ID --query-gpu=name --format=csv,noheader,nounits)

    # Determine power limit based on GPU model
    case "$GPU_NAME" in
        *"950"*) POWER_LIMIT=75 ;;
        *"960"*) POWER_LIMIT=120 ;;
        *"970"*) POWER_LIMIT=145 ;;
        *"980"*) POWER_LIMIT=165 ;;
        *"980 Ti"*) POWER_LIMIT=250 ;;
        *"1050"*) POWER_LIMIT=75 ;;
        *"1050 Ti"*) POWER_LIMIT=75 ;;
        *"1060"*) POWER_LIMIT=120 ;;
        *"1070"*) POWER_LIMIT=150 ;;
        *"1070 Ti"*) POWER_LIMIT=180 ;;
        *"1080"*) POWER_LIMIT=175 ;;
        *"1080 Ti"*) POWER_LIMIT=250 ;;
        
        # 20 Series
        *"1650"*) POWER_LIMIT=75 ;;
        *"1660"*) POWER_LIMIT=120 ;;
        *"1660 Ti"*) POWER_LIMIT=120 ;;
        *"2060"*) POWER_LIMIT=160 ;;
        *"2070"*) POWER_LIMIT=145 ;;
        *"2070 Super"*) POWER_LIMIT=175 ;;
        *"2080"*) POWER_LIMIT=215 ;;
        *"2080 Super"*) POWER_LIMIT=250 ;;
        *"2080 Ti"*) POWER_LIMIT=260 ;;
        
        # 30 Series
        *"3050"*) POWER_LIMIT=90 ;;
        *"3060"*) POWER_LIMIT=130 ;;
        *"3060 Ti"*) POWER_LIMIT=150 ;;
        *"3070"*) POWER_LIMIT=165 ;;
        *"3070 Ti"*) POWER_LIMIT=185 ;;
        *"3080"*) POWER_LIMIT=235 ;;
        *"3080 Ti"*) POWER_LIMIT=270 ;;
        *"3090"*) POWER_LIMIT=250 ;;
        
        # 40 Series
        *"4050"*) POWER_LIMIT=100 ;;
        *"4060"*) POWER_LIMIT=140 ;;
        *"4060 Ti"*) POWER_LIMIT=160 ;;
        *"4070"*) POWER_LIMIT=180 ;;
        *"4070 Ti"*) POWER_LIMIT=200 ;;
        *"4080"*) POWER_LIMIT=255 ;;
        *"4080 Ti"*) POWER_LIMIT=280 ;;
        *"4090"*) POWER_LIMIT=300 ;;
        *) echo "Unknown GPU model: $GPU_NAME"; exit 1 ;;
    esac

    echo "Setting power limit to $POWER_LIMIT W for GPU $GPU_ID ($GPU_NAME)"

    # Set power limit
    nvidia-smi -i $GPU_ID -pl $POWER_LIMIT
done
