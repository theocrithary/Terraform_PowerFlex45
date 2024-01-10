# Pre-requisites

## Install Terraform
https://developer.hashicorp.com/terraform/install

### RHEL
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

### Ubuntu
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## Git clone repo
```
git clone https://github.com/theocrithary/Terraform_PowerFlex45.git
```

## Change to new directory path
```
cd Terraform_PowerFlex45
```

## Rename tfvars file for environment variables

```
mv terraform.tfvars.example terraform.tfvars
```

## Edit the tfvars file and replace all variables with your environment details
```
vi terraform.tfvars
```
# Step 1: Run the Terraform build to setup all required VM's

## Initialize, run the plan and apply the Terraform
```
terraform init && terraform plan && terraform apply -auto-approve
```

# Step 2: Run the installer scripts to setup and install the PFMP

## SSH to the installer VM with root account
```
ssh root@<pf_installer_ip>  ## use the ip address of the installer VM
```

## Run the setup installer script
```
/opt/dell/pfmp/PFMP_Installer/scripts/setup_installer.sh
```

## Run the installer script
```
/opt/dell/pfmp/PFMP_Installer/scripts/install_PFMP.sh

Are ssh keys used for authentication connecting to the cluster nodes[Y]?:no
Please enter the ssh username for the nodes specified in the PFMP_Config.json[root]:<enter>
Are passwords the same for all the cluster nodes[Y]?:<enter>
Please enter the ssh password for the nodes specified in the PFMP_Config.json.
Password:<root_password>
```

- This process will take some time to complete, allow an hour or so to finish all tasks
- You can monitor the progress with the below log file;

```
tail -f /opt/dell/pfmp/atlantic/logs/bedrock.log
```

## Delete the installer VM

- Once the above script has completed and confirmed via the logs, you can then power off and delete the PFMP installer VM by logging into the vSphere client manually.

# Login to PowerFlex Manager & perform initial setup

- Use a browser to open the PowerFlex Manager console
https://powerflex.iac.ssc/

- Login with the default user account
admin / Admin123!

- Change the password when prompted

- Step through the Initial Config Wizard and select "I want to deploy a new instance of PowerFlex"

- Upload the compliance bundle (PowerFlex_Software_4.5.0.0_287_r1.zip) - requires a CIFs/SMB file share to host the file or a web server such as AWS S3 with a public URL such as https://pflex-packages.s3.eu-west-1.amazonaws.com/pflex-45/Software_Only_Complete_4.5.0_287/PowerFlex_Software_4.5.0.0_287_r1.zip

- The package download will take a few mins to complete, but will raise a critical warning. Action it by allowing unsigned package.

- Upload the compatibility management version file (cm-20230901.gpg)
     - Settings -> compatibility management -> upload file

- Go back to the installation configuration wizard page by navigating to the ? in the top right and clicking on 'getting started'

- Configure the networks
      - Define networks -> Define
      - Name: powerflex-data
      - Network Type: PowerFlex Data
      - VLAN ID: 1
      - Subnet: 192.168.10.0
      - Subnet Mask: 255.255.255.0
      - Gateway: 192.168.10.1
      - Primary DNS: 192.168.10.10
      - Secondary DNS: 192.168.10.69-192.168.10.72
      - DNS Suffix: lab.local
      - IP Address Range
      - Role: Server or Client
      - Starting IP: 192.168.10.69
      - Ending IP: 192.168.10.72

      - Define networks -> Define
      - Name: powerflex-mgmt
      - Network Type: PowerFlex Data
      - VLAN ID: 1
      - Subnet: 192.168.10.0
      - Subnet Mask: 255.255.255.0
      - Gateway: 192.168.10.1
      - Primary DNS: 192.168.10.10
      - Secondary DNS: 192.168.10.69-192.168.10.72
      - DNS Suffix: lab.local
      - IP Address Range
      - Role: Server or Client
      - Starting IP: 192.168.10.69
      - Ending IP: 192.168.10.72

- Discover Resources
      - Resource Type: Node (Software Management)
      - IP/Hostname Range: Start IP: 192.168.10.69 End IP: 192.168.10.72
      - Resource State: Managed
      - Discover into Node Pool: Global
      - Credentials: click on the + icon and create a new OS Admin credential with the root password for the storage nodes

# Install PowerFlex software on storage nodes to create MDM cluster with 4 x SDS nodes

- Confirm discovered resources by navigating to the 'Resources' tab and exploring the node and node pool details
      - Compliance: Unknown
      - Deployment Status: Not in Use
      - Managed State: Managed

- Create a new template by navigating to the 'Lifecycle' tab and selecting 'Templates'
      - Create
      - Create a new template and provide a name
      - Select a template category and select the 'PowerFlex 4.5.0.0' firmware and software compliance
      - Choose the 'PowerFlex SuperUser and All LifecycleAdmin and DriveReplacer' role to have access to the resource group
      - Save
      - Add Node
      - Component Name: Node (Software Only)
      - Number of Instances: 4
      - OS: Ubuntu
      - Use Node For Dell PowerFlex: tick
      - PowerFlex Role: Storage Only
      - Client Storage Access: SDC Only
      - Enable Replication: tick
      - Node Pool: Global
      - Interfaces -> Add Interface -> Choose Networks
      - Select 'powerflex-data' and click >> to add to the template and save
      - Add Cluster -> PowerFlex Cluster
      - Associate Selected: Node (Software Only): tick
      - Target Gateway: PowerFlex System
      - All other settings as default and save
      - Publish Template

- Deploy a new resource group
      - Select the template and click 'Deploy Resource Group'
      - Provide a name for the resource group and click next
      - Use all the default settings, except the following;
      - Journal Capacity: Default 10%
      - MDM Virtual IP Source: User Entered IP
      - PowerFlex-data IP Source: Manual Entry
      - PowerFlex-data IP Address: 192.168.10.73 (a seperate IP assigned as the VIP for the MDM cluster)






# Troubleshooting

## Timeout errors
All actions are idempotent, so you can run the following command as many times as needed to complete the build successfully.
```
terraform apply -auto-approve
```
- If you get any errors or the process does not complete, try running it again.
- Once completed, you should see a message similar to the below;
```
Apply complete! Resources: 0 added, 8 changed, 0 destroyed.
```

## Unable to login to 1 or more nodes
- Try manually logging in to the effected host with either the 'ubuntu' or 'root' account
- If you are unable to login to root, but ubuntu is accessible, then try restarting the SSH daemon

```
sudo service sshd restart
exit
terraform apply -auto-approve
```