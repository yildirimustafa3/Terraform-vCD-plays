# With this terraform, you can create an vCloud Organisation, vCloud Organisation user(org-admin), a flex Organisation VDC with no limit, and a Org-VDC network(direct)
# variables

variable "admin_user" {}
variable "admin_password" {}
variable "org_user_password" {}

terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
      version = "3.5.1"
    }
  }
}

provider "vcd" {
  user     = var.admin_user
  password = var.admin_password
  org      = "System"
  url      = "https://nameofvcloud.com/api"
  max_retry_timeout    = "5"
  allow_unverified_ssl = "true"
}

resource "vcd_org" "mustafaterraform-org" {
  name             = "mustafaterraform-org"
  full_name        = "mustafaterraform-org"
  description      = "Testing description"
  is_enabled       = "true"
  delete_recursive = "true"
  delete_force     = "true"

  vapp_lease {
    maximum_runtime_lease_in_sec          = 0 # never expires
    power_off_on_runtime_lease_expiration = false
    maximum_storage_lease_in_sec          = 0 # never expires
    delete_on_storage_lease_expiration    = false
  }
  vapp_template_lease {
    maximum_storage_lease_in_sec       = 0 # never expires
    delete_on_storage_lease_expiration = false
  }
}


resource "vcd_org_user" "my-org-admin" {
  org         = vcd_org.mustafaterraform-org.name
  name        = vcd_org.mustafaterraform-org.name
  description = "a new org admin"
  role        = "Organization Administrator"
  password    = var.org_user_password
  deployed_vm_quota = 0 # unlimited
  stored_vm_quota   = 0 # unlimited
}

resource "vcd_org_vdc" "my-vdc" {
  name        = "mustafaterraform-vdc"
  description = "Description for org vdc"
  org         = vcd_org.mustafaterraform-org.name

  allocation_model  = "Flex"
  network_pool_name = "test-TZ"
  provider_vdc_name = "test-pvdc"

  elasticity = true
  vm_quota = 0 # unlimited
  memory_guaranteed = 0
  include_vm_memory_overhead = false # if there is no allocated memory, this needs to be false
  cpu_guaranteed = 0
  cpu_speed = 1000 # in MHz , default is 1000Mhz(1GHz)

  compute_capacity {
    cpu {
      allocated = "0"
      limit     = "0"
    }

    memory {
      allocated = "0"
      limit     = "0"
    }
  }

  storage_profile {
    name    = "vSAN Default Storage Policy"
    enabled = true
    limit   = 0 # unlimited
    default = true
  }


 /*  metadata = {
    role    = "customerName"
    env     = "staging"
    version = "v1"
  } */

  enabled                  = true
  enable_thin_provisioning = true
  enable_fast_provisioning = false
  delete_force             = true
  delete_recursive         = true
}



resource "vcd_network_direct" "mustafaterraformnetwork" {
  org = vcd_org.mustafaterraform-org.name
  vdc = vcd_org_vdc.my-vdc.name

  name             = "mustafaterraformvlan112"
  external_network = "TestNetwork - vlan112" #extarnal network name that is added previosly into vcloud , otherwise it has to be created beforehand.
}

# Standalone VM creation 
/* resource "vcd_vm" "mustafaterraform-vm" {
  name = "mustafaterraform-vm"
  vdc  = vcd_org_vdc.my-vdc.name
  catalog_name  = "example-catalog"
  #template_name = "photon-hw11"
  cpus          = 2
  memory        = 4096

   network {
    name               = vcd_network_direct.mustafaterraformnetwork.name
    type               = "org"
    ip_allocation_mode = "POOL"
  } 
}  */

resource "vcd_vm" "test01" {
  org  = "mustafaterraform-org"
  vdc  = "mustafaterraform-vdc"
  name = "testuidan"
  #accept_all_eulas               = true
  power_on                       = true
  #prevent_update_power_off       = false
  network {
          adapter_type       = "VMXNET3"
          connected          = true
          ip                 = "10.61.91.15"
          ip_allocation_mode = "POOL"
          is_primary         = true
          #mac                = "00:50:56:00:00:00" 
          name               = "mustafaterraformvlan112"
          type               = "org" 
          }
}

resource "vcd_vm" "terraformvms" {
  org  = "mustafaterraform-org"
  vdc  = "mustafaterraform-vdc"
  name = "terraform-vm"
  computer_name = "terraform-vms"
  cpu_cores= 2
  cpu_hot_add_enabled= false
  cpus= 2
  memory = 2048
  hardware_version = "vmx-19"
  os_type = "ubuntu64Guest"
  memory_hot_add_enabled = true
  #accept_all_eulas               = true
  power_on = true
  #prevent_update_power_off       = false
  network {
          adapter_type       = "VMXNET3"
          connected          = true
          #ip                 = "10.61.91.15"
          ip_allocation_mode = "POOL"
          is_primary         = true
          #mac                = "00:50:56:01:00:00" 
          name               = "mustafaterraformvlan112"
          type               = "org" 
          }
  count = 2
}


output "vm_ip" {
	value = vcd_vm.terraformvms[0].network[0] # --> runlayınca bunu print eder, her seferinde tek
}