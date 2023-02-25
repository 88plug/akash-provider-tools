#!/bin/bash
PASSWORD="xxx"

echo $PASSWORD > key-pass.txt

# Get the list of valid certificates owned by the account
CERT_LIST=$(akash query cert list --owner $AKASH_ACCOUNT_ADDRESS --state valid -o json | jq '.certificates')

# Loop through the certificate list
for CERT in $(echo "${CERT_LIST}" | jq -r '.[] | @base64'); do
  # Decode the certificate JSON
  CERT_JSON=$(echo ${CERT} | base64 --decode | jq -r '.')

  # Extract the certificate ID and domain
  CERT_ID=$(echo "${CERT_JSON}" | jq -r '.serial')

  # Do something with the certificate ID and domain
  echo "Certificate ID: ${CERT_ID}"

  ( sleep 2s; cat key-pass.txt; cat key-pass.txt ) | akash tx cert revoke server --from $AKASH_ACCOUNT_ADDRESS --serial $CERT_ID -y -b async

done
