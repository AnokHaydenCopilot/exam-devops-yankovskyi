# Progress Report - DevOps Part 2 Exam

- **Author**: Vitalii Yankovskyi
- **Goal**: AWS & Kubernetes deployment pipeline
- **Status**: Completed

## Steps Completed:
1. **Repository Setup**: Initialized local workspace `~/ALL/LABS/Екзамен_Завдання/Exam_DevOps_Yankovskyi` and pushed it to GitHub using `gh` CLI.
2. **Task 1 (Terraform)**:
   - Wrote S3 backend configuration (`main.tf`).
   - Wrote AWS resources: VPC, SG, Subnet, RouteTable, IGW, EC2 instance (`t3.medium`).
   - CI/CD checks: `terraform plan` blocks the pipeline if there's a syntax or structural issue.
3. **Task 2 (Ansible)**:
   - Configured `setup.yml` script installing `minikube`, `kubectl`, `helm`, `docker`.
   - CI/CD: Pipeline creates a dynamic `inventory.ini` mapped to the provided EC2 node IP. Uses `--check` dry-run for validation.
4. **Task 3 (Deploy & K8s)**:
   - Configured `task3-deploy.yml` pipeline with environments: `dev` and `release` based on GitHub Input.
   - Built and pushed images to GitHub Container Registry (GHCR) using tags `dev` (from `develop` branch) and `release` (from `1.0.0` tag).
   - Used `--dry-run=client` testing before kubectl apply.
   - Deployed on specific `target_env` namespace on Minikube. Forwarded 8002 and 8003 ports.
5. **Bonus**: Setup `Task 1 - Destroy` pipeline for tearing down resources.
