#!/bin/bash


# Initialize paths to required files
CUSTOM_GRAFANA_CONFIG_FILE="generate_grafana_configuration.yaml"
GRAFANA_HELM_CHART_NAME="grafana"
HELM_CHART_REPO="grafana/grafana"


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
      url: http://prometheus.insightsphere.com
dashboards:
  default:
EOF
}


# Upgrade the Grafana Helm chart with the custom configurations
function upgrade_helm_chart() {
	helm upgrade "$GRAFANA_HELM_CHART_NAME" "$HELM_CHART_REPO" \
		-f $CUSTOM_GRAFANA_CONFIG_FILE
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
	dashboard_revision=$3

}

###########
# Main script execution starts here
###########


# Create the custom scraping configuration file
create_custom_configuration_file


add_custom_dashboard_id "node-exporter-dashboard" "1860" "36"

# Upgrade the Helm chart with the custom configuration configuration
upgrade_helm_chart &> /dev/null && echo "Helm Chart was succesfully updated!" || echo "ERROR: Failed to update Helm chart."


# Delete the temporary custom configuration configuration file
delete_custom_configuration_file

