variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_datacenter" {
  description = "vSphere data center"
  type        = string
}

variable "vsphere_cluster" {
  description = "vSphere cluster"
  type        = string
}

variable "vsphere_datastore" {
  description = "vSphere datastore"
  type        = string
}

variable "vsphere_network" {
  description = "vSphere network name"
  type        = string
}

variable "vsphere_content_library" {
  description = "vSphere content library"
  type        = string
}

variable "k8s_template" {
  description = "k8s template name"
  type        = string
}

variable "vsphere_host" {
  description = "vSphere host name"
  type        = string
}

variable "subnet_gateway" {
  description = "network default gateway"
  type        = string
}

variable "subnet_netmask" {
  description = "network subnet mask"
  type        = string
}

variable "dns_server_list" {
  description = "dns server list"
  type        = string
}

variable "dns_suffix" {
  description = "dns suffix / domain name"
  type        = string
}

variable "pfmp_mgmt_node_1_ip" {
  description = "PFMP 1 management IP"
  type        = string
}

variable "pfmp_mgmt_node_2_ip" {
  description = "PFMP 2 management IP"
  type        = string
}

variable "pfmp_mgmt_node_3_ip" {
  description = "PFMP 3 management IP"
  type        = string
}

variable "pfmp_mgmt_node_1_name" {
  description = "PFMP 1 host name"
  type        = string
}

variable "pfmp_mgmt_node_2_name" {
  description = "PFMP 2 host name"
  type        = string
}

variable "pfmp_mgmt_node_3_name" {
  description = "PFMP 3 host name"
  type        = string
}

variable "root_password" {
  description = "default root password"
  type        = string
}

variable "pf_installer_vm_name" {
  description = "PowerFlex installer VM name"
  type        = string
}

variable "pf_installer_ip" {
  description = "PowerFlex installer IP address"
  type        = string
}

variable "pf_installer_template" {
  description = "PowerFlex installer template name"
  type        = string
}

variable "ip_pool_for_pfmp_services" {
  description = "IP pool (5 required) for K8s ingress services"
  type        = string
}
variable "vip_for_pfmp_ui" {
  description = "PowerFlex management UI virtual IP"
  type        = string
}

variable "hostname_for_pfmp_ui" {
  description = "PowerFlex management UI hostname (fqdn)"
  type        = string
}

variable "storage_node_template" {
  description = "vSphere template  for storage nodes (e.g. Ubuntu 20.04)"
  type        = string
}

variable "powerflex_node_1_name" {
  description = "Hostname for storage node 1"
  type        = string
}

variable "powerflex_node_1_ip" {
  description = "IP address for storage node 1"
  type        = string
}

variable "powerflex_node_2_name" {
  description = "Hostname for storage node 2"
  type        = string
}

variable "powerflex_node_2_ip" {
  description = "IP address for storage node 2"
  type        = string
}

variable "powerflex_node_3_name" {
  description = "Hostname for storage node 3"
  type        = string
}

variable "powerflex_node_3_ip" {
  description = "IP address for storage node 3"
  type        = string
}

variable "powerflex_node_4_name" {
  description = "Hostname for storage node 4"
  type        = string
}

variable "powerflex_node_4_ip" {
  description = "IP address for storage node 4"
  type        = string
}