# TF-Infra

Terraform Infrastructure-as-Code (IaC) repository for provisioning AWS and GCP resources.

This repository follows environment isolation using separate local clones (dev and demo) with shared Terraform configuration files and environment-specific `terraform.tfvars`.

Structure

```
tf-infra/
├── aws/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ ├── providers.tf
│ └── terraform.tfvars
├── gcp/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ ├── providers.tf
│ └── terraform.tfvars
└── .github/workflows/terraform-ci.yml
```

* Common `.tf` files across environments

* Environment-specific values in `terraform.tfvars`

* Separate Terraform state per environment (via separate local clones)

## Environment Setup

### Fork the Repository

Fork the organization tf-infra repository to your GitHub account.

### Clone for Dev Environment

```
git clone git@github.com
:<your-username>/tf-infra.git tf-infra-dev
```

### Clone for Demo Environment

```
git clone git@github.com
:<your-username>/tf-infra.git tf-infra-demo
```

>[!NOTE]
>Each clone maintains its own Terraform state.

### Configure Upstream Remote

#### Run inside both local clones:

```
git remote add upstream git@github.com
:csye6225-cloud-spring26/tf-infra.git
git fetch upstream
```

#### Verify:

```
git remote -v
```
---
#### Naming Convention

>[!NOTE]
>Resources are named with their environment for easy distinction:

```
${app_name}-${env_name}-resource_type
```

Example:

* `csye6225-dev-vpc`

* `csye6225-demo-subnet-1`

#### `env_name` is passed through `terraform.tfvars`.

## CLI Setup for Terraform

These steps are for a new user who has access to the repository and wants to run Terraform locally.

### AWS CLI

#### Install AWS CLI: Download link

#### Configure profiles for environments

```
aws configure --profile dev
aws configure --profile demo
```

#### Verify profile access

```
aws sts get-caller-identity --profile dev
aws sts get-caller-identity --profile demo
```

>[!NOTE]
>Ensure the correct profile (dev or demo) matches the terraform.tfvars configuration when running Terraform.

### GCP CLI

Authenticate Terraform with GCP

```
gcloud auth login
gcloud auth application-default login
```

Switch to the correct configuration

```
gcloud config configurations activate dev # or demo
```

 Verify the project ID matches the one in the `.tfvars`
```
gcloud config get-value project
```

>[!NOTE]
>Terraform uses the active configuration and Application Default Credentials (ADC) to authenticate. Make sure the project matches the one in your terraform.tfvars.

### Prerequisites

* Terraform >= 1.5

* AWS CLI installed and profiles configured

* GCP CLI installed, active configuration set, and ADC configured

* Git with forked repository access

## Usage
### Initialize

#### For AWS resources
```
cd aws          
```
#### For GCP resources
```
cd gcp          
```
#### Initialize Terraform
```
terraform init
```
#### Format & Validate

```
terraform fmt -recursive
terraform validate
```
#### Plan

```
terraform plan -var-file=terraform.tfvars
```

Apply

```
terraform apply -var-file=terraform.tfvars
```

Destroy

```
terraform destroy -var-file=terraform.tfvars
```

## Notes
> Each clone maintains its own Terraform state and configuration, including environment-specific values such as project_id, region, and terraform.tfvars. 

> Keep your environment clean by destroying resources after testing if not required for active work.

> Always verify the active AWS profile or GCP configuration matches your intended environment before running Terraform.