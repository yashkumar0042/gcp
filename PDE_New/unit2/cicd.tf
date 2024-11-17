To automate infrastructure deployment in **GCP** using **Terraform** and **GitHub Actions**, you can set up a **CI/CD pipeline** for Terraform. This pipeline will automate the steps such as planning, applying, and verifying Terraform configurations for provisioning GCP resources.

Here’s a sample CI/CD pipeline using **GitHub Actions** and **Terraform** to automate the deployment of infrastructure in **GCP**.

### Prerequisites
1. **GCP Project** and **Service Account** with sufficient permissions.
2. **Terraform** installed in your local environment.
3. **GitHub repository** where your Terraform configurations will be stored.
4. **GitHub Secrets** to securely store sensitive information like `GCP credentials` (Service Account Key JSON file).

### Steps:

#### 1. Set Up **GitHub Secrets**
- **`GCP_PROJECT_ID`**: Your GCP Project ID.
- **`GCP_SA_KEY`**: The **Service Account Key** JSON file content (downloaded from GCP Console).
  
Go to your repository’s **Settings → Secrets → New repository secret** to add the secrets.

#### 2. Create Terraform Files
Create a basic **Terraform configuration** for a GCP resource. For example, a **GCP Storage Bucket**.

```hcl
# main.tf

provider "google" {
  credentials = file("<YOUR-GCP-SERVICE-ACCOUNT-KEY>.json")
  project     = var.gcp_project_id
  region      = var.gcp_region
}

resource "google_storage_bucket" "my_bucket" {
  name     = "my-unique-bucket-2024"
  location = "US"
}
```

Create a `variables.tf` file for input variables.

```hcl
# variables.tf

variable "gcp_project_id" {
  description = "The GCP project ID"
}

variable "gcp_region" {
  description = "The region for GCP resources"
  default     = "us-central1"
}
```

#### 3. **GitHub Actions Workflow**
Create a `.github/workflows/terraform.yml` file to define your GitHub Actions workflow.

```yaml
name: 'Terraform CI/CD for GCP'

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest

    steps:
      # Checkout the code from the repository
      - name: Checkout code
        uses: actions/checkout@v2

      # Set up Google Cloud SDK
      - name: Set up Google Cloud SDK
        uses: google-github-actions/setup-gcloud@v0.2.0
        with:
          version: '345.0.0'

      # Authenticate to GCP using the service account
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v0.4.0
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      # Install Terraform
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: '1.3.0'

      # Initialize Terraform
      - name: Terraform Init
        run: terraform init

      # Plan Terraform changes
      - name: Terraform Plan
        run: terraform plan -out=tfplan

      # Apply the Terraform changes (auto-approve)
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan

      # Optionally, you can output the state file to GitHub Actions' artifact storage
      - name: Upload Terraform state
        uses: actions/upload-artifact@v2
        with:
          name: terraform-state
          path: terraform.tfstate
```

### Key Elements of the Workflow:
1. **Trigger Events**: The workflow triggers on `push` and `pull_request` events to the `main` branch.
2. **Authenticate to GCP**: The `google-github-actions/auth` action authenticates to GCP using the service account credentials stored in GitHub Secrets.
3. **Terraform Setup**: The workflow uses the `hashicorp/setup-terraform` action to install the specified version of Terraform.
4. **Terraform Operations**:
   - `terraform init`: Initializes the Terraform configuration.
   - `terraform plan`: Creates an execution plan to show changes.
   - `terraform apply`: Applies the changes to GCP (automatically approves).
5. **Upload State**: Optionally uploads the Terraform state file to GitHub artifacts for later retrieval.

### 4. Example Usage
1. **Create a PR (Pull Request)**: When you push your changes (like adding new Terraform resources), a PR will trigger the pipeline.
2. **Terraform Plan**: The plan step ensures you’re aware of what changes Terraform intends to make.
3. **Terraform Apply**: Once changes are approved, Terraform applies the changes to your GCP environment.

### 5. Monitor and Debug
- After a commit or PR, you can monitor the GitHub Actions run under the **Actions** tab of the repository.
- GitHub provides detailed logs for each step, which will help with debugging if something fails.

### Additional Resources:
- [Google Cloud Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Notes:
- Ensure you **validate your Terraform code** before applying changes in a production environment.
- You can extend this pipeline with different environments (e.g., **Dev**, **Prod**) by using separate Terraform configurations or workspaces.

This basic CI/CD pipeline should help you automate infrastructure management on GCP using **Terraform** and **GitHub Actions** effectively.
