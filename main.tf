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
resource "vsphere_virtual_machine" "vm" {
  name             = var.pfmp_mgmt_node_1_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
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