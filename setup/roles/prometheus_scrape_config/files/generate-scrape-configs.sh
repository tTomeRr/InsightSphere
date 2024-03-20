#!/bin/bash


# Initialize paths to required files
INVENTORY_FILE_PATH="inventory.ini"
READ_INI_SCRIPT_PATH="roles/prometheus_scrape_config/files/read-ini.sh"
CUSTOM_SCRAPE_CONFIG_PATH="generate_scrape_file.yaml"
PROMETHEUS_HELM_CHART_NAME="prometheus"
HELM_CHART_REPO="prometheus-community/prometheus"


# Check if the inventory file exists
if [ ! -f "$INVENTORY_FILE_PATH" ]; then
	echo "Inventory file '$INVENTORY_FILE_PATH' not found."
	exit 1
fi


# Check if the read-ini script exists
if [ ! -f "$READ_INI_SCRIPT_PATH" ]; then
	echo "Read-ini script '$READ_INI_SCRIPT_PATH' not found. "
	exit 1
fi

# Check if the Prometheus Helm chart exists
if ! helm list --short | grep -q "$PROMETHEUS_HELM_CHART_NAME"; then 
	echo "Prometheus Helm Chart '$PROMETHEUS_HELM_CHART_NAME' not found. "
	exit 1
fi


# Create an empty custom scrape configuration file
function create_custom_scrape_file() {
	> "$CUSTOM_SCRAPE_CONFIG_PATH"
}


# Upgrade the Prometheus Helm chart with custom configurations
function upgrade_helm_chart() {
	helm upgrade --install "$PROMETHEUS_HELM_CHART_NAME" "$HELM_CHART_REPO" \
		--set alertmanager.enabled=false \
		--set prometheus-node-exporter.enabled=false \
		--set prometheus-pushgateway.enabled=false \
		--set kube-state-metrics.enabled=false \
		--set-file extraScrapeConfigs="$CUSTOM_SCRAPE_CONFIG_PATH"
}


# Delete the custom scrape configuration file
function delete_custom_scrape_file() {
	[ -f "$CUSTOM_SCRAPE_CONFIG_PATH" ] && rm "$CUSTOM_SCRAPE_CONFIG_PATH"
}


# Check if the machine can ping the specified client
function check_connection_to_client() {
	client="$1"
	group="$2"

	ansible -m ping "$group" --limit "$client" &> /dev/null && return 0 || return 1
}


# Add a client to the custom scrape configuration based on its group
function add_client_to_configuration() {
	client="$1"
	group="$2"

	case "$group" in
		node_exporters)
			add_node_exporter "$client"
			;;
		kubernetes)
			add_kubernetes_exporter "$client"
			;;
		network)
			add_network_exporter "$client"
			;;
		storage)
			add_storage_exporter "$client"
			;;
		proxmox)
			add_proxmox_exporter "$client"
			;;
	esac
}


###########
# Functions to configure Prometheus to scrape data from various clients
###########


function add_node_exporter() {
	client="$1"

	cat <<EOF >> "$CUSTOM_SCRAPE_CONFIG_PATH"
- job_name: 'Node Exporter: $client'
  static_configs:
  - targets: ['$client:9100']
EOF
}


function add_proxmox_exporter() {
	client="$1"

	cat <<EOF >> "$CUSTOM_SCRAPE_CONFIG_PATH"
- job_name: 'Proxmox VE: $client'
  static_configs:
  - targets: ['$client:9221']
EOF
}


function add_network_exporter() {
	client="$1"

	cat <<EOF >> "$CUSTOM_SCRAPE_CONFIG_PATH"
- job_name: 'SNMP Network Device: $client'
  metrics_path: /snmp
  static_configs:
    - targets: ['$client:161']
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: 'snmp-exporter.example.com:9116'
EOF
}

function add_proxmox_exporter() {
	client="$1"

	cat <<EOF >> "$CUSTOM_SCRAPE_CONFIG_PATH"
- job_name: 'NetApp Storage $client'
  static_configs:
  - targets: ['$client:9280']

EOF
}

function add_kubernetes_exporter() {
	client="$1"

	cat <<EOF >> "$CUSTOM_SCRAPE_CONFIG_PATH"

- job_name: 'kube-state-metrics $client'
  static_configs:
  - targets: ['$client:8080']
EOF
}


###########
# Main script execution starts here
###########


# Create the custom scraping configuration file
create_custom_scrape_file


# Iterate over each group and client, check connectivity, and add to scrape configuration if reachable
for group in node_exporters kubernetes network storage proxmox; do
	for client in $(./"$READ_INI_SCRIPT_PATH" "$INVENTORY_FILE_PATH" "$group"); do
		if check_connection_to_client "$client" "$group"; then
			echo "Ping to $client was successful. Adding it to the Prometheus scrape configuration."
			add_client_to_configuration "$client" "$group"
		else
			echo "Unable to ping $client. Skipping."
		fi

	done
done


# Upgrade the Helm chart with the custom scrape configuration
upgrade_helm_chart &> /dev/null && echo "Helm Chart was succesfully updated!" || echo "ERROR: Failed to update Helm chart."


# Delete the temporary custom scrape configuration file
delete_custom_scrape_file


# Restart Prometheus to apply the new configuration
killall -HUP prometheus

