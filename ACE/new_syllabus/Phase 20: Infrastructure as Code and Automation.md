# Phase 20: Infrastructure as Code and Automation

Infrastructure as Code should be learned near the end of the ACE journey because Terraform, Config Connector, Helm, and AI-assisted infrastructure tools automate the same resources that you previously created manually.

The ACE exam is unlikely to test advanced Terraform syntax deeply. However, you should understand:

- Why Infrastructure as Code is used
- The Terraform workflow
- Providers, resources, variables, outputs, and state
- How Terraform authenticates to Google Cloud
- How to identify and correct configuration drift
- When to use Terraform, Config Connector, Helm, or Google Cloud’s application-design tools
- How to safely create, update, and destroy infrastructure

Google Cloud supports several Infrastructure as Code approaches, including Terraform, Config Connector, Config Controller, Kubernetes-based configuration, and reusable infrastructure blueprints. citeturn663792search1turn235670search14

---

# 1. Infrastructure as Code Basics

## 1.1 What is Infrastructure as Code?

Infrastructure as Code, commonly called **IaC**, is the practice of defining infrastructure in configuration files instead of manually creating resources through the Google Cloud console.

Without IaC:

1. An administrator opens the console.
2. Creates a VPC.
3. Creates a subnet.
4. Creates firewall rules.
5. Creates virtual machines.
6. Repeats the same steps in development, testing, and production.

With IaC, those resources are described in files:

```hcl
resource "google_compute_network" "main_vpc" {
  name                    = "main-vpc"
  auto_create_subnetworks = false
}
```

The IaC tool reads the file and calls Google Cloud APIs to create the required resources.

---

## 1.2 Declarative vs imperative configuration

### Imperative approach

You specify every action that must happen.

Example:

```bash
gcloud compute networks create ace-vpc \
  --subnet-mode=custom

gcloud compute networks subnets create ace-subnet \
  --network=ace-vpc \
  --region=asia-south1 \
  --range=10.10.0.0/24
```

This means:

> First create the network, and then create the subnet.

### Declarative approach

You describe the final desired state.

```hcl
resource "google_compute_network" "ace_vpc" {
  name                    = "ace-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ace_subnet" {
  name          = "ace-subnet"
  region        = "asia-south1"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.ace_vpc.id
}
```

Terraform determines:

- Which API calls are required
- The dependency order
- Which resources already exist
- Which resources need modification
- Which resources need deletion

---

## 1.3 Benefits of Infrastructure as Code

### Repeatability

You can deploy the same infrastructure in:

- Development
- Testing
- Staging
- Production

Only variables such as project ID, machine type, and region need to change.

### Version control

IaC files can be stored in Git.

This provides:

- Change history
- Code review
- Pull requests
- Rollback capability
- Auditing
- Collaboration

### Consistency

Manual deployments frequently produce configuration differences.

For example:

- Development VM uses `e2-medium`
- Testing VM accidentally uses `n2-standard-4`
- Production firewall rule permits `0.0.0.0/0`

IaC reduces these inconsistencies.

### Automation

IaC can run through:

- Cloud Build
- GitHub Actions
- Jenkins
- GitLab CI/CD
- Terraform Cloud
- Google Cloud Infrastructure Manager

### Documentation

The configuration itself describes the infrastructure.

### Disaster recovery

Infrastructure can be recreated from source-controlled configuration.

However, IaC recreates infrastructure definitions—not necessarily application data. Database backups and object-storage protection must still be managed separately.

---

## 1.4 Desired state and reconciliation

IaC tools compare:

1. **Desired state** — what the configuration says should exist
2. **Recorded state** — what the IaC tool currently knows
3. **Actual state** — what exists in Google Cloud

Terraform then determines the actions needed to align the actual infrastructure with the desired infrastructure.

---

## 1.5 Configuration drift

Configuration drift happens when the deployed infrastructure no longer matches its IaC configuration.

Example:

Terraform defines:

```hcl
machine_type = "e2-micro"
```

Someone manually changes the VM to:

```text
e2-standard-4
```

Now the actual resource differs from Terraform’s configuration.

The next time you run:

```bash
terraform plan
```

Terraform detects the difference and normally proposes changing the machine type back to the configured value.

### Best practice

Avoid manually modifying Terraform-managed resources.

Emergency manual changes should later be reflected in the Terraform configuration, followed by a new plan and controlled deployment.

---

# 2. Terraform Basics

## 2.1 What is Terraform?

Terraform is a declarative Infrastructure as Code tool created by HashiCorp.

It can manage infrastructure across multiple providers, including:

- Google Cloud
- AWS
- Microsoft Azure
- Kubernetes
- GitHub
- Datadog
- Cloudflare

For Google Cloud, Terraform uses the Google Cloud provider to call Google Cloud APIs and manage resources. citeturn235670search14turn235670search15

---

## 2.2 Terraform architecture

A typical Terraform workflow is:

```text
Terraform configuration
        ↓
Google Cloud provider
        ↓
Google Cloud APIs
        ↓
Google Cloud resources
```

Terraform itself does not directly create a VM. It asks the Google Cloud provider to call the Compute Engine API.

---

## 2.3 Terraform configuration language

Terraform uses HashiCorp Configuration Language, or **HCL**.

Terraform files normally use the `.tf` extension.

Typical project:

```text
terraform-project/
├── versions.tf
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
```

### Common file purposes

| File | Purpose |
|---|---|
| `versions.tf` | Terraform and provider version constraints |
| `provider.tf` | Provider configuration |
| `main.tf` | Infrastructure resources |
| `variables.tf` | Input variable definitions |
| `terraform.tfvars` | Variable values |
| `outputs.tf` | Values displayed after deployment |
| `.terraform.lock.hcl` | Provider version lock file |
| `terraform.tfstate` | Terraform state |

Terraform does not require these exact file names. It loads all `.tf` files in the current directory as one configuration.

---

# 3. Core Terraform Blocks

## 3.1 Terraform block

The `terraform` block defines Terraform requirements.

```hcl
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
```

### Important points

- `required_version` controls the Terraform CLI version.
- `required_providers` declares the required providers.
- `source` identifies the provider registry location.
- `version` prevents unexpected provider upgrades.

In production, provider versions should be constrained and the `.terraform.lock.hcl` file should normally be committed to version control.

---

## 3.2 Provider block

The provider block configures the connection to Google Cloud.

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
```

The provider needs:

- Credentials
- Project information
- Region or zone, depending on the resources

---

## 3.3 Resource block

A resource block creates or manages infrastructure.

```hcl
resource "google_compute_network" "ace_vpc" {
  name                    = "ace-vpc"
  auto_create_subnetworks = false
}
```

General syntax:

```hcl
resource "<PROVIDER_RESOURCE_TYPE>" "<LOCAL_NAME>" {
  argument = value
}
```

In this example:

```text
google_compute_network = resource type
ace_vpc                = Terraform local name
ace-vpc                = actual Google Cloud resource name
```

The Terraform reference is:

```hcl
google_compute_network.ace_vpc
```

---

## 3.4 Variables

Variables make configurations reusable.

```hcl
variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}
```

A variable with a default value:

```hcl
variable "region" {
  description = "Deployment region"
  type        = string
  default     = "asia-south1"
}
```

Reference it as:

```hcl
var.region
```

---

## 3.5 Variable values

Values can be supplied in several ways.

### Through a `.tfvars` file

```hcl
project_id   = "my-project-id"
region       = "asia-south1"
zone         = "asia-south1-a"
machine_type = "e2-micro"
```

### Through the command line

```bash
terraform apply \
  -var="project_id=my-project-id" \
  -var="region=asia-south1"
