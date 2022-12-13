# Ansible-Terraform Kubernetes cluster set up on Azure

Ansible Terraform to set up a 3 node Kubernetes cluster on Azure.

## Getting started

### Prerequisites

- [Authenticate account on Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure)

### Installation

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Deployment

Use Terraform to deploy required resources with

```bash
terraform plan
terraform apply
```

Use node public IP output to create /inventory/hosts.ini file

```
[controller-server]
<controller-0-ip>

[worker-servers]
<worker-0-ip>
<worker-1-ip>
```

Set up nodes with Ansible with playbooks in order

```
ansible-playbooks <playbook> -i <path-to-hosts.ini>
```

Follow kubeadm guide from [kubernetes.io](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)

- kubeadm init on controller node
- join worker nodes
- install CNI on all nodes

## Acknowledgements

- [Kubernetes The Hard Way on Azure](https://github.com/ivanfioravanti/kubernetes-the-hard-way-on-azure) by [Kelsey Hightower](https://github.com/kelseyhightower)
