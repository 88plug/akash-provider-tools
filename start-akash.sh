#!/bin/bash

echo "Welcome back!"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

function configure_gpu() {
  echo "Detected GPU but not set up. Starting configuration..."

  # Add Helm repositories
  helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
  helm repo add akash https://akash-network.github.io/helm-charts
  helm repo update

  # Create NVIDIA RuntimeClass
  cat > /home/akash/gpu-nvidia-runtime-class.yaml <<EOF
kind: RuntimeClass
apiVersion: node.k8s.io/v1
metadata:
  name: nvidia
handler: nvidia
EOF

  kubectl apply -f /home/akash/gpu-nvidia-runtime-class.yaml

  # Install NVIDIA Device Plugin
  helm upgrade -i nvdp nvdp/nvidia-device-plugin \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --set runtimeClassName="nvidia"

  echo "Waiting 30 seconds for the GPU to settle..."
  sleep 30
  kubectl get pods -A -o wide

  # Set GPU_ENABLED to true
  echo "GPU_ENABLED=true" >> variables
}

function create_test_pod() {
  cat > gpu-test-pod.yaml <<EOF
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: nvidia
handler: nvidia
---
apiVersion: v1
kind: Pod
metadata:
  name: nbody-gpu-benchmark
  namespace: default
spec:
  restartPolicy: OnFailure
  runtimeClassName: nvidia
  containers:
  - name: cuda-container
    image: nvcr.io/nvidia/k8s/cuda-sample:nbody
    args: ["nbody", "-gpu", "-benchmark"]
    resources:
      limits:
        nvidia.com/gpu: 1
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: all
    - name: NVIDIA_DRIVER_CAPABILITIES
      value: all
EOF

  k3s kubectl apply -f gpu-test-pod.yaml
  echo "Waiting for the test pod to start..."

  wait_for_pod "nbody-gpu-benchmark" 60 5
}

function wait_for_pod() {
  local POD_NAME=$1
  local MAX_WAIT_SECONDS=$2
  local WAIT_INTERVAL_SECONDS=$3
  local elapsed_seconds=0

  while [[ $elapsed_seconds -lt $MAX_WAIT_SECONDS ]]; do
    local pod_status=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}')
    
    case $pod_status in
      "Pending")
        echo "Pod '$POD_NAME' is in 'Pending' state. Waiting for it to be scheduled on a node..."
        ;;

      "Running")
        local ready_containers=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.containerStatuses[*].ready}' | grep -c true)
        local total_containers=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.containerStatuses[*].ready}' | wc -w)
        
        if [[ $ready_containers -eq $total_containers ]]; then
          echo "All containers in Pod '$POD_NAME' are ready."
          break
        else
          echo "Waiting for all containers in Pod '$POD_NAME' to be ready. Waiting for $WAIT_INTERVAL_SECONDS seconds..."
        fi
        ;;

      "Succeeded")
        echo "Pod '$POD_NAME' has reached the 'Completed' state."
        kubectl logs "$POD_NAME"
        kubectl delete pod "$POD_NAME"
        echo "GPU_BUG=false" >> variables

        break
        ;;

      "Failed")
        echo "Pod '$POD_NAME' has reached the 'Failed' state."
        kubectl logs "$POD_NAME"
        kubectl delete pod "$POD_NAME"
        echo "GPU_BUG=true" >> variables

        break
        ;;

      *)
        echo "Waiting for Pod '$POD_NAME' to reach the desired state. Waiting for $WAIT_INTERVAL_SECONDS seconds..."
        ;;
    }

    sleep "$WAIT_INTERVAL_SECONDS"
    elapsed_seconds=$((elapsed_seconds + WAIT_INTERVAL_SECONDS))
  done

  if [[ $elapsed_seconds -ge $MAX_WAIT_SECONDS ]]; then
    echo "Timeout: Pod '$POD_NAME' did not reach the desired state within $MAX_WAIT_SECONDS seconds."
  fi
}

if lspci | grep -q NVIDIA && ! grep -q "GPU_ENABLED=true" variables; then
  configure_gpu
  create_test_pod
fi

cleanup_bootstrap() {
    if [ -f ./*bootstrap.sh ]; then
        echo "Found old installers - cleaning up"
        rm ./microk8s-bootstrap.sh 2>/dev/null
        rm ./k3s-bootstrap.sh 2>/dev/null
        rm ./kubespray-bootstrap.sh 2>/dev/null
    fi
}

run_bootstrap() {
    local method=$1
    local bootstrap_script

    case "$method" in
        kubespray)
            bootstrap_script="kubespray-bootstrap.sh"
            ;;
        microk8s)
            bootstrap_script="microk8s-bootstrap.sh"
            ;;
        k3s)
            bootstrap_script="k3s-bootstrap.sh"
            ;;
        *)
            echo "Invalid method: $method"
            exit 1
            ;;
    esac

    wget -q --no-cache "https://raw.githubusercontent.com/88plug/akash-provider-tools/main/$bootstrap_script"
    chmod +x "$bootstrap_script"
    echo "No setup detected! Enter the default password 'akash' to start the Akash installer"
    sudo "./$bootstrap_script"
}

main() {
    cleanup_bootstrap
    if [ ! -f variables ]; then
        while true; do
            read -p "Which Kubernetes install method would you like to use (k3s/microk8s/kubespray)? (microk8s): " method
            read -p "Are you sure you want to install with the $method method? (y/n): " choice

            case "$choice" in
                [Yy])
                    run_bootstrap "$method"
                    break
                    ;;
                [Nn])
                    echo "Please try again with microk8s if unsure"
                    sleep 3
                    ;;
                *)
                    echo "Invalid entry, please try again with Y or N"
                    sleep 3
                    ;;
            esac
        done
    else
        source variables
        if [[ $SETUP_COMPLETE == true ]]; then
            export KUBECONFIG=/home/akash/.kube/kubeconfig
            echo "Variables file detected - Setup complete"
        fi
    fi
}

# Execute the main function
main
