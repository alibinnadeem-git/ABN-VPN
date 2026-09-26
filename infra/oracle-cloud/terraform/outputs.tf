output "instance_id" {
  value = oci_core_instance.vpn.id
}

output "public_ip" {
  value = oci_core_instance.vpn.public_ip
}

output "wireguard_endpoint" {
  value = "${oci_core_instance.vpn.public_ip}:${var.wireguard_port}"
}

output "region" {
  value = var.region
}