```

### Through environment variables

```bash
export TF_VAR_project_id="my-project-id"
export TF_VAR_region="asia-south1"
```

Terraform recognizes variables prefixed with:

```text
TF_VAR_
```

---

## 3.6 Outputs

Outputs display important values after deployment.

```hcl
output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.ace_vm.network_interface[0].network_ip
}
```

View all outputs:

```bash
terraform output
```

View one output:

```bash
terraform output vm_internal_ip
```

---

## 3.7 Local values

Locals avoid repeating expressions.

```hcl
locals {
  name_prefix = "${var.environment}-ace"
}
```

Use the local value:

```hcl
name = "${local.name_prefix}-vpc"
```

Unlike input variables, local values are calculated within the configuration and are not normally supplied by users.

---

## 3.8 Data sources

A data source reads existing information instead of creating a resource.

Example:

```hcl
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}
```

Use it in a VM:

```hcl
initialize_params {
  image = data.google_compute_image.debian.self_link
}
```

### Resource vs data source

| Resource | Data source |
|---|---|
| Creates or manages something | Reads existing information |
| Maintains lifecycle | Does not own the external resource |
| Example: create VPC | Example: find latest Debian image |

---

## 3.9 Dependencies

Terraform automatically detects dependencies when one resource references another.

```hcl
network = google_compute_network.ace_vpc.id
```

Terraform understands that the VPC must exist before the dependent resource.

An explicit dependency is occasionally required:

```hcl
depends_on = [
  google_project_service.compute_api
]
```

Use `depends_on` only when Terraform cannot infer the dependency through resource references.

---

# 4. Terraform Workflow

The core Terraform workflow is:

```text
Write → Initialize → Format → Validate → Plan → Apply
```

Google Cloud’s Terraform documentation identifies `init`, `plan`, `apply`, and `destroy` as fundamental commands for managing infrastructure. citeturn235670search31

---

## 4.1 `terraform init`

```bash
terraform init
```

It:

- Initializes the working directory
- Downloads providers
- Configures the backend
- Creates the `.terraform` directory
- Creates or updates `.terraform.lock.hcl`

Run it:

- When starting a new project
- After changing providers
- After changing the backend
- After downloading an existing Terraform project

---

## 4.2 `terraform fmt`

```bash
terraform fmt
```

It reformats Terraform files into the standard HCL format.

Check formatting without modifying files:

```bash
terraform fmt -check -recursive
```

Useful in CI/CD:

```bash
terraform fmt -check -recursive
```

---

## 4.3 `terraform validate`

```bash
terraform validate
```

It checks:

- Terraform syntax
- Internal references
- Required arguments
- Type consistency

It does not fully confirm that Google Cloud will accept the configuration. API permissions, quotas, invalid regions, and policy constraints may still cause `terraform apply` to fail.

---

## 4.4 `terraform plan`

```bash
terraform plan
```

It previews proposed changes.

Common symbols:

```text
+ create
~ update in place
-/+ destroy and recreate
- destroy
```

Create a saved plan:

```bash
terraform plan -out=tfplan
```

A saved plan is useful because the exact reviewed plan can be applied:

```bash
terraform apply tfplan
```

---

## 4.5 `terraform apply`

```bash
terraform apply
```

Terraform displays the plan and asks for confirmation.

Automatically approve:

```bash
terraform apply -auto-approve
```

`-auto-approve` is convenient for labs but should be used carefully in production.

---

## 4.6 `terraform show`

```bash
terraform show
```

View a saved plan:

```bash
terraform show tfplan
```

Machine-readable JSON:

```bash
terraform show -json tfplan
```

---

## 4.7 `terraform state list`

```bash
terraform state list
```

Example output:

```text
google_compute_instance.ace_vm
google_compute_network.ace_vpc
google_compute_subnetwork.ace_subnet
```

Inspect one resource:

```bash
terraform state show google_compute_instance.ace_vm
```

Do not manually edit the state file using a text editor.

---

## 4.8 `terraform destroy`

```bash
terraform destroy
```

It proposes deleting all Terraform-managed resources in the current state.

Lab-friendly command:

```bash
terraform destroy -auto-approve
```

Always review the destroy plan carefully.

---

# 5. Terraform State

## 5.1 What is Terraform state?

Terraform stores information about managed infrastructure in a state file:

```text
terraform.tfstate
```

State maps Terraform addresses such as:

```text
google_compute_network.ace_vpc
```

to actual Google Cloud resources such as:

```text
projects/my-project/global/networks/ace-vpc
```

Terraform needs state to understand:

- Which resources it manages
- Resource IDs
- Resource dependencies
- Existing attributes
- Previous configuration

---

## 5.2 Local state

By default, state is stored locally.

```text
terraform.tfstate
```

This is acceptable for:

- Personal labs
- Temporary demonstrations
- Single-user experiments

It is unsuitable for team environments because:

- Different engineers may have different copies
- Simultaneous deployments can conflict
- The state may be lost
- Sensitive values may appear in the state
- There may be no reliable locking or central backup

---

## 5.3 Remote state in Cloud Storage

For team environments, state can be stored in a Cloud Storage bucket.

```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "ace/network"
  }
}
```

Benefits include:

- Shared state
- Central storage
- Versioning
- Access control through IAM
- Better collaboration

### Important bootstrap issue

The state bucket usually must exist before Terraform initializes the backend.

Create it separately:

```bash
gcloud storage buckets create gs://YOUR_UNIQUE_BUCKET_NAME \
  --location=asia-south1 \
  --uniform-bucket-level-access
```

Enable versioning:

```bash
gcloud storage buckets update gs://YOUR_UNIQUE_BUCKET_NAME \
  --versioning
```

Then run:

```bash
terraform init -migrate-state
```

---

## 5.4 State security

Terraform state may contain:

- IP addresses
- Resource IDs
- Service account information
- Configuration values
- Sensitive values
- In some situations, secrets passed to resources

Marking an output as sensitive only hides it from normal CLI output. It does not guarantee that the value is absent from the state.

Protect remote state with:

- Least-privilege IAM
- Uniform bucket-level access
- Object versioning
- Encryption requirements
- Logging and auditing
- Restricted administrator access

---

# 6. Terraform Provider for Google Cloud

## 6.1 Google provider

The main provider is:

```hcl
hashicorp/google
```

Example:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
```

---

## 6.2 Google beta provider

Some preview or beta features may require:

```hcl
hashicorp/google-beta
```

Example:

```hcl
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}
```

