terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "network-terraform" {
  name = "network-terraform"
}

resource "yandex_vpc_subnet" "subnet-terraform" {
  name           = "subnet-terraform"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["172.16.10.0/24"]
  network_id     = yandex_vpc_network.network-terraform.id
}

resource "yandex_compute_instance" "vm" {
  count = 2

  name        = "vm-${count.index}"
  platform_id = "standard-v1"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80293ig2816a78q276"
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-terraform.id
    nat       = true
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    user-data = replace(file("${path.module}/cloud-config-base.yaml"), "VM-PLACEHOLDER", "VM-${count.index}")
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_lb_target_group" "tg-new-group" {
  name = "tg-new-group"

  dynamic "target" {
    for_each = yandex_compute_instance.vm
    content {
      subnet_id = yandex_vpc_subnet.subnet-terraform.id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "balancer1" {
  name = "balancer1"

  listener {
    name = "listener-balancer1"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg-new-group.id

    healthcheck {
      name = "http"
      http_options {
        port  = 80
        path  = "/"
      }
      interval            = 10
      timeout             = 5
      unhealthy_threshold = 2
      healthy_threshold   = 2
    }
  }
}

