#  Copyright 2018 Banco Bilbao Vizcaya Argentaria, S.A.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
}

resource "null_resource" "prebuild" {
  provisioner "local-exec" {
    command = "bash build.sh"
    working_dir = "${path.module}"
  }
}


resource "aws_instance" "inmemory-storage" {
  count                       = "1"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "${var.instance_type}"

  vpc_security_group_ids      = ["${var.vpc_security_group_ids}"]
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = true
  key_name                    = "${var.key_name}"

  root_block_device = [{
    volume_type = "gp2"
    volume_size = "${var.volume_size}"
  }]

  tags {
    Name = "qed-${var.name}"
  }


  provisioner "file" {
      source     = "${path.module}/data"
      destination = "${var.path}"

      connection {
        user = "ec2-user"
        private_key = "${file("${var.key_path}")}"
      }
  }

  provisioner "file" {
    source     = "./config_files/node_exporter"
    destination = "${var.path}/node_exporter"

    connection {
      user = "ec2-user"
      private_key = "${file("${var.key_path}")}"
    }
  }

  user_data = <<-DATA
  #!/bin/bash

  while [ ! -f ${var.path}/storage ] || \
        [ ! -f ${var.path}/node_exporter ] || \
        [ `lsof ${var.path}/* | wc -l` -gt 0 ]; do
    sleep 1
  done
  sleep 1

  chmod +x ${var.path}/node_exporter
  ${var.path}/node_exporter &

  chmod +x ${var.path}/storage
  ${var.path}/storage
  DATA
}
