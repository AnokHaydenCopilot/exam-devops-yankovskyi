# DevOps Exam — Vitalii Yankovskyi

CI/CD pipeline that provisions AWS infrastructure, configures a Kubernetes node, and deploys a Django application to two isolated environments.

## Repository layout

```
task1/                       # Terraform — AWS infrastructure
  main.tf
task2/                       # Ansible — VM configuration
  setup.yml
  inventory.ini.tpl
task3/                       # Kubernetes manifests
  deployment-dev.yaml
  deployment-release.yaml
.github/workflows/
  task1-apply.yml            # Terraform apply
  task1-destroy.yml          # Terraform destroy (bonus)
  task2-ansible.yml          # Ansible playbook runner
  task3-deploy.yml           # Docker build + K8s deploy
```

---

## Task 1  Infrastructure (Terraform + AWS)

**Workflow:** `task1-apply.yml`

Provisions the following AWS resources in `eu-central-1`:

| Resource | Name |
|---|---|
| VPC | `yankovskyi-vpc` · `10.10.10.0/24` |
| Security group | `yankovskyi-firewall` · inbound: 22, 80, 443, 8000–8003 |
| EC2 instance | `yankovskyi-node` · Ubuntu 24.04 · `m7i-flex.large` (meets Minikube requirements) |
| S3 bucket | `yankovskyi-bucket` |

**SSH key management:** CI generates a fresh `ed25519` key pair on first run, stores the private key in **AWS Secrets Manager** (`yankovskyi/ci/ssh-key`), and passes only the public key to Terraform. Subsequent runs retrieve the existing key. No keys are ever committed to the repository.

**Remote Terraform state:**

```hcl
backend "s3" {
  bucket = "yankovskyi-terraform-state-exam"
  key    = "state/terraform.tfstate"
  region = "eu-central-1"
}
```

The state bucket is **separate** from the application bucket. The workflow bootstraps it before `terraform init` runs — `terraform init` does not create the bucket, it only connects to it. If the bucket does not exist at init time, Terraform exits with an error. State is stored remotely so any future run (or any runner) picks up the current infrastructure state instead of treating everything as new.

The instance IP is stored in **SSM Parameter Store** (`/yankovskyi/ec2/instance_ip`) as a Terraform-managed resource, so Task 2 and Task 3 retrieve it automatically without manual input.

**Pre-flight:** `terraform validate` + `terraform plan` run before `apply`. The pipeline stops on any error.

---

## Task 2  VM Configuration (Ansible)

**Workflow:** `task2-ansible.yml`

Installs on the EC2 instance:
- Docker (official convenience script)
- Minikube (docker driver, `--memory=4096 --cpus=2`)
- kubectl `v1.30.0`
- Helm
- Supporting packages: `socat`, `conntrack`, `curl`, `jq`, etc.

The SSH private key is loaded from AWS Secrets Manager at runtime. The instance IP is resolved automatically from SSM Parameter Store.

**Pre-flight:** `ansible-playbook --syntax-check` + `--check` (dry-run) run before the real playbook. The pipeline stops on syntax errors.

---

## Task 3  Application Deployment (Docker + Kubernetes)

**Workflow:** `task3-deploy.yml`  
**Source app:** [YulianSalo/devops-exam-pt2](https://github.com/YulianSalo/devops-exam-pt2)

Two independent environments, triggered by workflow input `target_env`:

| Environment | Branch/Tag | Port | NodePort |
|---|---|---|---|
| `dev` | `develop` | **8002** | 30002 |
| `release` | `1.0.0` | **8003** | 30003 |

**Pipeline steps:**
1. Clone source → checkout correct branch/tag → build Docker image → push to GHCR
2. Resolve EC2 IP from SSM
3. Create K8s namespace + GHCR image pull secret
4. Render environment-specific manifest (`deployment-dev.yaml` / `deployment-release.yaml`)
5. `kubectl apply --dry-run=client` validation
6. `kubectl apply` + `rollout status` wait
7. Start `socat` on the EC2 host: `EC2:8002 → minikubeIP:30002` (stable, survives SSH disconnect)
8. `curl` endpoint verification

**Verification:**
```bash
curl http://<EC2_IP>:8002   # → Hello, World! DEVELOP
curl http://<EC2_IP>:8003   # → Hello, World! 1.0.0
```

---

## How to run

> **Prerequisites:** GitHub Actions secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` must be set.

1. **Task 1**  run `Task 1 - Terraform Infrastructure (Apply)` → provisions all AWS resources, stores IP in SSM
2. **Task 2**  run `Task 2 - Ansible Setup` (no inputs needed, IP auto-resolved from SSM)
3. **Task 3**  run `Task 3 - Deploy Application` with `target_env=dev`, then again with `target_env=release`

To tear down: run `Task 1 - Terraform Infrastructure (Destroy)`.
