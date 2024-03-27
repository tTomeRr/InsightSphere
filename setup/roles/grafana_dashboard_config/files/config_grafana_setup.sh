#!/bin/bash


# Initialize paths to required files
CUSTOM_GRAFANA_CONFIG_FILE="generate_grafana_configuration.yaml"
GRAFANA_HELM_CHART_NAME="grafana"
HELM_CHART_REPO="grafana/grafana"

# Create a dictionary that will hold the exporters dashboards values
# [id/file, Dashboard name, Dashboard path/ID, Dashboard revision]
declare -A dashboards
dashboards[node_exporter_arr]='id node_exporter_full 1860 36'
dashboards[network_arr]='id network_full 12197 1'
dashboards[storage_arr]='id storage_full 5119 1'
dashboards[kubernetes_arr]='file kubernetes_full roles/grafana_dashboard_config/files/kubernetes_dashboard.json'
dashboards[proxmox_arr]='id proxmox_full 10347 5'

# Check if the Grafana Helm chart exists
if ! helm list --short | grep -q "$GRAFANA_HELM_CHART_NAME"; then
	echo "Grafana Helm Chart '$GRAFANA_HELM_CHART_NAME' not found. "
	exit 1
fi

# Create an empty custom configuration file
function create_custom_configuration_file() {
	> "$CUSTOM_GRAFANA_CONFIG_FILE"
	cat << EOF >> "$CUSTOM_GRAFANA_CONFIG_FILE" 
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default
      orgId: 1
      type: file
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - access: proxy
      name: Prometheus
      orgId: 1
      type: prometheus
      url: https://prometheus.insightsphere.com
      jsonData:
        tlsSkipVerify: true
dashboards:
  default:
EOF
}


# Upgrade the Grafana Helm chart with the custom configurations
function upgrade_helm_chart() {
	helm upgrade "$GRAFANA_HELM_CHART_NAME" "$HELM_CHART_REPO" \
		-f "$CUSTOM_GRAFANA_CONFIG_FILE"
	}


# Delete the custom configuration file
function delete_custom_configuration_file() {
	[ -f "$CUSTOM_GRAFANA_CONFIG_FILE" ] && rm "$CUSTOM_GRAFANA_CONFIG_FILE"
}


# Add the custom dashboard configuration via ID
function add_custom_dashboard_id() {
	dashboard_name=$1
	dashboard_id=$2
	dashboard_revision=$3
	cat << EOF >> "$CUSTOM_GRAFANA_CONFIG_FILE"
    $dashboard_name:
      gnetId: $dashboard_id
      revision: $dashboard_revision	
EOF
}

# Add the custom dashboard configuration via custom file
function add_custom_dashboard_file() {
	dashboard_name=$1
	dashboard_file_path=$2

	if [ ! -e $dashboard_file_path ]; then
		return
	fi

	cat << EOF >> "$CUSTOM_GRAFANA_CONFIG_FILE"
    $dashboard_name:
      json: | 
	$(dashboard_file_path)
EOF

}

###########
# Main script execution starts here
###########


# Create the custom configuration setup file
create_custom_configuration_file

# Iterate over the dashboards dictionary and add each dashboard to the configuration file
for dashboard in "${!dashboards[@]}"; do
    IFS=' ' read -r -a dashboard_info <<< "${dashboards[$dashboard]}"
    dashboard_type=${dashboard_info[0]}
    dashboard_name=${dashboard_info[1]}
    dashboard_id=${dashboard_info[2]}
    dashboard_revision=${dashboard_info[3]}

    if [ "$dashboard_type" == "id" ]; then
    	add_custom_dashboard_id "$dashboard_name" "$dashboard_id" "$dashboard_revision"

    elif [ "$dashboard_type" == "file" ]; then
        add_custom_dashboard_file "$dashboard_name" "$dashboard_id"
    fi
done

# Upgrade the Helm chart with the custom configuration configuration
upgrade_helm_chart &> /dev/null && echo "Helm Chart was succesfully updated!" || echo "ERROR: Failed to update Helm chart."


# Delete the temporary custom configuration configuration file
delete_custom_configuration_file