Provider configuration:

```hcl
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
```

A resource can explicitly use the beta provider:

```hcl
resource "google_compute_instance" "example" {
  provider = google-beta

  name         = "beta-example"
  machine_type = "e2-micro"
  zone         = var.zone

  # Remaining configuration
}
```

Use the stable provider unless the required feature specifically needs the beta provider.

---

# 7. Terraform Authentication to Google Cloud

## 7.1 Application Default Credentials

For local development or Cloud Shell, Terraform can use Application Default Credentials.

Run:

```bash
gcloud auth application-default login
```

Then:

```bash
gcloud auth application-default set-quota-project PROJECT_ID
```

This creates credentials for applications such as Terraform and client libraries.

This is separate from:

```bash
gcloud auth login
```

`gcloud auth login` authenticates the gcloud CLI, while Application Default Credentials are used by applications that follow Google’s ADC mechanism.

---

## 7.2 Cloud Shell authentication

Cloud Shell already has:

- Google Cloud CLI
- Terraform
- An authenticated Google Cloud session
- Access to the selected project, subject to IAM permissions

This makes Cloud Shell convenient for ACE labs.

---

## 7.3 Service account impersonation

For enterprise environments, service account impersonation is generally preferable to downloading long-lived service account keys.

Example provider:

```hcl
provider "google" {
  project                     = var.project_id
  region                      = var.region
  impersonate_service_account = var.terraform_service_account
}
```

Variable:

```hcl
variable "terraform_service_account" {
  type = string
}
```

Example value:

```hcl
terraform_service_account = "terraform-deployer@my-project.iam.gserviceaccount.com"
```

The caller needs permission to generate tokens for that service account, usually through:

```text
roles/iam.serviceAccountTokenCreator
```

The impersonated service account also requires permissions to manage the target resources.

---

## 7.4 Service account keys

A service account JSON key can be used:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

However, long-lived service account keys introduce security and lifecycle risks.

For production automation, prefer:

- Workload Identity Federation
- Service account impersonation
- Attached service account identities
- Short-lived credentials

---

# 8. Creating a VPC with Terraform

## Basic VPC

```hcl
resource "google_compute_network" "ace_vpc" {
  name                    = "ace-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}
```

### Important attributes

| Attribute | Meaning |
|---|---|
| `name` | VPC name |
| `auto_create_subnetworks` | `false` creates a custom-mode VPC |
| `routing_mode` | `REGIONAL` or `GLOBAL` dynamic routing mode |
| `delete_default_routes_on_create` | Whether to remove automatically created default routes |

For ACE scenarios, remember:

```hcl
auto_create_subnetworks = false
```

means **custom-mode VPC**.

Google Cloud’s VPC documentation uses the `google_compute_network` Terraform resource to create VPC networks. citeturn235670search35

---

## Subnet

```hcl
resource "google_compute_subnetwork" "ace_subnet" {
  name                     = "ace-subnet"
  region                   = "asia-south1"
  network                  = google_compute_network.ace_vpc.id
  ip_cidr_range            = "10.10.0.0/24"
  private_ip_google_access = true
}
```

`private_ip_google_access = true` allows eligible VMs without external IP addresses to reach Google APIs and services through Private Google Access.

It does not provide general internet access. Cloud NAT is needed when private VMs require outbound internet access.

---

# 9. Creating a VM with Terraform

```hcl
resource "google_compute_instance" "ace_vm" {
  name         = "ace-terraform-vm"
  machine_type = "e2-micro"
  zone         = "asia-south1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ace_subnet.id
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOT
}
```

Google Cloud provides Terraform quickstarts specifically for creating Compute Engine VM instances through the Google provider. citeturn235670search15

---

## VM with an external IP

Add an empty `access_config` block:

```hcl
network_interface {
  subnetwork = google_compute_subnetwork.ace_subnet.id

  access_config {
  }
}
```

This requests an ephemeral external IP.

Without `access_config`, the VM receives only an internal IP.

---

## VM service account

```hcl
service_account {
  email  = google_service_account.vm_service_account.email
  scopes = ["cloud-platform"]
}
```

Create the service account:

```hcl
resource "google_service_account" "vm_service_account" {
  account_id   = "ace-vm-sa"
  display_name = "ACE Terraform VM Service Account"
}
```

The `cloud-platform` OAuth scope allows the VM to request tokens for Google Cloud APIs, but IAM roles still determine what the service account can actually do.

---

# 10. Terraform Lifecycle Management

## 10.1 Resource replacement

Some changes can be updated in place:

```text
~ update
```

Other changes require destroying and recreating the resource:

```text
-/+ replace
```

For example, changing a resource property that an API treats as immutable may require replacement.

Always inspect `terraform plan`.

---

## 10.2 `prevent_destroy`

```hcl
lifecycle {
  prevent_destroy = true
}
```

This prevents Terraform from deleting the resource unless the lifecycle rule is removed first.

Useful for:

- Production databases
- Critical storage buckets
- Shared networks
- Important state resources

It is an additional safety measure, not a replacement for IAM, backups, code review, or change controls.

---

## 10.3 `create_before_destroy`

```hcl
lifecycle {
  create_before_destroy = true
}
```

Terraform attempts to create the replacement before deleting the existing resource.

This can reduce downtime, but it only works when:

- Both resources can temporarily coexist
- Resource names do not conflict
- Quotas permit the additional resource

---

## 10.4 `ignore_changes`

```hcl
lifecycle {
  ignore_changes = [
    labels
  ]
}
```

Terraform ignores changes to listed attributes.

Use this carefully because it can hide legitimate drift.

---

# 11. Importing Existing Resources

Terraform can import an existing Google Cloud resource into state.

Example:

```bash
terraform import \
  google_compute_network.existing_vpc \
  projects/PROJECT_ID/global/networks/existing-vpc
```

Before importing, create the matching resource block:

```hcl
resource "google_compute_network" "existing_vpc" {
  name                    = "existing-vpc"
  auto_create_subnetworks = false
}
```

Import adds the resource to Terraform state. It does not automatically guarantee that your local configuration fully matches every property of the existing resource.

After importing:

```bash
terraform plan
```

Review all proposed changes carefully.

---

# 12. Terraform Modules

## 12.1 What is a module?

A module is a reusable collection of Terraform files.

Instead of repeating VPC configuration in every project, create a reusable module.

```text
modules/
└── network/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

Google Cloud provides Terraform blueprints and modules that package reusable infrastructure patterns for larger deployments. citeturn663792search0

---

## 12.2 Calling a module

```hcl
module "network" {
  source = "./modules/network"

