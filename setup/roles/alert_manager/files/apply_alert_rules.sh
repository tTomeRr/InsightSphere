#!/bin/bash

PROMETHEUS_HELM_CHART_NAME="prometheus"
HELM_CHART_REPO="prometheus-community/prometheus"
CUSTOM_RULE_CONFIG_PATH="generate_rule_file.yaml"


# Create an empty custom scrape configuration file
function create_custom_rule_file() {
        > "$CUSTOM_RULE_CONFIG_PATH"
	cat "groups:" >> generate_rule_file.yaml
}

function combine_rules_to_custome_rule_file() {
	for file in files/*.yml; do
        	if [ -f "$file" ]; then
        		cat "$file" >> "$CUSTOM_RULE_CONFIG_PATH"
        	fi
        done
}

# Upgrade the Prometheus Helm chart with custom configurations
function upgrade_helm_chart() {
        helm upgrade "$PROMETHEUS_HELM_CHART_NAME" "$HELM_CHART_REPO" \
                --reuse-values \
                --set-file serverFiles.alerting_rules.yml="$CUSTOM_RULE_CONFIG_PATH"
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

# Add all rules to a main yaml file
combine_rules_to_custome_rule_file

# Upgrade the Helm chart with the custom scrape configuration
upgrade_helm_chart &> /dev/null && echo "Helm Chart was succesfully updated!" || echo "ERROR: Failed to update Helm chart."


# Delete the temporary custom scrape configuration file
delete_custom_rule_file


# Restart Prometheus to apply the new configuration
killall -HUP prometheus

