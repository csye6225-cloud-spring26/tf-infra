## TF-Infra

Terraform Infrastructure-as-Code (IaC) repository for provisioning networking resources in AWS and GCP.

This repository follows environment isolation using separate local clones (dev and demo) with shared Terraform configuration files and environment-specific `terraform.tfvars`.

### Structure

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

### Environment Setup
#### Fork the Repository

* Fork the organization tf-infra repository to your GitHub account.

#### Clone for Dev Environment

```
git clone git@github.com:<your-username>/tf-infra.git tf-infra-dev
```

#### Clone for Demo Environment

```
git clone git@github.com:<your-username>/tf-infra.git tf-infra-demo
```

> [!NOTE]  
> Each clone maintains its own Terraform state.

### Configure Upstream Remote

Run inside both local clones:

```
git remote add upstream git@github.com
:csye6225-cloud-spring26/tf-infra.git
git fetch upstream
```

Verify:

```
git remote -v
```

### Naming Convention

> [!NOTE]  
> It is a good practice to name the resources with their environments to distinguish them easily
```
${app_name}-${env_name}-resource_type
```

Example:

* `csye6225-dev-vpc`

* `csye6225-demo-public-subnet-1`

* `env_name` is passed through `terraform.tfvars`.

### Prerequisites

* Terraform >= 1.5

* AWS CLI configured (region: us-east-1)

* GCP CLI configured

* Git with forked repository access

### Usage

#### Initialize

```
cd aws # or gcp
terraform init
```

Format & Validate

```
terraform fmt
terraform validate
```

Plan

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