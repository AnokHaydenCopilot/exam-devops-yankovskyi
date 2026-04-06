# DevOps Exam - Vitalii Yankovskyi

This repository contains the completed tasks for the DevOps Part 2 Exam.

## Task 1: Infrastructure Provisioning (Terraform)
- **Files**: `task1/main.tf`
- **CI/CD**: `.github/workflows/task1-apply.yml`, `.github/workflows/task1-destroy.yml`
- **Result**: Provisions AWS VPC (`10.10.10.0/24`), subnet, IGW, route table, security group (ports 22, 80, 443, 8000-8003), `t3.medium` EC2 instance running Ubuntu 24.04, and the exam bucket.
- **State**: Terraform state is stored in the remote S3 backend `yankovskyi-terraform-state-exam/state/terraform.tfstate`. The workflow bootstraps the bucket before `terraform init`.
- **SSH**: The CI generates the SSH key pair, stores the private key in AWS Secrets Manager, and passes only the public key to Terraform.

## Task 2: VM Configuration (Ansible)
- **Files**: `task2/setup.yml`, `task2/inventory.ini.tpl`
- **CI/CD**: `.github/workflows/task2-ansible.yml`
- **Result**: Installs Docker, Minikube, kubectl, Helm, and supporting dependencies on the provisioned EC2 instance. The workflow loads the SSH private key from AWS Secrets Manager, builds `inventory.ini` dynamically from the provided server IP, and runs syntax plus `--check` validation before the real playbook.

## Task 3: Application Deployment (CI/CD to Minikube)
- **Files**: `task3/deployment.yaml`
- **CI/CD**: `.github/workflows/task3-deploy.yml`
- **Result**: Pipeline builds a Docker image from the [devops-exam-pt2](https://github.com/YulianSalo/devops-exam-pt2) repository, pushes it to GHCR, and deploys it to the remote EC2 Minikube cluster using Kubernetes manifests.
  - `dev` builds from `develop` and is exposed on port 8002.
  - `release` builds from tag `1.0.0` and is exposed on port 8003.
  - Deployment is validated with a remote `kubectl --dry-run=client` before apply, then verified with `curl` against the published port.

---
### Requirements Addressed
- [x] S3 backend logic with remote tfstate
- [x] Pre-flight pipeline checks (terraform plan, ansible check, kubectl dry-run)
- [x] Secrets kept out of the repository and stored in AWS Secrets Manager
- [x] Port proxying and dedicated configurations for dev/release node ports
- [x] Automated tear-down (destroy pipeline)
- [x] CI-generated SSH key pair

### How to run
1. Ensure GitHub Actions secrets are set: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
2. Run `Task 1 - Terraform Infrastructure` from GitHub Actions. This creates the state bucket if needed, generates the SSH key material, and provisions the AWS resources.
3. Copy the EC2 public IP from the workflow output.
4. Run `Task 2 - Ansible Setup` with that IP.
5. Run `Task 3 - Deploy App` with the same IP and choose `dev` or `release`.
6. Validate the deployment with `curl http://<EC2_PUBLIC_IP>:8002` for `dev` or `curl http://<EC2_PUBLIC_IP>:8003` for `release`.

### State note
Terraform does not create the S3 backend bucket automatically just because the backend block exists. `terraform init` checks whether the bucket exists and is reachable before planning or applying. The workflow bootstraps the bucket first, and the actual state lives in S3 under `state/terraform.tfstate`.
