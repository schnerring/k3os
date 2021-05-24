variable "client_id" {
  type        = string
  description = "The application ID of the AAD Service Principal."
}

variable "client_secret" {
  type        = string
  description = "A password/secret registered for the AAD SP."
}

variable "tenant_id" {
  type        = string
  description = "The Active Directory tenant identifier with which your client_id and subscription_id are associated."
}

variable "subscription_id" {
  type        = string
  description = "The subscription to use."
}

variable "region" {
  type        = string
  description = "Azure datacenter in which your VM will build."
  default     = "West Europe"
}

locals {
  k3os_version            = "v0.19.4-dev.5"
  k3os_iso_url            = "https://github.com/rancher/k3os/releases/download/${local.k3os_version}/k3os-amd64.iso"
  k3os_install_script_url = "https://raw.githubusercontent.com/rancher/k3os/${local.k3os_version}/install.sh"
}

source "azure-arm" "main" {
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  tenant_id                         = "${var.tenant_id}"
  subscription_id                   = "${var.subscription_id}"

  managed_image_name                = "k3os-${local.k3os_version}-mimg"
  managed_image_resource_group_name = "packer-images-rg"

  vm_size                           = "Standard_DS2_v2"
  location                          = "${var.region}"

  image_offer                       = "UbuntuServer"
  image_publisher                   = "Canonical"
  image_sku                         = "16.04-LTS"
  os_type                           = "Linux"
}

build {
  sources = [
    "source.azure-arm.main"
  ]

  provisioner "file" {
    source      = "./config.yaml"
    destination = "/tmp/config.yaml"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo bash -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "set -x",
      "curl -o /tmp/install.sh ${local.k3os_install_script_url}",
      "chmod +x /tmp/install.sh",
      "/tmp/install.sh --takeover --tty ttyS0 --config /tmp/config.yaml --no-format $(findmnt / -o SOURCE -n) ${local.k3os_iso_url}"
    ]
  }
  
  provisioner "shell" {
    expect_disconnect = true
    pause_after = "3m"
    execute_command = "chmod +x {{ .Path }}; sudo bash -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "sync",
      "systemd-run --on-active=3 --timer-property=AccuracySec=100ms sudo systemctl reboot --force --force",
      "systemctl stop sshd"
    ]
  }
}
