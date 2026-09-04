output "load_balancer_ip" {
  value = one([for l in yandex_lb_network_load_balancer.balancer1.listener : one(l.external_address_spec).address if l.name == "listener-balancer1"])
}

output "internal_ip_address_vm_0" {
  value = yandex_compute_instance.vm[0].network_interface[0].ip_address
}

output "external_ip_address_vm_0" {
  value = yandex_compute_instance.vm[0].network_interface[0].nat_ip_address
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm[1].network_interface[0].ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm[1].network_interface[0].nat_ip_address
}
