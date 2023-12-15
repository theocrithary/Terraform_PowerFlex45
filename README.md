## Pre-requisites

# Install Terraform
https://developer.hashicorp.com/terraform/install

## RHEL
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

## Ubuntu
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

# Git clone repo
```
git clone https://github.com/theocrithary/Terraform_PowerFlex45.git
```

# Change to new directory path
```
cd Terraform_PowerFlex45
```

# Rename tfvars file for environment variables
```
mv terraform.tfvars.example terraform.tfvars
```

# Edit the tfvars file and replace all variables with your environment details
```
vi terraform.tfvars
```

# Initialize, run the plan and apply the Terraform
```
terraform init && terraform plan && terraform apply -auto-approve
```