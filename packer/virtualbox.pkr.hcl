packer {
  required_version = ">= 1.7.1"
}

variable "box_description" {
  type    = string
  default = "${env("BUILD_BOX_DESCRIPTION")}"
}

variable "box_version" {
  type    = string
  default = "${env("BUILD_BOX_VERSION")}"
}

variable "cpus" {
  type    = string
  default = "${env("BUILD_CPUS")}"
}

variable "custom_overlay" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY")}"
}

variable "custom_overlay_branch" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY_BRANCH")}"
}

variable "custom_overlay_name" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY_NAME")}"
}

variable "custom_overlay_url" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY_URL")}"
}

variable "disksize" {
  type    = string
  default = "${env("BUILD_GUEST_DISKSIZE")}"
}

variable "guest_additions" {
  type    = string
  default = "${env("BUILD_GUEST_ADDITIONS")}"
}

variable "guest_os_type" {
  type    = string
  default = "${env("BUILD_GUEST_TYPE")}"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "makeopts" {
  type    = string
  default = "${env("BUILD_MAKEOPTS")}"
}

variable "memory" {
  type    = string
  default = "${env("BUILD_MEMORY")}"
}

variable "output_file" {
  type    = string
  default = "${env("BUILD_OUTPUT_FILE_TEMP")}"
}

variable "rebuild_system" {
  type    = string
  default = "${env("BUILD_REBUILD_SYSTEM")}"
}

variable "stage3_file" {
  type    = string
  default = "${env("BUILD_STAGE3_FILE")}"
}

variable "stage3_path" {
  type    = string
  default = "${env("BUILD_STAGE3_PATH")}"
}

variable "stage3_url" {
  type    = string
  default = "${env("BUILD_STAGE3_URL")}"
}

variable "sysrescuecd_checksum" {
  type    = string
  default = "${env("BUILD_SYSRESCUECD_REMOTE_HASH")}"
}

variable "sysrescuecd_url" {
  type    = string
  default = "${env("BUILD_SYSRESCUECD_FILE")}"
}

variable "timestamp" {
  type    = string
  default = "${env("BUILD_TIMESTAMP")}"
}

variable "timezone" {
  type    = string
  default = "${env("BUILD_TIMEZONE")}"
}

variable "username" {
  type    = string
  default = "root"
}

variable "password" {
  type    = string
  default = "toor"
}

variable "vm_name" {
  type    = string
  default = "${env("BUILD_BOX_NAME")}"
}

variable "vm_username" {
  type    = string
  default = "${env("BUILD_BOX_USERNAME")}"
}

source "virtualbox-iso" "img" {
  boot_command         = ["<enter>", "<wait>", "<enter>", "<wait10>", "<enter>", "<wait10>", "<wait10>", "passwd ${var.username}", "<enter>", "<wait>", "${var.password}", "<enter>", "<wait>", "${var.password}", "<enter>", "<wait>", "${var.password}", "<enter>", "<wait>"]
  boot_wait            = "5s"
  disk_size            = "${var.disksize}"
  guest_additions_mode = "disable"
  guest_os_type        = "${var.guest_os_type}"
  hard_drive_interface = "sata"
  hard_drive_nonrotational = "true"
  headless             = "${var.headless}"
  iso_checksum         = "sha256:${var.sysrescuecd_checksum}"
  iso_interface        = "sata"
  iso_url              = "${var.sysrescuecd_url}"
  shutdown_command     = "shutdown -hP now"
  ssh_username         = "${var.username}"
  ssh_password         = "${var.password}"
  ssh_pty              = "true"
  ssh_wait_timeout     = "30s"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "virtio"],
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--usb", "off"],
    ["modifyvm", "{{ .Name }}", "--chipset", "ich9"],
    ["modifyvm", "{{ .Name }}", "--rtcuseutc", "on"],
    ["modifyvm", "{{ .Name }}", "--vram", "12"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--hpet", "on"],
    ["modifyvm", "{{ .Name }}", "--hwvirtex", "on"],
    ["modifyvm", "{{ .Name }}", "--vtxvpid", "on"],
    ["modifyvm", "{{ .Name }}", "--largepages", "on"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "off"]
  ]
  vm_name              = "${var.vm_name}"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "\"${var.box_description}\"",
    "--version", "${var.box_version}"
  ]
}

build {
  sources = ["source.virtualbox-iso.img"]
  provisioner "file" {
    destination = "/tmp/scripts"
    source      = "packer/scripts"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "download/stage3-latest.tar.xz"
  }
  provisioner "file" {
    destination = "/tmp/"
    source      = "distfiles"
  }
  provisioner "shell" {
    environment_vars  = [
      "scripts=/tmp",
      "BUILD_RUN=true",
      "BUILD_BOX_NAME=${var.vm_name}",
      "BUILD_BOX_USERNAME=${var.vm_username}",
      "BUILD_BOX_VERSION=${var.box_version}",
      "BUILD_MAKEOPTS=${var.makeopts}",
      "BUILD_TIMESTAMP=${var.timestamp}",
      "BUILD_TIMEZONE=${var.timezone}",
      "BUILD_STAGE3_FILE=${var.stage3_file}",
      "BUILD_STAGE3_URL=${var.stage3_url}",
      "BUILD_STAGE3_PATH=${var.stage3_path}",
      "BUILD_GUEST_ADDITIONS=${var.guest_additions}",
      "BUILD_REBUILD_SYSTEM=${var.rebuild_system}",
      "BUILD_CUSTOM_OVERLAY=${var.custom_overlay}",
      "BUILD_CUSTOM_OVERLAY_NAME=${var.custom_overlay_name}",
      "BUILD_CUSTOM_OVERLAY_URL=${var.custom_overlay_url}",
      "BUILD_CUSTOM_OVERLAY_BRANCH=${var.custom_overlay_branch}"
    ]
    expect_disconnect = false
    script            = "packer/provision.sh"
  }
  post-processor "checksum" {
    checksum_types = ["sha1"]
    output         = "build/packer.{{.ChecksumType}}.checksum"
  }
  post-processor "vagrant" {
    output              = "${var.output_file}"
  }
}
