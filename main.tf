# Terraform Block with Required Providers
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"  
    }
  }
  required_version = ">= 1.0.0"  
}

# Define Terraform Variables
variable "gcp_creds" {
  default = "./resources/gitops-poc-1-0b406afbb75c.json" 
}

variable "ssh_public_key" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxluP3kBLdL9uvyWEkl2RUmKQ028hde/HwtOjY10hrz ssh-user"
}

# Google Provider Configuration
provider "google" {
  credentials = file(var.gcp_creds)  # Service account key
  project     = "gitops-poc-1"  
  region      = "us-central1"  
}

# Create VPC and Subnet
resource "google_compute_network" "gitops_poc_vpc" {
  name                    = "gitops-poc-vpc"
  auto_create_subnetworks = false 
}

resource "google_compute_subnetwork" "gitops_poc_vpc_subnet" {
  name          = "gitops-poc-vpc-subnet"
  network       = google_compute_network.gitops_poc_vpc.name
  region        = "us-central1"
  ip_cidr_range = "10.2.0.0/16"  # Define the IP range for the subnet
}

# Firewall Rule to Allow SSH and Other Traffic
resource "google_compute_firewall" "allow_ssh_and_all" {
  name    = "allow-ssh-and-all"
  network = google_compute_network.gitops_poc_vpc.name

  direction     = "INGRESS"  # Ingress indicates inbound traffic
  source_ranges = ["0.0.0.0/0"]  # Allow all source IP addresses

  # Define what traffic to allow
  allow {
    protocol = "tcp"
    ports    = ["22"]  # Allow SSH on port 22
  }

  allow {
    protocol = "icmp"  # Allow ICMP traffic (like ping)
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]  # Allow all TCP ports
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]  # Allow all UDP ports
  }
}


# Create the k8smaster VM with SSH Access
resource "google_compute_instance" "k8smaster" {
  name         = "k8smaster"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"  # Ubuntu OS
      size  = 20  # Boot disk size in GB
    }
  }

  network_interface {
    network    = google_compute_network.gitops_poc_vpc.self_link
    subnetwork = google_compute_subnetwork.gitops_poc_vpc_subnet.self_link
    access_config {
      # Enable external IP (NAT)
    }
  }

  metadata = {
    "ssh-keys" = "ssh-user:${var.ssh_public_key}"  # SSH public key with defined username
  }

  shielded_instance_config {
    enable_vtpm              = true  # Enable vTPM for enhanced security
    enable_integrity_monitoring = true  # Enable Integrity Monitoring
  }
}

# Create the k8sworker1 VM with SSH Access
resource "google_compute_instance" "k8sworker1" {
  name         = "k8sworker1"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"  # Ubuntu OS
      size  = 20  # Disk size in GB
    }
  }

  network_interface {
    network    = google_compute_network.gitops_poc_vpc.self_link
    subnetwork = google_compute_subnetwork.gitops_poc_vpc_subnet.self_link
    access_config {
      # Enable external IP (NAT)
    }
  }

  metadata = {
    "ssh-keys" = "ssh-user:${var.ssh_public_key}"  # SSH public key with defined username
  }

  shielded_instance_config {
    enable_vtpm              = true  # Enable vTPM
    enable_integrity_monitoring = true  # Integrity Monitoring
  }
}

# Create the ops VM with SSH Access
resource "google_compute_instance" "ops" {
  name         = "ops"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"  # Ubuntu OS
      size  = 20  # Disk size in GB
    }
  }

  network_interface {
    network    = google_compute_network.gitops_poc_vpc.self_link
    subnetwork = google_compute_subnetwork.gitops_poc_vpc_subnet.self_link
    access_config {
      # Enable external IP (NAT)
    }
  }

  metadata = {
    "ssh-keys" = "ssh-user:${var.ssh_public_key}"  # SSH public key with defined username
  }

  shielded_instance_config {
    enable_vtpm              = true  # Enable vTPM
    enable_integrity_monitoring = true  # Integrity Monitoring
  }
}

# Terraform Outputs to Get Public IPs and SSH Usernames
output "k8smaster_public_ip" {
  value = google_compute_instance.k8smaster.network_interface[0].access_config[0].nat_ip
}

output "k8sworker1_public_ip" {
  value = google_compute_instance.k8sworker1.network_interface[0].access_config[0].nat_ip
}

output "ops_public_ip" {
  value = google_compute_instance.ops.network_interface[0].access_config[0].nat_ip
}

output "ssh_user" {
  value = "ssh-user"  # The SSH username
}
