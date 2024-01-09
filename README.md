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

# Troubleshooting

## Timeout errors
All actions are idempotent, so you can run the following command as many times as needed to complete the build successfully.
```
terraform apply -auto-approve
```
If you get any errors or the process does not complete, try running it again.
Once completed, you should see a message similar to the below;
```
Apply complete! Resources: 0 added, 8 changed, 0 destroyed.
```

## Unable to login to 1 or more nodes
Try manually logging in to the effected host with either the 'ubuntu' or 'root' account
If you are unable to login to root, but ubuntu is accessible, then try restarting the SSH daemon
```
sudo service sshd restart
exit
terraform apply -auto-approve
```