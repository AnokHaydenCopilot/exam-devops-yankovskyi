# DevOps Exam - Vitalii Yankovskyi

This repository contains the completed tasks for the DevOps Part 2 Exam.

## Task 1: Infrastructure Provisioning (Terraform)
- **Files**: `task1/main.tf`
- **CI/CD**: `.github/workflows/task1-apply.yml`, `.github/workflows/task1-destroy.yml`
- **Result**: Provisions AWS VPC (`10.10.10.0/24`), Subnet, IGW, Route Table, Security Group (ports 22, 80, 443, 8000-8003), and `t3.medium` EC2 instance running Ubuntu 24.04. S3 Bucket is created for metadata, and tfstate is configured to use remote S3 backend. Pipeline validates `terraform plan` before applying. Secrets are passed via GitHub Actions. Destruction pipeline is available for cleanup.

## Task 2: VM Configuration (Ansible)
- **Files**: `task2/setup.yml`, `task2/inventory.ini.tpl`
- **CI/CD**: `.github/workflows/task2-ansible.yml`
- **Result**: Installs Minikube, Kubernetes, Helm, Docker, and other dependencies on the provisioned EC2 instance. Pipeline configures `inventory.ini` dynamically using the server IP passed as a deployment input and uses `--check` for pre-flight validation. Minikube ports 8002 and 8003 are exposed with proxy/port-forwarding.

## Task 3: Application Deployment (CI/CD to Minikube)
- **Files**: `task3/deployment.yaml`
- **CI/CD**: `.github/workflows/task3-deploy.yml`
- **Result**: Pipeline builds a Docker container from the [devops-exam-pt2](https://github.com/YulianSalo/devops-exam-pt2) repository, pushes to GHCR, and deploys it to the remote EC2 Minikube cluster using Kubernetes manifests.
  - `dev` environment building from `develop` branch. Deployed to port 8002.
  - `release` environment building from `1.0.0` tag. Deployed to port 8003.
  - Implements remote SSH deployment via `--dry-run=client` testing before applying changes. App uses an individual Kubernetes namespace.

---
### Requirements Addressed
- [x] S3 backend logic
- [x] Pre-flight pipeline checks (terraform plan, ansible check, kubectl dry-run)
- [x] Protected secrets in CI/CD variables
- [x] Port proxying and dedicated configurations for dev/release node ports
- [x] Automated tear-down (destroy pipeline)

### How to run
1. Ensure GitHub Actions secrets are set: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `SSH_PRIVATE_KEY`.
2. Run `Task 1 - Terraform Infrastructure` from GitHub Actions.
3. Retrieve resulting EC2 IP. Ensure you have the `yankovskyi_key` set as `SSH_PRIVATE_KEY` for later runs.
4. Run `Task 2 - Ansible Setup` supplying the EC2 IP.
5. Setup `KUBE_HOST` secret with the EC2 IP.
6. Run `Task 3 - Deploy App` targeting either `dev` or `release` environments.
