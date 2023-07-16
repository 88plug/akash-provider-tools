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
        *"960"*) POWER_LIMIT=120 ;;
        *"1660"*) POWER_LIMIT=120 ;;
        *"1080"*) POWER_LIMIT=175 ;;
        *"2070"*) POWER_LIMIT=145 ;;
        *"3060"*) POWER_LIMIT=130 ;;
        *"3070"*) POWER_LIMIT=165 ;;
        *"3090"*) POWER_LIMIT=250 ;;
        *) echo "Unknown GPU model: $GPU_NAME"; exit 1 ;;
    esac

    echo "Setting power limit to $POWER_LIMIT W for GPU $GPU_ID ($GPU_NAME)"

    # Set power limit
    nvidia-smi -i $GPU_ID -pl $POWER_LIMIT
done
