#!/bin/bash


# Initialize paths to required files
INVENTORY_FILE_PATH="../../../inventory.ini"
READ_INI_SCRIPT_PATH="read-ini.sh"
CUSTOM_SCRAPE_CONFIG_PATH="generate_scrape_file.yaml"


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


# Create an empty custom scrape configuration file
function create_custom_scrape_file() {
	> "$CUSTOM_SCRAPE_CONFIG_PATH"
}


# Upgrade the Prometheus Helm chart with custom configurations
function upgrade_helm_chart() {
	helm upgrade --install prometheus prometheus-community/prometheus \
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
	ping -q -c1 "$client" &>/dev/null && return 0 || return 1
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
			add_kubernetes "$client"
			;;
		network)
			add_network "$client"
			;;
		storage)
			add_storage "$client"
			;;
		proxmox)
			add_proxmox "$client"
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
      - targets:
        - $client:9221  # Proxmox VE node with PVE exporter.
        - $client:9221  # Proxmox VE node with PVE exporter.
    metrics_path: /pve
    params:
      module: [default]
      cluster: ['1']
      node: ['1']
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
		if check_connection_to_client "$client"; then
			add_client_to_configuration "$client" "$group"
		fi
	done
done


# Upgrade the Helm chart with the custom scrape configuration
upgrade_helm_chart


# Delete the temporary custom scrape configuration file
delete_custom_scrape_file


# Restart Prometheus to apply the new configuration
killall -HUP prometheus

# TODO: Add templates for network, storage, proxmox, kubernetes

