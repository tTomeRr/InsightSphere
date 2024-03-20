# Set the namespace where Grafana is installed
GRAFANA_HELM="grafana"

# Fetch the admin-password from the secret in the specified namespace
GRAFANA_PASSWORD=$(kubectl get secret "$GRAFANA_HELM" -o jsonpath='{.data.admin-password}' | base64 --decode)

# Save the Grafana password in an Ansible Vault
echo "$GRAFANA_PASSWORD" > grafana_password.txt
ansible-vault encrypt grafana_password.txt

echo "Grafana password has been fetched and saved in the Ansible Vault."

