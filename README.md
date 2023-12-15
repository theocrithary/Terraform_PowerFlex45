
git clone https://github.com/theocrithary/Terraform_PowerFlex45.git

cd Terraform_PowerFlex45

mv terraform.tfvars.example terraform.tfvars

(edit the tfvars file and replace all variables with your environment details)

terraform init && terraform plan && terraform apply -auto-approve