  project_id  = var.project_id
  network_name = "production-vpc"
  region       = "asia-south1"
  subnet_cidr  = "10.20.0.0/24"
}
```

---

## 12.3 Advantages of modules

- Reusability
- Standardization
- Reduced duplication
- Easier governance
- Faster deployments
- Consistent security controls

Example enterprise module:

```text
secure-vm-module
├── private IP only
├── approved machine types
├── Shielded VM enabled
├── OS Login enabled
├── mandatory labels
└── approved service account
```

Developers use the module without rebuilding every security control.

---

# 13. Terraform Workspaces

A workspace allows multiple Terraform state instances to use the same configuration.

Commands:

```bash
terraform workspace list
```

Create:

```bash
terraform workspace new dev
```

Select:

```bash
terraform workspace select dev
```

Use in configuration:

```hcl
name = "${terraform.workspace}-ace-vpc"
```

### Important limitation

Workspaces are not always the best way to isolate production environments.

Many organizations prefer separate:

- Directories
- State files
- Projects
- Pipelines
- Service accounts
- IAM boundaries

Example:

```text
environments/
├── dev/
├── staging/
└── production/
```

This provides stronger isolation and clearer ownership.

---

# 14. Config Connector

## 14.1 What is Config Connector?

Config Connector is an open-source Kubernetes add-on that lets you manage Google Cloud resources through Kubernetes APIs and YAML manifests.

It provides Custom Resource Definitions and controllers that continuously reconcile Kubernetes objects with corresponding Google Cloud resources. citeturn235670search2turn235670search6

Example:

```yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeNetwork
metadata:
  name: ace-config-connector-vpc
spec:
  autoCreateSubnetworks: false
  routingMode: REGIONAL
```

Apply:

```bash
kubectl apply -f network.yaml
```

Config Connector creates the VPC through Google Cloud APIs.

---

## 14.2 How Config Connector works

```text
Kubernetes YAML
      ↓
Config Connector CRD
      ↓
Config Connector controller
      ↓
Google Cloud API
      ↓
Google Cloud resource
```

The controller repeatedly compares:

- Kubernetes desired state
- Google Cloud actual state

It then reconciles differences.

---

## 14.3 Kubernetes-native capabilities

Config Connector lets teams use:

- `kubectl`
- Kubernetes YAML
- RBAC
- Namespaces
- Kubernetes events
- GitOps workflows
- Policy Controller
- Config Sync
- Custom resources

Supported Config Connector resources use Kubernetes API groups under `cnrm.cloud.google.com`. citeturn235670search7

---

## 14.4 Example: Cloud Storage bucket

```yaml
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: ace-config-connector-bucket
  annotations:
    cnrm.cloud.google.com/project-id: YOUR_PROJECT_ID
spec:
  location: ASIA-SOUTH1
  uniformBucketLevelAccess: true
  versioning:
    enabled: true
```

Apply:

```bash
kubectl apply -f bucket.yaml
```

Check:

```bash
kubectl get storagebucket
```

Describe:

```bash
kubectl describe storagebucket ace-config-connector-bucket
```

Delete:

```bash
kubectl delete -f bucket.yaml
```

Depending on the Config Connector deletion policy, deleting the Kubernetes object may also delete the underlying Google Cloud resource.

---

## 14.5 Config Connector installation options

Google Cloud documents three main installation approaches:

1. Config Controller
2. Manual installation using the Config Connector operator
3. GKE add-on-based installation

Manual namespaced mode is recommended for many multi-tenant scenarios because it improves permission isolation and scalability. citeturn235670search3turn235670search5

---

## 14.6 Terraform vs Config Connector

| Requirement | Terraform | Config Connector |
|---|---|---|
| General-purpose cloud IaC | Strong fit | Kubernetes-focused |
| Multi-cloud infrastructure | Strong fit | No |
| Kubernetes-native workflows | Possible but separate | Strong fit |
| Uses HCL | Yes | No |
| Uses Kubernetes YAML | No | Yes |
| Continuous reconciliation | Mostly plan/apply driven | Controller driven |
| GitOps integration | Yes | Very natural |
| Existing Kubernetes platform team | Useful | Often preferable |
| Manage many cloud providers | Yes | Primarily Google Cloud |

### Exam decision rule

Choose **Terraform** when:

- The organization wants standardized general-purpose IaC
- The infrastructure spans multiple services or cloud providers
- Teams already use HCL and Terraform pipelines

Choose **Config Connector** when:

- The organization is Kubernetes-centric
- Teams want to manage Google Cloud resources through Kubernetes APIs
- GitOps and Kubernetes RBAC are central requirements

---

# 15. Config Controller

Config Controller is a Google-managed control plane that includes Config Connector.

It gives organizations a centralized Kubernetes-style control plane for provisioning Google Cloud infrastructure without requiring them to operate the underlying management cluster themselves. Google Cloud manages the Config Connector version and regularly updates it as qualified releases become available. citeturn235670search5

### Config Connector vs Config Controller

| Config Connector | Config Controller |
|---|---|
| Kubernetes add-on and controllers | Managed configuration control plane |
| Can run in your GKE environment | Google-managed service |
| You manage installation options | Google manages much of the control-plane lifecycle |
| More operational responsibility | Lower control-plane operational burden |

---

# 16. Helm

## 16.1 What is Helm?

Helm is a package manager for Kubernetes.

A Kubernetes application may require multiple manifests:

```text
Deployment
Service
ConfigMap
Secret
Ingress
ServiceAccount
HorizontalPodAutoscaler
NetworkPolicy
```

Helm packages these objects into a reusable unit called a **chart**.

---

## 16.2 Core Helm terminology

| Term | Meaning |
|---|---|
| Chart | Kubernetes application package |
| Release | Installed instance of a chart |
| Repository | Location containing charts |
| Values | Custom configuration passed to a chart |
| Template | Parameterized Kubernetes manifest |
| `Chart.yaml` | Chart metadata |
| `values.yaml` | Default configuration values |

---

## 16.3 Helm chart structure

```text
my-application/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

---

## 16.4 Common Helm commands

Add a repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Update repository information:

```bash
helm repo update
```

Search:

```bash
helm search repo nginx
```

Install a chart:

```bash
helm install web-server bitnami/nginx
```

List releases:

```bash
helm list
```

Upgrade:

```bash
helm upgrade web-server bitnami/nginx
```

Install or upgrade:

```bash
helm upgrade --install web-server bitnami/nginx
```

View release status:

```bash
helm status web-server
```

View history:

```bash
helm history web-server
```

Rollback:

```bash
helm rollback web-server 1
```

Uninstall:

```bash
helm uninstall web-server
```

Helm is preinstalled in Google Cloud Shell, making it convenient for GKE administration and labs. citeturn235670search30turn235670search46

---

## 16.5 Custom values

Create:

```yaml
# custom-values.yaml
replicaCount: 3

service:
  type: LoadBalancer
```

Install:

```bash
helm upgrade --install web-server bitnami/nginx \
  --values custom-values.yaml
```

Or override individual values:

```bash
helm upgrade --install web-server bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```

---

## 16.6 Terraform vs Helm

Terraform manages infrastructure such as:

- VPC
- Subnet
- GKE cluster
- IAM
- Cloud SQL
- Load balancer components

Helm packages and deploys applications inside Kubernetes.

Common combination:

```text
Terraform
   └── Creates GKE cluster
          └── Helm
                └── Deploys applications to GKE
```

Terraform also has a Helm provider, but teams should decide carefully whether application releases and infrastructure need the same lifecycle.

---

