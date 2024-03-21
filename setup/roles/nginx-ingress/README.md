Ansible Task: Manage Nginx Ingress Installation

- Install Kubernetes Python library.
- Check existence of /tmp/nginx-ingress directory.
- Check if Nginx Ingress is installed.
- Pull Nginx Ingress Helm chart if directory does not exist.
- Apply CRDs for Nginx Ingress if Helm chart not installed.
- Install Nginx Ingress using Helm if not installed.
- Clean up nginx-ingress folder.

