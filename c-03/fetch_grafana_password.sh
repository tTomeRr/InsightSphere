#!/bin/bash

# Fetch the Grafana password from the Helm Chart and save it in an Ansible Vault

# Set the namespace where Grafana is installed
NAMESPACE="monitoring"

# Fetch the values for all releases in the specified namespace
VALUES=$(helm get values -n $NAMESPACE)

# Extract the Grafana password from the values
GRAFANA_PASSWORD=$(echo "$VALUES" | grep -oP 'adminPassword:\s*\K.*')

# Save the Grafana password in an Ansible Vault
echo "$GRAFANA_PASSWORD" > grafana_password.txt
ansible-vault encrypt grafana_password.txt

# Remove the plaintext password file
rm grafana_password.txt

echo "Grafana password has been fetched and saved in the Ansible Vault."