# 17. Fabric FAST

## 17.1 What is Fabric FAST?

Fabric FAST is a framework based on Cloud Foundation Fabric patterns for rapidly creating an enterprise Google Cloud foundation or landing zone.

It is intended for much larger environments than a simple VPC-and-VM lab.

Fabric FAST can help structure:

- Organization-level configuration
- Folders and projects
- IAM
- Shared VPC
- Hub-and-spoke networking
- Network Connectivity Center
- Security controls
- Logging
- Billing integration
- Environment separation
- Terraform automation

Google Cloud architecture guidance references Fabric FAST as one option for implementing enterprise landing-zone and hub-and-spoke designs. citeturn663792search6turn663792search17turn663792search37

---

## 17.2 Landing zone concept

A landing zone is the initial cloud foundation on which workload teams deploy applications.

A typical landing zone includes:

```text
Organization
├── Bootstrap
├── Common services
├── Networking
├── Security
├── Logging
├── Development
├── Non-production
└── Production
```

Its purpose is to ensure that future projects inherit approved:

- Networking
- Security
- Identity
- Logging
- Compliance
- Billing
- Governance patterns

---

## 17.3 FAST vs writing Terraform manually

| Manual Terraform | Fabric FAST |
|---|---|
| You design everything yourself | Provides structured enterprise patterns |
| Suitable for small environments | Designed for larger foundations |
| Easier to understand initially | More modules and dependencies |
| Maximum flexibility | Faster standardization |
| Small learning curve | Requires landing-zone knowledge |

### ACE perspective

You do not need to memorize Fabric FAST implementation internals.

Understand that it is used for:

- Enterprise cloud foundations
- Landing-zone deployment
- Reusable Terraform-based architecture
- Standardized networking, IAM, security, and project provisioning

---

# 18. Gemini CLI

## 18.1 What is Gemini CLI?

Gemini CLI provides AI assistance from the terminal.

It can help with:

- Understanding a repository
- Generating Terraform configuration
- Explaining an error
- Updating code
- Generating scripts
- Reviewing configuration
- Running development workflows
- Producing documentation
- Troubleshooting deployment failures

Gemini CLI is available in Cloud Shell without additional installation, and its Google Cloud usage is associated with Gemini Code Assist entitlements and quotas. citeturn235670search12turn235670search24

---

## 18.2 Example use cases

### Generate Terraform

Prompt:

```text
Create Terraform code for a custom-mode VPC named ace-vpc,
a subnet named ace-subnet in asia-south1 with CIDR
10.10.0.0/24, and an e2-micro Debian VM without an external IP.
Use variables and outputs.
```

### Troubleshoot an error

```text
Explain why terraform apply receives a 403 error when creating
a Compute Engine instance. Identify the required API and IAM
permissions, but do not change files yet.
```

### Review configuration

```text
Review this Terraform directory for:
- overly broad firewall rules
- hardcoded project IDs
- missing provider version constraints
- public IP exposure
- unsafe state handling
```

### Generate documentation

```text
Create a README explaining prerequisites, variables, outputs,
deployment steps, verification, and cleanup for this Terraform project.
```

---

## 18.3 AI safety principles

AI-generated infrastructure must be reviewed.

Check for:

- Overly broad IAM roles
- `0.0.0.0/0` firewall access
- Public IP addresses
- Hardcoded credentials
- Incorrect regions
- Expensive machine types
- Destructive lifecycle changes
- Deprecated resource arguments
- Invalid provider versions
- Missing encryption or logging
- Incorrect assumptions about APIs and quotas

The safe workflow is:

```text
Prompt
  ↓
Generate proposal
  ↓
Human review
  ↓
terraform fmt
  ↓
terraform validate
  ↓
terraform plan
  ↓
Security and cost review
  ↓
terraform apply
```

Never treat generated infrastructure as automatically correct.

---

# 19. Google Antigravity

## 19.1 What is Google Antigravity?

Google Antigravity is an agentic development platform designed to let developers work with AI agents across code, terminals, browsers, workspaces, and development tasks.

Antigravity 2.0 operates as a standalone agent platform that can coordinate multiple local agents and automate development workflows. Its IDE and CLI can work directly with a codebase to build, debug, and ship software. citeturn663792search4turn663792search15turn663792search24turn663792search34

---

## 19.2 Infrastructure use cases

Antigravity can assist with:

- Reading an existing Terraform repository
- Designing module structures
- Generating infrastructure code
- Running validation commands
- Investigating failed deployments
- Updating multiple files
- Generating diagrams
- Creating tests and documentation
- Coordinating parallel development tasks

Example task:

```text
Analyze this Terraform project.

1. Identify all networking, IAM, and compute resources.
2. Detect hardcoded project IDs and regions.
3. Refactor the VPC and VM resources into reusable modules.
4. Run terraform fmt and terraform validate.
5. Show me the plan before applying anything.
6. Do not create or destroy cloud resources.
```

---

## 19.3 Antigravity and Google Cloud data services

Google has documented connecting Antigravity agents to services such as BigQuery, AlloyDB, Spanner, Cloud SQL, and Looker through MCP-based integrations. citeturn663792search5

### Important distinction

Antigravity is not itself an IaC state-management engine.

Terraform still handles:

- State
- Dependency graph
- Resource lifecycle
- Plan and apply
- Drift detection

Antigravity helps humans create, understand, modify, and operate the Terraform project.

---

# 20. Gemini Cloud Assist

## 20.1 What is Gemini Cloud Assist?

Gemini Cloud Assist is an AI-powered assistant for designing, deploying, operating, troubleshooting, and optimizing applications on Google Cloud.

Its capabilities include:

- Infrastructure design
- Deployment support
- Monitoring
- Troubleshooting
- Performance analysis
- Cost optimization
- Application lifecycle assistance

Google describes it as an agentic partner covering application design through deployment, monitoring, troubleshooting, performance, and cost optimization. citeturn663792search2turn663792search12turn663792search22

---

## 20.2 Infrastructure-related examples

You might ask:

```text
Design a highly available web application using Cloud Run,
Cloud SQL, HTTPS load balancing, Cloud Armor, and Secret Manager.
```

Or:

```text
Why is this VM unable to reach the internet even though the
firewall allows egress?
```

Or:

```text
Find underutilized Compute Engine instances and explain the
possible monthly savings before recommending any changes.
```

Or:

```text
Generate Terraform for this proposed Google Cloud architecture.
```

The Gemini Cloud Assist infrastructure-design tooling can generate an architecture, render a diagram, and generate Terraform code. It can also work from existing IaC while iterating on an application design. citeturn663792search41

---

## 20.3 Gemini Cloud Assist vs Gemini CLI

| Gemini Cloud Assist | Gemini CLI |
|---|---|
| Google Cloud lifecycle assistant | Terminal-based development assistant |
| Strong Google Cloud resource context | Strong local repository context |
| Design, operations, monitoring, cost | Coding, scripting and repository work |
| Available through supported Cloud interfaces and integrations | Used directly from the command line |
| Can assist across running cloud environments | Often starts from local code and files |

