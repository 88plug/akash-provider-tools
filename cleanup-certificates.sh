#!/bin/bash

FEE=5000

# Set the number of results to retrieve per page
PAGE_SIZE=25

# Initialize the starting page number
PAGE_NUM=1

# Initialize the total certificate count
TOTAL_CERTS=0

# Loop until all results have been retrieved
while true; do
  # Get the next page of results
  PAGE_RESULTS=$(akash query cert list --owner $AKASH_ACCOUNT_ADDRESS --node http://rpc.akash.rocks:26657 --state valid --page $PAGE_NUM --limit $PAGE_SIZE -o json)

  # Check if there are no more results
  if [[ $(echo $PAGE_RESULTS | jq '.certificates | length') -eq 0 ]]; then
    break
  fi

  # Get the number of certificates in the current page
  PAGE_CERTS=$(echo "${PAGE_RESULTS}" | jq -r '.certificates | length')

  # Add the number of certificates in the current page to the total count
  TOTAL_CERTS=$((TOTAL_CERTS + PAGE_CERTS))

  # Increment the page number
  PAGE_NUM=$((PAGE_NUM + 1))
done

# Inform the user how many certificates will be deleted
echo "Found ${TOTAL_CERTS} active certificates. Deleting..."

# Reset the page number
PAGE_NUM=1

# Loop until all results have been retrieved
while true; do
  # Get the next page of results
  PAGE_RESULTS=$(akash query cert list --owner $AKASH_ACCOUNT_ADDRESS --node http://rpc.akash.rocks:26657 --state valid --page $PAGE_NUM --limit $PAGE_SIZE -o json)

  # Check if there are no more results
  if [[ $(echo $PAGE_RESULTS | jq '.certificates | length') -eq 0 ]]; then
    break
  fi

  # Loop through the page results and delete the certificates
  for CERT in $(echo "${PAGE_RESULTS}" | jq -r '.certificates[] | @base64'); do
    # Decode the certificate JSON
    CERT_JSON=$(echo ${CERT} | base64 --decode | jq -r '.')

    # Extract the certificate ID and domain
    CERT_ID=$(echo "${CERT_JSON}" | jq -r '.serial')

    # Delete the certificate
#    ( sleep 2s; cat key-pass.txt; cat key-pass.txt ) | akash tx cert revoke server --from $AKASH_ACCOUNT_ADDRESS --serial $CERT_ID -y -b block >/dev/null 2>&1
    # Delete the certificate
    echo "Deleting certificate with ID: ${CERT_ID}"
    while true; do
      RESPONSE=$({ sleep 2s; cat key-pass.txt; cat key-pass.txt; } | akash tx cert revoke server --from $AKASH_ACCOUNT_ADDRESS --serial $CERT_ID --fees ${FEE}uakt -y -b sync 2>&1)

      if echo "$RESPONSE" | grep -q "incorrect account sequence"; then
        echo "Retry due to incorrect account sequence error"
        continue
      elif echo "$RESPONSE" | grep -q "txhash"; then
        echo "Certificate with ID ${CERT_ID} successfully deleted"
        break
      else
        echo "Error deleting certificate with ID ${CERT_ID}"
        echo "$RESPONSE"
        exit 1
      fi
    done

    # Increment the total certificate count
    TOTAL_CERTS=$((TOTAL_CERTS - 1))

    # Print progress
    echo "${TOTAL_CERTS} active certificates remaining"
  done

  # Increment the page number
  PAGE_NUM=$((PAGE_NUM + 1))
done

# Print the final message
echo "Deleted all active certificates"
