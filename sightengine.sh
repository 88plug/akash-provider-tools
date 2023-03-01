# Set up variables for Sightengine API
sightengine_user="x"
sightengine_secret="x"
sightengine_api_url="https://api.sightengine.com/1.0/check.json"

# Define keywords to check
keywords1="nude|porn|sex|xxx"
keywords2="drug|abuse|gun|weapon"
keywords3="pirate|warez|torrent"

# Get the list of pod names and their associated namespaces
pod_namespaces=($(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase == "Running") | .metadata.name + "|" + .metadata.namespace'))
exclude_namespaces="akash-services|kube-system|ingress-nginx|lens-metrics"

# Loop through the pod names and namespaces to check their images for inappropriate content
for pod_namespace in "${pod_namespaces[@]}"; do
    # Parse the pod name and namespace from the array
    pod_name=${pod_namespace%|*}
    namespace=${pod_namespace#*|}
    echo "Checking pod $pod_name in namespace $namespace"

    # Skip excluded namespaces
    if [[ $exclude_namespaces =~ (^|\|\|)$namespace($|\|\|) ]]; then
        echo "Skipping $pod_name!"
        continue
    fi

    # Loop through supported image types
    supported_image_types=("jpg" "jpeg" "png" "gif" "bmp" "svg" "webp")
    for image_type in "${supported_image_types[@]}"; do
        # Find image files and check them for inappropriate content
        for image_file in $(kubectl exec -n $namespace $pod_name -- find / \( -path /host -o -path /proc \) -prune -o -type f \( -iname \*.$image_type \) -size +1c -print 2>/dev/null); do
            tmp_file=$(mktemp)
            kubectl exec $pod_name -n $namespace -- cat $image_file > $tmp_file
            width=$(identify -format '%w' $tmp_file 2>/dev/null)
            height=$(identify -format '%h' $tmp_file 2>/dev/null)
            if [[ -n $width && -n $height && $width -gt 25 && $height -gt 25 ]]; then
                response=$(curl -s -X POST -F "models=nudity-2.0,wad,offensive,scam,face-attributes,gore" -F "media=@$tmp_file" "https://api.sightengine.com/1.0/check.json?api_user=$sightengine_user&api_secret=$sightengine_secret")
                if [[ $response == *"\"status\": \"success\","* ]]; then
                    if [[ $(echo $response | jq '.alcohol') > 0.5 || $(echo $response | jq '.offensive.prob') > 0.5 || $(echo $response | jq '.weapon') > 0.5 || $(echo $response | jq '.nudity.sexual_display') > 0.5 || $(echo $response | jq '.nudity.sexual_activity') > 0.5 || $(echo $response | jq '.nudity.erotica') > 0.5 || $(echo $response | jq '.nudity.suggestive_classes | .["male_chest"]') > 0.5 || $(echo $response | jq '.nudity.suggestive_classes | .["cleavage"]') > 0.5 || $(echo $response | jq '.nudity.suggestive_classes | .["lingerie"]') > 0.5 || $(echo $response | jq '.nudity.suggestive_classes | .["miniskirt"]') > 0.5 || $(echo $response | jq '.nudity.suggestive_classes | .["bikini"]') > 0.5 || $(echo $response | jq '.nudity.suggestive') > 0.5 || $(echo $response | jq '.drugs') > 0.5 || $(echo $response | jq '.scam.prob') > 0.5 || $(echo $response | jq '.gore.prob') > 0.5 ]]; then
                        echo "We found inappropriate content in $image_file"
                        break
                    fi
                fi
                rm $tmp_file
            fi
        done
    done
done