These capabilities increasingly overlap through agentic tooling and MCP integrations.

---

# 21. Application Design Center

## 21.1 What is Application Design Center?

Application Design Center lets platform and application teams visually design, share, and deploy application architectures on Google Cloud.

Platform teams can publish standardized application templates, while developers use those templates to deploy approved architectures more quickly. citeturn663792search10turn663792search45

Application Design Center became generally available in December 2025 and supports an AI-powered canvas-style workflow for designing and modifying Terraform application templates. citeturn663792search18

---

## 21.2 Main concepts

### Application

A logical grouping of workloads and services that together provide a business function.

Example:

```text
Online Store Application
├── Frontend workload
├── Product service
├── Payment service
├── Cloud SQL
├── Memorystore
└── Load balancer
```

Application Design Center works with an application-centric model, while App Hub groups services and workloads into logical applications. citeturn663792search29

### Template

A reusable, deployable architecture.

Example:

```text
Approved Three-Tier Web Application
├── Global load balancer
├── Cloud Run frontend
├── Private Cloud SQL
├── Secret Manager
├── Monitoring
└── Required labels
```

### Platform administrator

Creates and governs templates.

### Application developer

Selects a template, supplies approved parameters, and deploys the application.

---

## 21.3 Why organizations use it

It helps solve the following problem:

```text
Every team independently designs infrastructure
                    ↓
Inconsistent security, networking and reliability
```

Instead:

```text
Platform team creates approved templates
                    ↓
Development teams deploy standardized applications
```

Benefits include:

- Faster application deployment
- Reusable architecture
- Organizational standards
- Reduced infrastructure duplication
- Better platform-team governance
- Visual architecture design
- Terraform-based deployment artifacts

Application Design Center can also integrate with external tools such as Antigravity, Gemini CLI, and Cursor through MCP-based integrations. citeturn663792search32turn663792search49

---

# 22. AI-Assisted Planning and Implementation

AI-assisted cloud development can be divided into five stages.

## Stage 1: Requirements gathering

Example request:

```text
I need an internal application for 500 employees.
It must be highly available, accessible only through corporate
networks, use PostgreSQL, and support disaster recovery.
```

AI can identify missing requirements:

- Expected traffic
- Recovery time objective
- Recovery point objective
- Data residency
- Authentication
- Availability target
- Budget
- Compliance
- Deployment frequency

---

## Stage 2: Architecture planning

Possible result:

```text
Users
  ↓
Internal Application Load Balancer
  ↓
Regional Managed Instance Group
  ↓
Cloud SQL HA
  ↓
Backup and cross-region replica
```

The architecture must still be reviewed by cloud, security, networking, and application owners.

---

## Stage 3: Infrastructure generation

AI can generate:

- Terraform resources
- Variables
- Outputs
- Modules
- IAM bindings
- Firewall rules
- Startup scripts
- CI/CD pipelines

---

## Stage 4: Validation and testing

Run:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

Additional tools may include:

- `tflint`
- `checkov`
- Policy as Code
- Organization Policy
- Cloud Build validation
- Security scanners

---

## Stage 5: Controlled deployment

Production workflow:

```text
Developer branch
      ↓
Pull request
      ↓
Formatting and validation
      ↓
Security and policy checks
      ↓
Terraform plan
      ↓
Human approval
      ↓
Terraform apply
      ↓
Post-deployment verification
```

AI may generate and analyze, but production approval should remain controlled.

---

# 23. Complete Mini Lab: VPC + Subnet + VM Using Terraform

## Objective

Create:

```text
Custom VPC: ace-terraform-vpc
        ↓
Subnet: ace-terraform-subnet
        ↓
Private VM: ace-terraform-vm
```

The VM will:

- Use Debian 12
- Use `e2-micro`
- Have only an internal IP
- Install NGINX through a startup script
- Allow internal HTTP traffic
- Use a custom service account

---

## Architecture

```text
Google Cloud Project
└── ace-terraform-vpc
    └── ace-terraform-subnet
        ├── CIDR: 10.20.0.0/24
        ├── Firewall: internal traffic
        ├── Firewall: SSH through IAP
        └── ace-terraform-vm
            ├── e2-micro
            ├── Debian 12
            ├── Private IP only
            └── NGINX
```

---

## Part A: GUI preparation

### Step 1: Open Google Cloud Console

Open the Google Cloud console and select your lab project.

### Step 2: Open Cloud Shell

Click:

```text
Activate Cloud Shell
```

Cloud Shell already includes common tools such as:

- `gcloud`
- Terraform
- Git
- `kubectl`
- Helm

### Step 3: Confirm the project

```bash
gcloud config get-value project
```

Set it when required:

```bash
gcloud config set project PROJECT_ID
```

### Step 4: Enable Compute Engine API

Through the console:

```text
Navigation menu
→ APIs & Services
→ Library
→ Search for Compute Engine API
→ Enable
```

CLI equivalent:

```bash
gcloud services enable compute.googleapis.com
```

---

## Part B: Create the Terraform project

```bash
mkdir -p ~/ace-terraform-lab
cd ~/ace-terraform-lab
```

---

## File 1: `versions.tf`

```bash
cat > versions.tf <<'EOF'
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
EOF
```

---

## File 2: `provider.tf`

```bash
cat > provider.tf <<'EOF'
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
EOF
```

---

## File 3: `variables.tf`

```bash
cat > variables.tf <<'EOF'
variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "asia-south1-a"
}

variable "network_name" {
  description = "Name of the custom VPC"
  type        = string
  default     = "ace-terraform-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "ace-terraform-subnet"
}

variable "subnet_cidr" {
  description = "Primary IPv4 CIDR range of the subnet"
  type        = string
  default     = "10.20.0.0/24"
}

variable "vm_name" {
  description = "Name of the Compute Engine instance"
  type        = string
  default     = "ace-terraform-vm"
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-micro"
}
EOF
```

---

## File 4: `main.tf`

```bash
cat > main.tf <<'EOF'
resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "ace_vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [
    google_project_service.compute_api
  ]
}

resource "google_compute_subnetwork" "ace_subnet" {
  name                     = var.subnet_name
  region                   = var.region
  network                  = google_compute_network.ace_vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_internal" {
  name      = "${var.network_name}-allow-internal"
  network   = google_compute_network.ace_vpc.name
  direction = "INGRESS"

  source_ranges = [
    var.subnet_cidr
  ]

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "${var.network_name}-allow-iap-ssh"
  network   = google_compute_network.ace_vpc.name
  direction = "INGRESS"

  source_ranges = [
    "35.235.240.0/20"
  ]

  target_tags = [
    "allow-iap-ssh"
  ]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_service_account" "vm_service_account" {
  account_id   = "ace-terraform-vm-sa"
  display_name = "ACE Terraform VM Service Account"
}

resource "google_compute_instance" "ace_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = [
    "allow-iap-ssh",
    "web-server"
  ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ace_subnet.id
  }

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    apt-get update
    apt-get install -y nginx

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
      <head>
        <title>ACE Terraform Lab</title>
      </head>
      <body>
        <h1>Infrastructure created using Terraform</h1>
        <p>VPC, subnet, firewall rules and VM deployed successfully.</p>
      </body>
    </html>
    HTML

    systemctl enable nginx
    systemctl restart nginx
  EOT

  labels = {
    environment = "lab"
    managed_by  = "terraform"
    phase       = "phase-20"
  }

  depends_on = [
    google_project_service.compute_api
  ]
}
EOF
```

