#######################################################################
## Init: Setup variables to connect to vCenter server
#######################################################################

provider "vsphere" {
  user = var.vsphere_user
  password = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name = var.vsphere_datastore
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_network" "network" {
  name = var.vsphere_network
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "default" {
  name          = format("%s%s", data.vsphere_compute_cluster.cluster.name, "/Resources")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name = var.vsphere_host
  datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

data "vsphere_content_library" "library" {
  name = var.vsphere_content_library
}

data "vsphere_content_library_item" "k8s_template" {
  name       = var.k8s_template
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

data "vsphere_content_library_item" "installer_template" {
  name       = var.pf_installer_template
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

data "vsphere_content_library_item" "storage_node_template" {
  name       = var.storage_node_template
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

#######################################################################
## Stage 1: Deploy the 3 x PFMP nodes to be used for K8s cluster
#######################################################################

## Deployment of PFMP-1 from Template
resource "vsphere_virtual_machine" "pfmp-1" {
  name             = var.pfmp_mgmt_node_1_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 14
  memory           = 32768
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 600
    thin_provisioned = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.k8s_template.id
    customize {
      network_interface {
        ipv4_address = var.pfmp_mgmt_node_1_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.pfmp_mgmt_node_1_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Deployment of PFMP-2 from Template
resource "vsphere_virtual_machine" "pfmp-2" {
  name             = var.pfmp_mgmt_node_2_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 4
  memory           = 4096
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 600
    thin_provisioned = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.k8s_template.id
    customize {
      network_interface {
        ipv4_address = var.pfmp_mgmt_node_2_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.pfmp_mgmt_node_2_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Deployment of PFMP-3 from Template
resource "vsphere_virtual_machine" "pfmp-3" {
  name             = var.pfmp_mgmt_node_3_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 4
  memory           = 4096
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 600
    thin_provisioned = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.k8s_template.id
    customize {
      network_interface {
        ipv4_address = var.pfmp_mgmt_node_3_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.pfmp_mgmt_node_3_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Change root password

resource "null_resource" "powerflex45_mgmt_node_1_changerootpassword" {
  connection {
      type     = "ssh"
      user     = "delladmin"
      password = "delladmin"
      host     = var.pfmp_mgmt_node_1_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "sudo chpasswd <<<root:${var.root_password}"
    ]
  }
}

resource "null_resource" "powerflex45_mgmt_node_2_changerootpassword" {
  connection {
      type     = "ssh"
      user     = "delladmin"
      password = "delladmin"
      host     = var.pfmp_mgmt_node_2_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "sudo chpasswd <<<root:${var.root_password}"
    ]
  }
}

resource "null_resource" "powerflex45_mgmt_node_3_changerootpassword" {
  connection {
      type     = "ssh"
      user     = "delladmin"
      password = "delladmin"
      host     = var.pfmp_mgmt_node_3_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "sudo chpasswd <<<root:${var.root_password}"
    ]
  }
}

resource "time_sleep" "wait_for_rootpasswordchange" {
  create_duration = "20s"
  depends_on = [ null_resource.powerflex45_mgmt_node_1_changerootpassword, null_resource.powerflex45_mgmt_node_2_changerootpassword, null_resource.powerflex45_mgmt_node_3_changerootpassword ]
}

## Login with root account and disable firewall, setup chrony, install kubectl client, remove additional NIC config files and reboot server

resource "null_resource" "powerflex45_mgmt_node_1_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.pfmp_mgmt_node_1_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "systemctl stop firewalld",
      "systemctl disable firewalld",
      "systemctl mask --now firewalld",      
      "echo 'pool pool.ntp.org iburst' >> /etc/chrony.conf",
      "systemctl enable chronyd",
      "rm -rf /etc/sysconfig/network/ifcfg-eth1",
      "rm -rf /etc/sysconfig/network/ifcfg-eth2",
      "rm -rf /etc/sysconfig/network/ifcfg-eth3",
      "sudo reboot &",
      "echo REBOOTING"
    ]
  }
}

resource "null_resource" "powerflex45_mgmt_node_2_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.pfmp_mgmt_node_2_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "systemctl stop firewalld",
      "systemctl disable firewalld",
      "systemctl mask --now firewalld",      
      "echo 'pool pool.ntp.org iburst' >> /etc/chrony.conf",
      "systemctl enable chronyd",
      "sudo reboot &",
      "echo REBOOTING"
    ]
  }
}

resource "null_resource" "powerflex45_mgmt_node_3_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.pfmp_mgmt_node_3_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "systemctl stop firewalld",
      "systemctl disable firewalld",
      "systemctl mask --now firewalld",      
      "echo 'pool pool.ntp.org iburst' >> /etc/chrony.conf",
      "systemctl enable chronyd",
      "sudo reboot &",
      "echo REBOOTING"
    ]
  }
}

#######################################################################
## Stage 2: Deploy the installer VM
#######################################################################

## Deployment of PF Installer VM from Template
resource "vsphere_virtual_machine" "installer-vm" {
  name             = var.pf_installer_vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 8
  memory           = 8192
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 100
    thin_provisioned = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.installer_template.id
    customize {
      network_interface {
        ipv4_address = var.pf_installer_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.pf_installer_vm_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Prepare the PFMP_Config.json file

resource "local_file" "PFMP_Config" {
  content  = <<EOT
  {
    "Nodes":
    [
      {
        "hostname": "${var.pfmp_mgmt_node_1_name}",
        "ipaddress": "${var.pfmp_mgmt_node_1_ip}"
      },
      {
        "hostname": "${var.pfmp_mgmt_node_2_name}",
        "ipaddress": "${var.pfmp_mgmt_node_2_ip}"
      },
      {
        "hostname": "${var.pfmp_mgmt_node_3_name}",
        "ipaddress": "${var.pfmp_mgmt_node_3_ip}"
      }
    ],
 
    "ClusterReservedIPPoolCIDR" : "10.42.0.0/23",
 
    "ServiceReservedIPPoolCIDR" : "10.43.0.0/23",
 
    "RoutableIPPoolCIDR" : [
	  {
	    "mgmt":"${var.ip_pool_for_pfmp_services}"
	  }
    ],
    
    "PFMPHostname" : "${var.hostname_for_pfmp_ui}",
  
    "PFMPHostIP" : "${var.vip_for_pfmp_ui}"
  }
  EOT

  filename = "${path.module}/PFMP_Config.json"
}

## Change root password

resource "null_resource" "pf_installer_changerootpassword" {
  connection {
      type     = "ssh"
      user     = "delladmin"
      password = "delladmin"
      host     = var.pf_installer_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chpasswd <<<root:${var.root_password}"
    ]
  }
}
resource "time_sleep" "wait_for_rootpasswordchange2" {
  create_duration = "20s"
  depends_on = [ null_resource.pf_installer_changerootpassword ]
}

## Login as root to disable firewall, setup chrony, 
resource "null_resource" "pf_installer_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange2]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.pf_installer_ip
  }
    provisioner "file" {
    source      = "PFMP_Config.json"
    destination = "/opt/dell/pfmp/PFMP_Installer/config/PFMP_Config.json"
  }
  
  provisioner "remote-exec" {
    inline = [
      "systemctl stop firewalld",
      "systemctl disable firewalld",
      "systemctl mask --now firewalld",      
      "echo 'pool pool.ntp.org iburst' >> /etc/chrony.conf",
      "systemctl enable chronyd",
      "sysctl -w net.ipv4.ip_forward=1",
      "sudo reboot &",
      "echo REBOOTING"
    ]
  }
}

#######################################################################
## Stage 3: Deploy the 4 x Storage Node VM's
#######################################################################

## Deployment of PowerFlex-Storage-Node-1 VM from Template
resource "vsphere_virtual_machine" "powerflex-node-1" {
  name             = var.powerflex_node_1_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 12
  memory           = 20480
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 32
    thin_provisioned = true
  }
  disk {
    label = "disk1"
    size  = 200
    thin_provisioned = true
    unit_number = 1
  }
  clone {
    template_uuid = data.vsphere_content_library_item.storage_node_template.id
    customize {
      network_interface {
        ipv4_address = var.powerflex_node_1_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.powerflex_node_1_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Deployment of PowerFlex-Storage-Node-2 VM from Template
resource "vsphere_virtual_machine" "powerflex-node-2" {
  name             = var.powerflex_node_2_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 12
  memory           = 20480
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 32
    thin_provisioned = true
  }
  disk {
    label = "disk1"
    size  = 200
    thin_provisioned = true
    unit_number = 1
  }
  clone {
    template_uuid = data.vsphere_content_library_item.storage_node_template.id
    customize {
      network_interface {
        ipv4_address = var.powerflex_node_2_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.powerflex_node_2_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Deployment of PowerFlex-Storage-Node-3 VM from Template
resource "vsphere_virtual_machine" "powerflex-node-3" {
  name             = var.powerflex_node_3_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 12
  memory           = 20480
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 32
    thin_provisioned = true
  }
  disk {
    label = "disk1"
    size  = 200
    thin_provisioned = true
    unit_number = 1
  }
  clone {
    template_uuid = data.vsphere_content_library_item.storage_node_template.id
    customize {
      network_interface {
        ipv4_address = var.powerflex_node_3_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.powerflex_node_3_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Deployment of PowerFlex-Storage-Node-4 VM from Template
resource "vsphere_virtual_machine" "powerflex-node-4" {
  name             = var.powerflex_node_4_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 12
  memory           = 20480
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 32
    thin_provisioned = true
  }
  disk {
    label = "disk1"
    size  = 200
    thin_provisioned = true
    unit_number = 1
  }
  clone {
    template_uuid = data.vsphere_content_library_item.storage_node_template.id
    customize {
      network_interface {
        ipv4_address = var.powerflex_node_4_ip
        ipv4_netmask = var.subnet_netmask
      }
      ipv4_gateway = var.subnet_gateway
      dns_server_list = [var.dns_server_list]
      dns_suffix_list = [var.dns_suffix]
      linux_options {
        host_name = var.powerflex_node_4_name
        domain    = var.dns_suffix
      }
    }
  }
}

## Change root password

resource "null_resource" "powerflex_node_1_changerootpassword" {
  connection {
      type     = "ssh"
      user     = var.ubuntu_template_username
      password = var.ubuntu_template_password
      host     = var.powerflex_node_1_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "printf ${var.ubuntu_template_password} | sudo -S apt update -y",
      "printf \"${var.root_password}\n${var.root_password}\" | sudo passwd root",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    ]
  }
}

resource "null_resource" "powerflex_node_2_changerootpassword" {
  connection {
      type     = "ssh"
      user     = var.ubuntu_template_username
      password = var.ubuntu_template_password
      host     = var.powerflex_node_2_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "printf ${var.ubuntu_template_password} | sudo -S apt update -y",
      "printf \"${var.root_password}\n${var.root_password}\" | sudo passwd root",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    ]
  }
}

resource "null_resource" "powerflex_node_3_changerootpassword" {
  connection {
      type     = "ssh"
      user     = var.ubuntu_template_username
      password = var.ubuntu_template_password
      host     = var.powerflex_node_3_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "printf ${var.ubuntu_template_password} | sudo -S apt update -y",
      "printf \"${var.root_password}\n${var.root_password}\" | sudo passwd root",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    ]
  }
}

resource "null_resource" "powerflex_node_4_changerootpassword" {
  connection {
      type     = "ssh"
      user     = var.ubuntu_template_username
      password = var.ubuntu_template_password
      host     = var.powerflex_node_4_ip
  }
  // change permissions to executable and pipe its output into a new file
  provisioner "remote-exec" {
    inline = [
      "printf ${var.ubuntu_template_password} | sudo -S apt update -y",
      "printf \"${var.root_password}\n${var.root_password}\" | sudo passwd root",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    ]
  }
}

resource "time_sleep" "wait_for_rootpasswordchange3" {
  create_duration = "20s"
  depends_on = [ null_resource.powerflex_node_1_changerootpassword, null_resource.powerflex_node_2_changerootpassword, null_resource.powerflex_node_3_changerootpassword, null_resource.powerflex_node_4_changerootpassword ]
}

## Login as root to install pre-req packages 
resource "null_resource" "powerflex_node_1_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange3]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.powerflex_node_1_ip
  }
  provisioner "remote-exec" {
    inline = [
      "apt update -y",
      "apt install unzip sshpass numactl libaio1 wget libapr1 libaprutil1 bash-completion binutils openjdk-11-jdk-headless smartmontools sg3-utils hdparm pciutils sysstat jq openssl libaio1 linux-image-extra-virtual libnuma1 -y"
    ]
  }
}

## Login as root to install pre-req packages 
resource "null_resource" "powerflex_node_2_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange3]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.powerflex_node_2_ip
  }
  provisioner "remote-exec" {
    inline = [
      "apt update -y",
      "apt install unzip sshpass numactl libaio1 wget libapr1 libaprutil1 bash-completion binutils openjdk-11-jdk-headless smartmontools sg3-utils hdparm pciutils sysstat jq openssl libaio1 linux-image-extra-virtual libnuma1 -y"
    ]
  }
}

## Login as root to install pre-req packages 
resource "null_resource" "powerflex_node_3_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange3]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.powerflex_node_3_ip
  }
  provisioner "remote-exec" {
    inline = [
      "apt update -y",
      "apt install unzip sshpass numactl libaio1 wget libapr1 libaprutil1 bash-completion binutils openjdk-11-jdk-headless smartmontools sg3-utils hdparm pciutils sysstat jq openssl libaio1 linux-image-extra-virtual libnuma1 -y"
    ]
  }
}

## Login as root to install pre-req packages 
resource "null_resource" "powerflex_node_4_bootstrap" {
  depends_on = [time_sleep.wait_for_rootpasswordchange3]
  connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.powerflex_node_4_ip
  }
  provisioner "remote-exec" {
    inline = [
      "apt update -y",
      "apt install unzip sshpass numactl libaio1 wget libapr1 libaprutil1 bash-completion binutils openjdk-11-jdk-headless smartmontools sg3-utils hdparm pciutils sysstat jq openssl libaio1 linux-image-extra-virtual libnuma1 -y"
    ]
  }
}