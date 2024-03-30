#!/bin/bash

exporter_type="$1"

if [ $# -ne 1 ]; then
	echo "ERROR: No argument provided."
	exit 1
fi

#Exit Code 0: Success.
#Exit Code 1: Invalid exporter type or unsupported type in download function.
#Exit Code 2: Failed to download the exporter package.
#Exit Code 3: Exporter failed to start or is not running as expected.
#Exit Code 4: kubectl or helm is not installed.


function add_exporter_user() {
	# Check if user already exists
	if id "$exporter_type" &>/dev/null; then
		echo "User $exporter_type already exists, skipping user creation."
	else
		# Add user named after the exporter type
		useradd -M -r -s /bin/false "$exporter_type"
	fi
}


function download_exporter_package() {
	url=""
	echo $exporter_type
	case "$exporter_type" in
		"node_exporter")
			url="https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz"
			;;
		"snmp_exporter")
			url="https://github.com/prometheus/snmp_exporter/releases/download/v0.25.0/snmp_exporter-0.25.0.linux-amd64.tar.gz"
			;;
		*)
			exit 1
			;;
	esac

	wget -q -O "${exporter_type}-stable.tar.gz" "$url"
}

function validate_exporter_package_download() {
	if [ $? -ne 0 ]; then
		echo "ERROR: Failed to download the exporter latest version from GitHub (exit code $?). Check internet connection and try again."
		exit 2
	else
		echo "Successfully downloaded the exporter latest version from GitHub!"

	# Extracting the compressed archive and saving version number as variable
	tar xvfz "${exporter_type}-stable.tar.gz"
	fi
}
function add_node_exporter_service(){

	# Create a systemd unit file for the node_exporter and define the Node Exporter service in the unit file:
	cat <<EOF > /etc/systemd/system/${exporter_type}.service
[Unit]
Description=Prometheus Node Exporter Service
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
}


function add_snmp_exporter_service(){

	# Create a systemd unit file for the snmp_exporter and define the SNMP Exporter service in the unit file:
	cat <<EOF > /etc/systemd/system/${exporter_type}.service
[Unit]
Description=Prometheus SNMP Exporter Service
After=network.target

[Service]
Type=simple
User=snmp_exporter
Group=snmp_exporter
ExecStart=/usr/local/bin/snmp_exporter --config.file="/usr/local/bin/snmp.yml"

[Install]
WantedBy=multi-user.target
EOF
}

function check_current_exporter_version() {
	# Saving the stable version of the exporter and the version that is running if there is any.
	stable_ver_downloaded=$(ls -d ${exporter_type}-*/ | head -n 1 | awk -F'[-.]' '{print $2 "." $3 "." $4}')
	ver_running=$(/usr/local/bin/${exporter_type} --version 2>&1 | grep 'version' | head -n 1 | awk '{print $3}')

    # Returns true if there is a new stable version
    [ "$stable_ver_downloaded" != "$ver_running" ] && return 0 || return 1
}

function update_exporter_version() {
	# Copy the Exporter binary to the appropriate location and set ownership:
	cp -f ${exporter_type}*.linux-amd64/${exporter_type} /usr/local/bin/
	chown $exporter_type:$exporter_type /usr/local/bin/$exporter_type
}

function update_snmp_exporter_version() {
	# Copy configuration file 'snmp.yml', file that configures SNMP targets and metrics
	# for monitoring with the snmp_exporter, also set ownership:
	cp -f ${exporter_type}*.linux-amd64/snmp.yml /usr/local/bin/
	chown $exporter_type:$exporter_type /usr/local/bin/snmp.yml
}

function start_service() {
	# Reload system configuration if service is already installed
	systemctl daemon-reload

	# Start and enable the ${exporter_type} service:
	systemctl enable --now ${exporter_type}.service
}

function cleanup() {
	# Cleanup files downloaded and extracted
	rm -rf ${exporter_type}-stable.tar.gz ${exporter_type}-stable ${exporter_type}*.linux-amd64
}

function check_exporter_up(){

	retries=20

	if [ "$exporter_type" == "node_exporter" ]; then
		port=9100
	elif [ "$exporter_type" == "snmp_exporter" ]; then
		port=9116
	fi

	while [ $retries -gt 0 ]; do

		# curl the exporter ip and port and grab the http response to check the exporter is up and running

		response_code=$(curl -s -o /dev/null -w "%{http_code}" "localhost:$port")

		# If up and running, send success message, if failed also send message and exit with failure
		if [ "$response_code" -eq 200 ]; then
			echo "${exporter_type} successfully created and is up and running as a service!"
			break
		elif [ $retries -eq 1 ]; then
			echo "ERROR: ${exporter_type} run into a problem. please check configuration and try again."
			exit 3
		fi
		((retries--))
		sleep 2
	done
}


# Check if Kubectl is installed.
function check_kubectl_install() {
	if [ ! -x "$(command -v kubectl)" ]; then
		"ERROR: Could not download Kubernetes exporter because kubectl or helm is not installed on target machine."
		exit 4
	fi
}

# Check if Helm is installed.
function check_helm_installed() {
	if [ ! -x "$(command -v helm)" ]; then
		"ERROR: Could not download Kubernetes exporter because kubectl or helm is not installed on target machine."
		exit 4
	fi
}

function install_kubernetes_exporter(){
	# Add Prometheus Community Helm repository
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	echo "Updating help repo."
	# Update Helm repositories
	helm repo update
	echo "Install kube-statemerics."
	# Check if kube-state-metrics is already installed
	if helm status kube-state-metrics -n kube-system >/dev/null 2>&1; then
		echo "kube-state-metrics is already installed."
	else
		# Install kube-state-metrics chart in kube-system namespace
		helm install kube-state-metrics prometheus-community/kube-state-metrics -n kube-system
		echo "kube-state-metrics installed successfully."
	fi
	# Set up port forwarding for kube-state-metrics service in the background
	nohup kubectl port-forward svc/kube-state-metrics -n kube-system 8080:8080 --address 0.0.0.0 >/dev/null 2>&1 &
	echo "Port forwarding for kube-state-metrics is running in the background."
}


function install_exporter() {
	exporter_type="$1"

	case "$exporter_type" in
		node_exporter)
			add_exporter_user
			download_exporter_package
			validate_exporter_package_download
			if check_current_exporter_version; then
				update_exporter_version
			fi
			add_node_exporter_service
			start_service
			check_exporter_up
			cleanup
			;;
		kubernetes)
			check_kubectl_install
			check_helm_installed
			install_kubernetes_exporter
			;;
		network | snmp_exporter)
			exporter_type="snmp_exporter"
			add_exporter_user
			download_exporter_package
			validate_exporter_package_download
			if check_current_exporter_version; then
				update_exporter_version
				update_snmp_exporter_version
			fi
			add_snmp_exporter_service
			start_service
			check_exporter_up
			cleanup
			;;
		storage)
			echo "ERROR: Storage exporter installation not implemented yet."
			;;
		proxmox)
			echo "ERROR: Proxmox exporter installation not implemented yet."
			;;
		*)
			echo "ERROR: Invalid exporter type: $exporter_type"
			exit 1
			;;
	esac
}


if [[ " node_exporter snmp_exporter kubernetes proxmox storage network " == *" $exporter_type "* ]]; then
	install_exporter $exporter_type
	echo "SUCCESS. Exporter was downloaded successfully."
	exit 0
else
	echo "ERROR: Invalid exporter type: $exporter_type"
	exit 1
fi
