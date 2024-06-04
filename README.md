# gitOps LCM of 5G k8s Infra

## Tools used

- Windows Subsystem for Linux (WSL)
- Version control system git
- Terraform
- Ansible
- Docker
- Kubernetes
- Flux CD gitops tool

## Deployment/ Installation Guide

## Pre-requisities

- Windows Subsystem for Linux (WSL) installed
- Visual Studio Code and extension packs are installed and configured for the Ansible development environment.
- python3 python3-venv python3-ldap installed
- pip3 installed
- In the Python virtual environment, the required packages are installed
- Terraform installed
- Target cloud OR/AND on-premises infrastructures configured for access from WSL in order to use Terrafom
- WSL Linux configured with git
- Generated git PAT available to use

## Infrastructure as Code (IaC) : Terraform

![IaC-design](./resources/IaC.png)
*Figure 1 : IaC using Terraform*

> IaC, CaC, and other refferences of source code -

- Clone this repo [gitops-poc ](https://github.com/gitops-lcm/gitops-poc.git)

**1.** Using WSL ``terminal`` navigate to the project root directory -

> Initialize Terraform in the directory -

```
terraform init
```

> To ``create`` using terraform commands -

```
terraform validate
```

```
terraform plan
```

```
terraform apply
```

> A successful ``create`` will have output with all VMs IP addresses.

> To ``destroy`` using terraform commands -

```
terraform destroy
```

## Configuration as Code (CaC) : Ansible

![CaC-design](./resources/CaC.png)
*Figure 2 : CaC using Ansible*

**2.** Connect all VMs using SSH to prepare for Ansible configuration access - 

```
ssh ssh-user@<ip address of VM>
```

> **Important:** Update ``ansible_host`` of ansible ``inventory`` file with target VMs IP addresses.

**3.** To prepare and configure k8s cluster - 

>**Important:** Run below Ansible commands from activated python virtual environment which having all required packages installed. (ref: ``requirements.txt``)
```
ansible-playbook k8s_playbook.yaml
```
**4.** To prepare and configure flux ops - 
```
ansible-playbook ops_playbook.yaml
```
**5.** To configure notification and alert - 
```
ansible-playbook notify_playbook.yaml
```

## gitOps in practice (gotk) : Flux CD

![gitOps-design](./resources/gitOps.png)
*Figure 3 : gitOps using Flux gtok*

> Flux systems repo created by flux during previous configuration phase -
  
- Clone the repo [flux-infra ](https://github.com/gitops-lcm/flux-infra.git)

> Copy ``monitoring`` folder from ``gitops-poc/resources/monitoring`` to ``flux-infra/``. Monitoring folder content open source monitoring tools of prometheus & grafana stack helm deployments. 

```
cp -r ~/gitops-poc/resources/monitoring ~/flux-infra
```

> Copy flux operator related CRDs ``monitoring.yaml``, ``slack_alert_provider.yaml`` ,``slack_alert.yaml``, and ``xyz_git_src.yaml`` files from ``gitops-poc/resources/crds/fluxops``to ``flux-infra/clusters/ops/`` . Push locally updated ``flux-infra`` with ops CRDs to ``main`` branch of remote git repository. 

```
git add .
```

```
git commit -m "updated flux ops crds"
```

```
git push origin main
```

> Similarly place all your deployment CRDs at ``flux-infra/clusters/ops/`` and push locally updated ``flux-infra`` with deployment CRDs to ``main`` branch of remote git repository.

```
cp ~/gitops-poc/resources/crds/deploy/* ~/flux-infra/clusters/ops/
```

```
git add .
```

```
git commit -m "updated deployment crds"
```

```
git push origin main
```

> ``patch``  required services / deployments.

To ``patch`` **kube-prometheus-stack-grafana** services for dashboard access -

```
ansible-playbook patch_playbook.yaml
```