---

## File 5: `outputs.tf`

```bash
cat > outputs.tf <<'EOF'
output "network_name" {
  description = "Created VPC network"
  value       = google_compute_network.ace_vpc.name
}

output "subnet_name" {
  description = "Created subnet"
  value       = google_compute_subnetwork.ace_subnet.name
}

output "vm_name" {
  description = "Created VM name"
  value       = google_compute_instance.ace_vm.name
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.ace_vm.network_interface[0].network_ip
}

output "vm_service_account" {
  description = "Service account attached to the VM"
  value       = google_service_account.vm_service_account.email
}

output "iap_ssh_command" {
  description = "Command for connecting to the VM through IAP"
  value       = "gcloud compute ssh ${google_compute_instance.ace_vm.name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}"
}
EOF
```

---

## File 6: `terraform.tfvars`

Set your project automatically:

```bash
PROJECT_ID="$(gcloud config get-value project)"
```

Create the variables file:

```bash
cat > terraform.tfvars <<EOF
project_id   = "${PROJECT_ID}"
region       = "asia-south1"
zone         = "asia-south1-a"
network_name = "ace-terraform-vpc"
subnet_name  = "ace-terraform-subnet"
subnet_cidr  = "10.20.0.0/24"
vm_name      = "ace-terraform-vm"
machine_type = "e2-micro"
EOF
```

Review:

```bash
cat terraform.tfvars
```

---

## Part C: Initialize and validate

### Step 1: Format

```bash
terraform fmt -recursive
```

### Step 2: Initialize

```bash
terraform init
```

Expected result:

```text
Terraform has been successfully initialized!
```

### Step 3: Validate

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

## Part D: Preview the deployment

```bash
terraform plan -out=tfplan
```

Review:

- Number of resources being created
- Project
- Region
- Zone
- CIDR range
- Firewall source ranges
- Whether the VM has an external IP
- Machine type
- Service account

Because the VM’s `network_interface` does not contain an `access_config` block, it will not receive an external IP.

---

## Part E: Apply

```bash
terraform apply tfplan
```

After completion:

```bash
terraform output
```

---

# 24. Verify Through CLI

## Verify the VPC

```bash
gcloud compute networks describe ace-terraform-vpc \
  --format="yaml(name,autoCreateSubnetworks,routingConfig.routingMode)"
```

Expected:

```text
autoCreateSubnetworks: false
routingMode: REGIONAL
```

---

## Verify the subnet

```bash
gcloud compute networks subnets describe ace-terraform-subnet \
  --region=asia-south1 \
  --format="yaml(name,region,ipCidrRange,privateIpGoogleAccess)"
```

---

## Verify firewall rules

```bash
gcloud compute firewall-rules list \
  --filter="network:ace-terraform-vpc" \
  --format="table(name,direction,sourceRanges.list():label=SOURCE_RANGES,allowed[].map().firewall_rule().list():label=ALLOW)"
```

---

## Verify the VM

```bash
gcloud compute instances describe ace-terraform-vm \
  --zone=asia-south1-a \
  --format="yaml(name,machineType,status,networkInterfaces,serviceAccounts)"
```

Confirm that:

- Status is `RUNNING`
- Internal IP exists
- External IP is absent
- Correct service account is attached

---

## View Terraform state

```bash
terraform state list
```

Expected resources include:

```text
google_compute_firewall.allow_iap_ssh
google_compute_firewall.allow_internal
google_compute_instance.ace_vm
google_compute_network.ace_vpc
google_compute_subnetwork.ace_subnet
google_project_service.compute_api
google_service_account.vm_service_account
```

Inspect the VM state:

```bash
terraform state show google_compute_instance.ace_vm
```

---

# 25. Verify Through Google Cloud Console

## VPC

Navigate to:

```text
Navigation menu
→ VPC network
→ VPC networks
→ ace-terraform-vpc
```

Verify:

- Mode: Custom
- Routing mode: Regional
- Subnet: `ace-terraform-subnet`
- CIDR: `10.20.0.0/24`

## Firewall

Navigate to:

```text
VPC network
→ Firewall
```

Verify:

- Internal traffic rule
- IAP SSH rule
- IAP source range `35.235.240.0/20`

## VM

Navigate to:

```text
Compute Engine
→ VM instances
→ ace-terraform-vm
```

Verify:

- `e2-micro`
- `asia-south1-a`
- No external IP
- Correct network and subnet
- Correct service account
- OS Login enabled

---

# 26. Test the VM

Because the VM has no external IP, connect through IAP:

```bash
gcloud compute ssh ace-terraform-vm \
  --zone=asia-south1-a \
  --tunnel-through-iap
```

Inside the VM:

```bash
systemctl status nginx --no-pager
```

Test locally:

```bash
curl http://localhost
```

Check startup-script logs:

```bash
sudo journalctl -u google-startup-scripts.service --no-pager
```

Exit:

```bash
exit
```

### Possible permission requirement

To SSH through IAP, your identity may need roles such as:

```text
roles/iap.tunnelResourceAccessor
roles/compute.osLogin
```

Additional permissions may be required depending on whether OS Login, service-account impersonation, and project-level access are configured.

---

# 27. Demonstrate Terraform Update

Change:

```hcl
machine_type = "e2-micro"
```

to:

```hcl
machine_type = "e2-small"
```

Or update `terraform.tfvars`:

```hcl
machine_type = "e2-small"
```

Run:

```bash
terraform plan
```

Study whether Terraform proposes:

- In-place update
- VM stop/start
- Resource replacement

Then apply:

```bash
terraform apply
```

For cost control, change it back to `e2-micro` after observing the plan.

---

# 28. Demonstrate Drift Detection

Through the console, add a label to the VM:

```text
manual-change = true
```

Run:

```bash
terraform plan
```

Terraform should detect that the actual labels differ from the configuration and propose restoring the configured label set.

Do not apply blindly. Read the plan and understand what Terraform wants to change.

---

# 29. Cleanup

Preview destruction:

```bash
terraform plan -destroy
```

Destroy:

```bash
terraform destroy
```

Confirm with:

```text
yes
```

Or, for the lab:

```bash
terraform destroy -auto-approve
```

Verify:

```bash
gcloud compute instances list \
  --filter="name=ace-terraform-vm"
```

```bash
gcloud compute networks list \
  --filter="name=ace-terraform-vpc"
```

The resources should no longer appear.

---

# 30. Common Terraform Errors

## Error 1: API not enabled

Example:

```text
Compute Engine API has not been used in project
```

Fix:

```bash
gcloud services enable compute.googleapis.com
```

---

## Error 2: Permission denied

Example:

```text
Error 403: Required permission compute.instances.create
```

