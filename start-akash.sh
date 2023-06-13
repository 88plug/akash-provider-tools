#!/bin/bash

cd /home/akash
if [ -f variables ]; then 
source /home/akash/variables

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
  cat > gpu-test-pod.yaml << EOF
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

  kubectl apply -f gpu-test-pod.yaml
  echo "Waiting for the test pod to start..."
  sleep 10
  kubectl logs gpu-pod
  kubectl delete pod gpu-pod
}

if lspci | grep -q NVIDIA && ! grep -q "GPU_ENABLED=true" variables; then
  configure_gpu
  create_test_pod
fi

fi 
#End NVIDIA

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
