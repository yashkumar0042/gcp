Below is a simple Terraform project that creates:

* A **VPC Network**
* A **Custom Subnet**
* A **Firewall rule** (SSH + HTTP)
* A **Compute Engine VM** inside the subnet

## Project Structure

```text
terraform-gcp/
│── provider.tf
│── variables.tf
│── main.tf
│── outputs.tf
```

---

# provider.tf

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
```

---

# variables.tf

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}
```

---

# main.tf

```hcl
############################
# VPC
############################

resource "google_compute_network" "vpc" {
  name                    = "terraform-vpc"
  auto_create_subnetworks = false
}

############################
# Custom Subnet
############################

resource "google_compute_subnetwork" "subnet" {
  name          = "terraform-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/24"
}

############################
# Firewall Rule
############################

resource "google_compute_firewall" "allow-ssh-http" {
  name    = "allow-ssh-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

############################
# VM Instance
############################

resource "google_compute_instance" "vm" {
  name         = "terraform-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
    }
  }

  metadata_startup_script = <<EOF
#!/bin/bash
apt update
apt install apache2 -y
echo "<h1>Hello from Terraform VM</h1>" > /var/www/html/index.html
systemctl enable apache2
systemctl start apache2
EOF
}
```

---

# outputs.tf

```hcl
output "vm_name" {
  value = google_compute_instance.vm.name
}

output "vm_external_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}
```

---

# terraform.tfvars

Create a file named **terraform.tfvars**

```hcl
project_id = "YOUR_PROJECT_ID"

region = "us-central1"

zone = "us-central1-a"
```

Example:

```hcl
project_id = "my-gcp-project-12345"

region = "us-central1"

zone = "us-central1-a"
```

---

# Commands

Initialize Terraform

```bash
terraform init
```

Check the execution plan

```bash
terraform plan
```

Create the resources

```bash
terraform apply
```

Type:

```text
yes
```

View outputs

```bash
terraform output
```

Example:

```text
vm_external_ip = "34.xx.xx.xx"
vpc_name = "terraform-vpc"
subnet_name = "terraform-subnet"
```

Destroy everything

```bash
terraform destroy
```

---

## Resources Created

| Resource     | Name             |
| ------------ | ---------------- |
| VPC          | terraform-vpc    |
| Subnet       | terraform-subnet |
| Firewall     | allow-ssh-http   |
| VM           | terraform-vm     |
| Machine Type | e2-micro         |
| OS           | Debian 12        |
| Web Server   | Apache2          |

This is a clean beginner-friendly Terraform configuration. As you advance, you can split it into reusable modules (VPC, firewall, compute), use remote state (e.g., GCS backend), and parameterize machine type, image, tags, and startup scripts for production deployments.