Possible causes:

- User lacks IAM permission
- Terraform service account lacks permission
- Wrong project selected
- Service account impersonation is misconfigured

Check:

```bash
gcloud config get-value project
```

```bash
gcloud auth list
```

---

## Error 3: Invalid zone or unavailable machine type

Example:

```text
Machine type e2-micro does not exist in zone
```

Check:

```bash
gcloud compute machine-types list \
  --zones=asia-south1-a
```

---

## Error 4: Quota exceeded

Example:

```text
Quota CPUS exceeded
```

Check:

```text
IAM & Admin
→ Quotas & System Limits
```

Possible solutions:

- Use a smaller machine type
- Delete unused resources
- Choose another region
- Request quota increase

---

## Error 5: Resource already exists

Example:

```text
The resource already exists
```

Possible solutions:

1. Import the existing resource.
2. Rename the Terraform resource.
3. Delete the manually created resource.
4. Remove the conflicting configuration.

Do not delete an unknown production resource merely to make Terraform succeed.

---

## Error 6: State lock or concurrent deployment

This occurs when another Terraform operation is using the same state.

Do not force-unlock until you confirm that no legitimate Terraform process is active.

---

## Error 7: Backend initialization required

Run:

```bash
terraform init -reconfigure
```

For backend migration:

```bash
terraform init -migrate-state
```

---

# 31. Production Best Practices

## Repository structure

```text
terraform/
├── modules/
│   ├── network/
│   ├── compute/
│   └── iam/
└── environments/
    ├── dev/
    ├── staging/
    └── production/
```

## Security

- Avoid service account keys
- Use impersonation or Workload Identity Federation
- Apply least privilege
- Avoid broad primitive roles
- Protect Terraform state
- Do not place secrets in `.tfvars`
- Review IAM resources carefully
- Restrict firewall source ranges

## Reliability

- Use remote state
- Enable state-bucket versioning
- Pin provider versions
- Commit `.terraform.lock.hcl`
- Review every plan
- Use backups for stateful services
- Separate production and non-production state

## Automation

CI/CD should run:

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

Only approved pipelines should run:

```bash
terraform apply
```

## Governance

Use:

- Organization Policy
- IAM
- Policy as Code
- Approved modules
- Application Design Center templates
- Audit Logs
- Pull-request approval

---

# 32. ACE Exam Decision Table

| Scenario | Best answer |
|---|---|
| Repeatably create Google Cloud infrastructure from code | Terraform |
| Manage infrastructure across Google Cloud and another cloud | Terraform |
| Manage Google Cloud resources through Kubernetes YAML | Config Connector |
| Use a managed Kubernetes-style configuration control plane | Config Controller |
| Package and deploy an application to GKE | Helm |
| Standardize an enterprise Google Cloud landing zone | Fabric FAST or approved foundation blueprints |
| Generate and troubleshoot code from a terminal | Gemini CLI |
| Coordinate agentic code and terminal workflows | Google Antigravity |
| Get AI assistance across design, operations and optimization | Gemini Cloud Assist |
| Visually create and share standardized application architectures | Application Design Center |
| Preview infrastructure changes | `terraform plan` |
| Create the planned infrastructure | `terraform apply` |
| Initialize providers and backend | `terraform init` |
| Check Terraform configuration consistency | `terraform validate` |
| Remove Terraform-managed resources | `terraform destroy` |
| Adopt an existing resource | `terraform import` |
| Share Terraform state across a team | Remote backend, commonly Cloud Storage |
| Detect manual configuration drift | Run `terraform plan` |
| Reuse standardized Terraform logic | Module |

---

# 33. Practice Questions

## Question 1

An organization needs to create identical VPCs and subnets across development, testing, and production. All changes must be code-reviewed.

What should it use?

A. Cloud Shell history  
B. Terraform stored in Git  
C. Manually created VPC templates  
D. Repeated gcloud commands run by each administrator  

**Answer: B**

Terraform provides declarative, version-controlled, repeatable infrastructure.

---

## Question 2

A Kubernetes platform team wants to create Pub/Sub topics and Cloud SQL instances using Kubernetes YAML and `kubectl`.

What should it use?

A. Helm only  
B. Config Connector  
C. Cloud Deployment Manager  
D. VM Manager  

**Answer: B**

Config Connector exposes Google Cloud resources through Kubernetes custom resources.

---

## Question 3

Before deploying a Terraform change, an engineer wants to see exactly which resources will be created, updated, replaced, or deleted.

Which command should be used?

```bash
terraform plan
```

---

## Question 4

A team stores Terraform state on every engineer’s laptop. Engineers frequently overwrite one another’s changes.

What is the best improvement?

A. Email the state file before each deployment  
B. Commit the state file to a public Git repository  
C. Use a protected remote backend  
D. Run Terraform only from personal laptops  

**Answer: C**

A remote backend centralizes state and improves team coordination. State should not be committed to a normal source repository.

---

## Question 5

A GKE application requires a Deployment, Service, ConfigMap, Ingress, and Horizontal Pod Autoscaler. The team wants a reusable application package with configurable values.

What should it use?

A. Helm chart  
B. Terraform state  
C. Cloud NAT  
D. Instance template  

**Answer: A**

---

## Question 6

An administrator manually changes a Terraform-managed VM. What happens during the next `terraform plan`?

A. Terraform always ignores the manual change  
B. Terraform detects the difference and proposes reconciliation  
C. Terraform deletes its state automatically  
D. Terraform disables the Compute Engine API  

**Answer: B**

---

## Question 7

A platform team wants developers to select approved, visually designed Google Cloud architectures and deploy them as standardized Terraform-based applications.

What should it use?

A. Application Design Center  
B. Cloud Profiler  
C. Managed Service for Prometheus  
D. Cloud DNS  

**Answer: A**

---

## Question 8

What is the best role of generative AI in an infrastructure deployment?

A. Apply every generated configuration directly to production  
B. Replace IAM and organization policies  
C. Generate and analyze proposed infrastructure followed by validation and human review  
D. Store secrets directly in generated Terraform files  

**Answer: C**

---

# 34. Final Revision Summary

Remember this flow:

```text
Terraform configuration
        ↓
terraform init
        ↓
terraform fmt
        ↓
terraform validate
        ↓
terraform plan
        ↓
Review IAM, networking, cost and destruction
        ↓
terraform apply
        ↓
Verify resources
        ↓
terraform destroy when no longer needed
```

And remember the tool boundaries:

```text
Terraform
→ General infrastructure provisioning and lifecycle

Config Connector
→ Google Cloud resources through Kubernetes APIs

Config Controller
→ Managed Kubernetes-style configuration control plane

Helm
→ Package and deploy applications inside Kubernetes

Fabric FAST
→ Enterprise Google Cloud landing-zone framework

Gemini CLI
→ Terminal-based AI coding and infrastructure assistance

Google Antigravity
→ Agentic development and multi-agent workflows

Gemini Cloud Assist
→ AI assistance across cloud design, operations and optimization

Application Design Center
→ Visual, governed and reusable application architecture
```
