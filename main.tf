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

data "vsphere_content_library_item" "template" {
  name       = var.vsphere_template
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

## Deployment of PFMP-1 from Template
resource "vsphere_virtual_machine" "pfmp-1" {
  name             = var.pfmp_mgmt_node_1_name
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
    template_uuid = data.vsphere_content_library_item.template.id
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
    template_uuid = data.vsphere_content_library_item.template.id
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
    template_uuid = data.vsphere_content_library_item.template.id
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
      "shutdown -r now"
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
      "shutdown -r now"
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
      "shutdown -r now"
    ]
  }
}