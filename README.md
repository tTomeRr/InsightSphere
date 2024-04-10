## Insight Sphere - Monitoring Made Efforless

<img src="https://github.com/tTomeRr/InsightSphere/assets/129614080/8d0c46b5-e045-43b7-9526-6a157c689e23" 
    align="right" alt="InsightSphere" width="140" height="178">

About The Project:

By combining Grafana and Prometheus, this project aims to implement a robust monitoring solution for hosting environments. Grafana, a powerful data visualization and       monitoring platform, pairs seamlessly with Prometheus, a leading open-source toolkit designed for modern cloud-native environments. Together, they offer a comprehensive,   customizable, and reliable monitoring solution tailored to your hosting needs. This fusion enables you to proactively identify and address potential issues while ensuring  optimal performance and reliability.


## Built With:
* [<img src="https://github.com/prometheus/docs/raw/ca2961b495c3e2a1e4586899c26de692fa5a28e7/static/prometheus_logo_orange_circle.svg" width="30" height="30">](https://prometheus.io/) [Prometheus](https://prometheus.io/)
* [<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Grafana_icon.svg/32px-Grafana_icon.svg.png" width="30" height="30">](https://grafana.com/) [Grafana](https://grafana.com/)
* [<img src="https://www.pagerduty.com/favicon.ico" width="30" height="30">](https://www.pagerduty.com/) [PagerDuty](https://www.pagerduty.com/)
* [<img src="https://kubernetes.io/images/favicon.png" width="30" height="30">](https://kubernete.io/) [Kubernetes](https://kubernetes.io/)

## Project Architcture

![ProjectInsightSphere diagram)](https://github.com/tTomeRr/InsightSphere/assets/129614080/a61a33c8-ec47-4b5f-b5b5-58ccaa0ccdd9)





## Installation and Setup Instructions:

1. Clone the repository.

    `git clone https://github.com/tTomeRr/InsightSphere.git`

2. Navigate to the repository in your computer

3. Go to the setup directory.

    `cd setup`

4. Run the setup.yaml ansible playbook.

    `ansible-playbook setup.yml`

## Usage

1. **Cluster Configuration:**
   - After running the Ansible playbook, a cluster will be set up with the following pods:
     - Prometheus
     - Grafana
     - Alertmanager
     - Certmanager
     - Nginx
     - Metallb

2. **Accessing the Monitoring Interface:**
   - After deployment, access the following websites on your web browser:
     - [https://prometheus.insightsphere.com](https://prometheus.insightsphere.com)
     - [https://grafana.insightsphere.com](https://grafana.insightsphere.com)
     - [https://alertmanager.insightsphere.com](https://alertmanager.insightsphere.com)

2. **Exporters Configuration:**
   - Edit the `inventory.ini` file to specify the exporters you want to scrape data from.
   - For example, to enable Prometheus to scrape data from 'machine1' using the Node Exporter, add 'machine1' to the 'node_exporters' group in the inventory file.
     This configuration not only configures the Prometheus server but also download and set up the Node Exporter on 'machine1' for data collection.

3. **Grafana Password:**
   - Retrieve the Grafana server password by opening `grafana_password.yml` with Ansible Vault. The username is admin.


- **Note:** Modify configuration values in the `values.yml` file if needed (optional).


## Contributing

The open source community thrives on contributions, fostering an environment of learning, inspiration, and creativity. Your input is highly valued and appreciated.

Should you have any suggestions for improvement, feel free to fork the repository and initiate a pull request. Alternatively, you can open an issue labeled "enhancement".  Don't hesitate to show your support by starring the project. Thank you once more!

1. Fork the Project
2. Create your Feature Branch (git checkout -b feature/AmazingFeature)
3. Commit your Changes (git commit -m 'Add some AmazingFeature')
4. Push to the Branch (git push origin feature/AmazingFeature)
5. Open a Pull Request


## License

Distributed under the MIT License. See `LICENSE.txt` for more information.


## Acknowledgments

Resources we find useful and would like to give credit to:

- [prometheus-community/helm-charts](https://github.com/prometheus-community/helm-charts)
- [grafana/helm-charts](https://github.com/grafana/helm-charts)
- [prometheus/snmp_exporter](https://github.com/prometheus/snmp_exporter)
- [Using Prometheus with SNMP Exporter to Monitor Cisco IOS XR, Nokia SR OS, and Arista EOS Network Devices](https://karneliuk.com/2023/01/tools-12-using-prometheus-with-snmp-exporter-to-monitor-cisco-ios-xr-nokia-sr-os-and-arista-eos-network-devices/)
- [cert-manager Documentation: Using Prometheus Metrics](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/)
- [Prometheus Alerts Using Prometheus Community Helm Chart](https://home.robusta.dev/blog/prometheus-alerts-using-prometheus-community-helm-chart)
- [Prometheus Monitoring and Alerting with OpsRamp](https://www.opsramp.com/guides/prometheus-monitoring/prometheus-alerting/)
- [Create a Grafana Dashboard for StorageGRID](https://docs.netapp.com/us-en/storagegrid-enable/tools-apps-guides/federate-prometheus.html#create-a-grafana-dashboard-for-storagegrid)
      
