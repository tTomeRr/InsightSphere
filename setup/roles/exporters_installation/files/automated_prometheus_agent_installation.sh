#!/bin/bash

exporter_type="$1"
service_already_up=false
# Add user named after the exporter type
useradd -M -r -s /bin/false $exporter_type


# Download the exporter latest version from GitHub
if [ "$exporter_type" == "node_exporter" ]; then
	wget -O ${exporter_type}-stable.tar.gz "https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz"
else
	wget -O ${exporter_type}-stable.tar.gz "https://github.com/prometheus/snmp_exporter/releases/download/v0.25.0/snmp_exporter-0.25.0.linux-amd64.tar.gz"
fi

# Check if exporter downloaded successfully from github
if [ $? -ne 0  ]; then
	echo "Failed to download the exporter latest version from GitHub (exit code $?) . Check internet connection and try again."
	exit 1
else
	echo "Successfully downloaded the exporter latest version from GitHub!"
fi

# Extracting the compressed archive and saving version number as variable
tar xvfz ${exporter_type}-stable.tar.gz 

# Saving the stable version of the exporter and the version that is runnig if there is any. 
stable_ver_downloaded=$(ls -d ${exporter_type}-*/ | head -n 1 | awk -F'[-.]' '{print $2 "." $3 "." $4}')
ver_running=$(${exporter_type} --version 2>&1 | grep 'version' | head -n -1  | awk '{print $3}')

# Only starting change if the version running is the same as version downloaded
if [ ! "$stable_ver_downloaded" == "$ver_running" ]; then
	# Copy the Exporter binary to the appropriate location and set ownership:
	cp -rf ${exporter_type}*.linux-amd64/${exporter_type} /usr/local/bin/
	chown $exporter_type:$exporter_type  /usr/local/bin/$exporter_type

	if [ "$exporter_type" == "node_exporter" ] && [ ! -e "/etc/systemd/system/${exporter_type}.service"  ] ; then

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



	elif [ "$exporter_type" == "snmp_exporter" ] && [ ! -e "/etc/systemd/system/${exporter_type}.service"  ]; then


	       # Copy configuration file 'snmp.yaml', file that configures SNMP targets and metrics for monitoring with the snmp_exporter, also set ownership:
		cp -f ${exporter_type}*.linux-amd64/snmp.yml /usr/local/bin/
		chown $exporter_type:$exporter_type  /usr/local/bin/snmp.yml

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


	fi
else
	echo "Service is already up and running at the latest version"
	service_already_up=true

fi

# Reload system configuration if service is already installed
if [ ! $service_already_up ]; then
	systemctl daemon-reload
fi

# Start and enable the $(exporter_type) service:
systemctl enable --now ${exporter_type}.service
if [ "$exporter_type" == "kubernetes" ]
        # Add Prometheus Community Helm repository
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        echo "Updating help repo."
        # Update Helm repositories
        helm repo update
        echo "Install kube-statemerics."
        # Install kube-state-metrics chart in kube-system namespace
        helm install kube-state-metrics prometheus-community/kube-state-metrics -n kube-system
        # Set up port forwarding for kube-state-metrics service in the background
        nohup kubectl port-forward svc/kube-state-metrics -n kube-system 8080:8080 --address 0.0.0.0 > /dev/null 2>&1 &
        # Optionally, you can add a sleep command to give some time for the port forwarding to start
        sleep 5

        # Print a message indicating that port forwarding is running in the background
        echo "Port forwarding for kube-state-metrics is running in the background."
fi
int1=20
while [ $int1 -gt 0 ]; do

	# curl the exporter ip and port and grab the http response to check the exporter is up and running
	if [ "$exporter_type" == "node_exporter" ]; then
		
		response_code=$(curl -s -o /dev/null -w "%{http_code}" "localhost:9100")
	elif [ "$exporter_type" == "snmp_exporter" ]; then

		response_code=$(curl -s -o /dev/null -w "%{http_code}" "localhost:9116")
	fi

	# If up and running, send success message, if failed also send message and exit with failure

	if [ "$response_code" -eq 200 ]; then

                echo "${exporter_type} successfully created and is up and running as a service!"
		break
	elif [ $int1 -eq 1 ]; then

		echo "${exporter_type} run into a problem. please check configuration and try again."
		exit 2
	fi
	((int1--))
	sleep 2

done


# Cleanup files downloaded and extracted
  rm -rf ${exporter_type}-stable.tar.gz ${exporter_type}-stable ${exporter_type}*.linux-amd64
