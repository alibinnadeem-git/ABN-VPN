data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "vpn" {
  compartment_id = var.compartment_ocid
  display_name   = "abn-vpn-vcn"
  dns_label      = "abnvpn"
  cidr_blocks    = [var.vcn_cidr]
}

resource "oci_core_internet_gateway" "vpn" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "abn-vpn-igw"
  enabled        = true
}

resource "oci_core_route_table" "vpn" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "abn-vpn-public-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vpn.id
  }
}

resource "oci_core_security_list" "vpn" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "abn-vpn-security"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"

    udp_options {
      min = var.wireguard_port
      max = var.wireguard_port
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.ssh_source_cidr

    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "vpn" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vpn.id
  display_name               = "abn-vpn-public-subnet"
  dns_label                  = "vpn"
  cidr_block                 = var.subnet_cidr
  route_table_id             = oci_core_route_table.vpn.id
  security_list_ids          = [oci_core_security_list.vpn.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "vpn" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = var.instance_name
  shape               = var.shape

  dynamic "shape_config" {
    for_each = var.shape == "VM.Standard.A1.Flex" ? [1] : []
    content {
      ocpus         = var.ocpus
      memory_in_gbs = var.memory_gbs
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.vpn.id
    assign_public_ip = true
    display_name     = "${var.instance_name}-vnic"
    hostname_label   = "abnvpn"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(<<-CLOUDINIT
      #cloud-config
      package_update: true
      packages:
        - git
        - wireguard
        - qrencode
        - ufw
        - curl
      write_files:
        - path: /etc/sysctl.d/99-abn-vpn.conf
          permissions: "0644"
          content: |
            net.ipv4.ip_forward=1
      runcmd:
        - [sysctl, --system]
      final_message: "ABN VPN OCI base node ready."
    CLOUDINIT
    )
  }

  lifecycle {
    precondition {
      condition     = length(data.oci_core_images.ubuntu.images) > 0
      error_message = "No Ubuntu 24.04 image is available for the selected shape/region."
    }
  }
}
