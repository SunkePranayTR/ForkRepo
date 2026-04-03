packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}



source "amazon-ebs" "amazon-linux" {
  region        = "us-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"


  source_ami = "ami-094c82cbda9bf2832"
  ami_name   = "a201814-gst-nonprod-intern1-ami1"

  tags = {
    "Name"                              = "a201814-gst-nonprod-intern1-ins1"
    "tr:application-asset-insight-id" = "201814"
    "tr:resource-owner"               = "ATPA-GST-DevOps@thomsonreuters.com"
    "tr:environment-type"             = "DEVELOPMENT"
  }
  run_tags = {
    "Name"                              = "a201814-gst-nonprod-intern1-ins1"
    "tr:application-asset-insight-id" = "201814"
    "tr:resource-owner"               = "ATPA-GST-DevOps@thomsonreuters.com"
    "tr:environment-type"             = "DEVELOPMENT"
  }
}
build {
  sources = [
    "source.amazon-ebs.amazon-linux"
  ]
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
}