# Progress Report - DevOps Part 2 Exam

- **Author**: Vitalii Yankovskyi
- **Goal**: AWS & Kubernetes deployment pipeline
- **Status**: Completed

## Steps Completed:
1. **Repository Setup**: Initialized local workspace `~/ALL/LABS/Екзамен_Завдання/Exam_DevOps_Yankovskyi` and pushed it to GitHub using `gh` CLI.
2. **Task 1 (Terraform)**:
   - Wrote S3 backend configuration (`main.tf`).
   - Wrote AWS resources: VPC, SG, subnet, route table, IGW, EC2 instance (`t3.medium`), and bucket.
   - CI/CD now bootstraps the remote state bucket and generates the SSH key pair in CI, storing the private key in AWS Secrets Manager.
3. **Task 2 (Ansible)**:
   - Configured `setup.yml` to install Docker, Minikube, kubectl, Helm, and supporting packages.
   - CI/CD now loads the SSH private key from AWS Secrets Manager and fails fast on syntax or `--check` errors.
4. **Task 3 (Deploy & K8s)**:
   - Configured `task3-deploy.yml` pipeline with environments: `dev` and `release` based on GitHub Input.
   - Built and pushed images to GitHub Container Registry (GHCR) using tags `dev` (from `develop` branch) and `release` (from `1.0.0` tag).
   - Used `--dry-run=client` testing before kubectl apply and validated the endpoint with `curl`.
5. **Bonus**: Set up `Task 1 - Destroy` pipeline for tearing down resources and cleaning up the AWS SSH secret.
