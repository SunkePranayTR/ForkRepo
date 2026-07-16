packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

locals {
  # HCL2-correct timestamp (NOT {{timestamp}}) -> e.g. 20260716103045
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "linux" {
  region        = "us-east-1"
  instance_type = "t3.micro"

  # Build inside your VPC (no default VPC in this account)
  subnet_id     = "subnet-0381bbe2dccd4e234"
  ssh_interface = "private_ip"
  ssh_username  = "ec2-user"

  # Base image: latest Amazon Linux 2023, Amazon-owned -> always launchable
  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  ami_name = "a201814-gst-nonprod-linux-baked-${local.timestamp}"

  tags = {
    "Name"                            = "a201814-gst-nonprod-linux-baked"
    "tr:application-asset-insight-id" = "201814"
    "tr:environment-type"             = "DEVELOPMENT"
    "tr:resource-owner"               = "ATPA-GST-DevOps@thomsonreuters.com"
  }
}

build {
  sources = ["source.amazon-ebs.linux"]

  # Make the image deployment-ready for the ASP.NET Core app
  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y unzip",
      # ASP.NET Core 9 runtime; fall back to Microsoft's installer if the dnf package is absent
      "sudo dnf install -y aspnetcore-runtime-9.0 || (curl -sSL https://dot.net/v1/dotnet-install.sh | sudo bash -s -- --runtime aspnetcore --channel 9.0 --install-dir /usr/share/dotnet && sudo ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet)",
      # Prove the runtime is present in the baked image
      "dotnet --list-runtimes 2>/dev/null || /usr/local/bin/dotnet --list-runtimes"
    ]
  }
}
