#!/bin/bash
# Set the number of results to retrieve per page
PAGE_SIZE=25

# Initialize the starting page number
PAGE_NUM=1

# Loop until all results have been retrieved
while true; do
  # Get the next page of results
  PAGE_RESULTS=$(akash query cert list --owner $AKASH_ACCOUNT_ADDRESS --node http://rpc.akash.rocks:26657 --state valid --page $PAGE_NUM --limit $PAGE_SIZE -o json)

  # Check if there are no more results
  if [[ $(echo $PAGE_RESULTS | jq '.certificates | length') -eq 0 ]]; then
    break
  fi

  # Loop through the page results
  for CERT in $(echo "${PAGE_RESULTS}" | jq -r '.certificates[] | @base64'); do
    # Decode the certificate JSON
    CERT_JSON=$(echo ${CERT} | base64 --decode | jq -r '.')

    # Extract the certificate ID and domain
    CERT_ID=$(echo "${CERT_JSON}" | jq -r '.serial')

    # Do something with the certificate ID and domain
    echo "Certificate ID: ${CERT_ID}"
    ( sleep 2s; cat key-pass.txt; cat key-pass.txt ) | akash tx cert revoke server --from $AKASH_ACCOUNT_ADDRESS --serial $CERT_ID -y -b async
    exit
  done

  # Increment the page number
  PAGE_NUM=$((PAGE_NUM + 1))
done
