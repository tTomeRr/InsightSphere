#!/bin/bash -x 

PROMETHEUS_HELM_CHART_NAME="prometheus"
HELM_CHART_REPO="prometheus-community/prometheus"
ALERTING_RULES=$(for file in roles/alert_manager/files/*.yml; do cat "$file"; echo; done)
CUSTOM_RULE_CONFIG_PATH="alerting_rules.yml"

# Create an empty custom scrape configuration file
function create_custom_rule_file() {
	cat <<EOF > $CUSTOM_RULE_CONFIG_PATH
alertmanager:
  enable: true
  config:
    groups:
$(echo "$ALERTING_RULES" | sed 's/^/    /')
EOF
}


# Upgrade the Prometheus Helm chart with custom configurations
function upgrade_helm_chart() {
        helm upgrade "$PROMETHEUS_HELM_CHART_NAME" "$HELM_CHART_REPO" \
                --reuse-values \
                -f "$CUSTOM_RULE_CONFIG_PATH"
}

# Delete the custom scrape configuration file
function delete_custom_rule_file() {
        [ -f "$CUSTOM_RULE_CONFIG_PATH" ] && rm "$CUSTOM_RULE_CONFIG_PATH"
}

###########
# Main script execution starts here
###########

# Create the custom scraping configuration file
create_custom_rule_file


# Upgrade the Helm chart with the custom scrape configuration
upgrade_helm_chart && echo "Helm Chart was succesfully updated!" || echo "ERROR: Failed to update Helm chart."


# Delete the temporary custom scrape configuration file
delete_custom_rule_file



