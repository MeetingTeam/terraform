# Terraform AWS Infrastructure and Application Deployment Guide

This guide outlines the steps to deploy the AWS infrastructure using Terraform and manage applications with Kubernetes, ArgoCD, and HashiCorp Vault.

## Project Structure Overview

The workspace is organized as follows:

*   **`./` (Root Directory):** Contains the main Terraform configuration for the EKS cluster and other core infrastructure components (`main.tf`, `variables.tf`, `output.tf`). It also includes Jenkinsfiles for CI/CD and Kubernetes manifest files.
*   **`application/`:** Holds Helm charts for various microservices (e.g., `chat-service`, `frontend-service`, `user-service`). Each service has its own chart and environment-specific value files (`values.dev.yaml`, `values.prod.yaml`).
*   **`chart/`:** Contains Helm charts for shared services and tools like ArgoCD (`argo-cd/`) and Jenkins (`jenkins/`).
*   **`environments/`:** Contains environment-specific Terraform configurations (`dev/`, `prod/`). Each environment has its own `main.tf`, `terraform.tfvars`, etc., to manage infrastructure variations between environments.
*   **`modules/`:** Houses reusable Terraform modules for different parts of the infrastructure, such as `compute`, `database`, `eks`, `network`, `security`, etc. This promotes modularity and code reuse.

## Deployment Steps

### Bước 1: Deploy AWS Infrastructure using Terraform

Navigate to the appropriate environment directory (`environments/dev` or `environments/prod`) and apply the Terraform configuration.

```bash
cd environments/<environment> # Replace <environment> with 'dev' or 'prod'
terraform init
terraform plan
terraform apply
```

This will provision the necessary AWS resources, including the EKS cluster, networking components, and other services defined in your Terraform modules.

### Bước 2: Configure `kubeconfig` for EKS

Once the EKS cluster is up and running, configure `kubectl` to interact with your cluster. Open a terminal (Git Bash or equivalent) and run:

```bash
aws eks update-kubeconfig --name doan-cluster-<environment> --region ap-southeast-1
```

Replace `<environment>` with the environment you deployed (e.g., `dev`, `prod`). This command updates your local `kubeconfig` file, allowing `kubectl` to connect to your EKS cluster.

### Bước 3: Access ArgoCD and Verify Application Deployment

ArgoCD is used for GitOps-style continuous delivery of applications defined in the `application/` and `chart/` directories.

To access the ArgoCD UI, use port-forwarding:

```bash
kubectl port-forward svc/argocd-server  30081:80 -n argo
```

Open your browser and navigate to `http://localhost:30081`. Log in to ArgoCD and check if the applications (e.g., `user-service`, `frontend-service`) have been deployed and are synced successfully.

### Bước 4: Insert Secrets into HashiCorp Vault Server

This project uses HashiCorp Vault for secret management. The following steps describe how to initialize Vault and load secrets. This typically needs to be done once.

1.  **Copy secret files to the Vault pod:**
    The `vault-secret-20250503T091044Z-1-001/vault-secret/` directory likely contains necessary scripts or initial secret data.
    ```bash
    kubectl -n vault cp ./vault-secret-20250503T091044Z-1-001/vault-secret vault-0:/home/vault
    ```
    *(Adjust the source path if your secrets/scripts are located elsewhere, e.g., directly in `./vault-secret/`)*

2.  **Access the Vault pod:**
    ```bash
    kubectl exec -it vault-0 -n vault -- sh
    ```

3.  **Inside the Vault pod, initialize and unseal Vault:**
    ```bash
    # (Inside the vault-0 pod)
    vault operator init
    ```
    Save the unseal keys and root token securely. You will need multiple unseal keys to unseal Vault.
    ```bash
    vault operator unseal <unseal_key_1>
    vault operator unseal <unseal_key_2>
    vault operator unseal <unseal_key_3>
    # ... (as many times as required based on your init settings)
    ```

4.  **Run any custom secret installation scripts:**
    Navigate to the directory where you copied the files and execute the installation script.
    ```bash
    # (Inside the vault-0 pod)
    cd /home/vault
    sh vault-install.sh # Or the name of your script
    ```
    Log in with the root token obtained during `vault operator init` if required by the script.

### Bước 5: Destroy Resources

To tear down all AWS infrastructure managed by Terraform:

1.  **Important Pre-requisite:** Before running `terraform destroy`, manually delete any AWS Load Balancers and their associated Target Groups that were created by Kubernetes services (especially services of type `LoadBalancer`). Terraform might not always be able to delete these resources if they are still in use or have dependencies managed outside of Terraform's state. You can do this via the AWS Management Console or AWS CLI.

2.  **Run Terraform Destroy:**
    Navigate to the environment directory (`environments/dev` or `environments/prod`) and run:
    ```bash
    cd environments/<environment> # Replace <environment> with 'dev' or 'prod'
    terraform destroy
    ```

This will remove all resources created by Terraform in that environment.

