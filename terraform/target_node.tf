data "aws_ami" "target" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners      = ["099720109477"]
}

resource "aws_instance" "target_node" {
  ami                         = data.aws_ami.target.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.server.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.serveraccess.id]
  key_name                    = var.key_name
  user_data                   = <<EOT
#!/bin/bash
TELEPORT_VERSION=${var.teleport_version}
sudo apt-get -y update
sudo apt-get -y install software-properties-common
sudo apt-get -y install apt-transport-https
sudo apt-get -y install libnss3-tools
sudo apt-get -y install wget
sudo apt-get -y install dnsutils
sudo apt-get -y install gpg
sudo apt-get -y update
curl -O https://cdn.teleport.dev/teleport-v$TELEPORT_VERSION-linux-amd64-bin.tar.gz
tar -xf teleport-v$TELEPORT_VERSION-linux-amd64-bin.tar.gz
cd teleport
sudo ./install
sudo cp examples/systemd/teleport.service /etc/systemd/system
mkdir /etc/teleport/
echo "Changing hostname..."
sudo hostnamectl set-hostname ${var.hostname}

#sed -i 's/start/start --diag-addr=127.0.0.1:3000 --config=\/etc\/teleport\/teleport.yaml/' /etc/systemd/system/teleport.service
HOSTNAME="teleportvm"
cat << EOP >> /etc/teleport.yaml
version: v3
teleport:
  data_dir: /var/lib/teleport
  proxy_server: ${var.proxy_server}
  join_params:
    token_name: ${var.join_token}
    method: token
  log:
    output: stderr
    severity: INFO
    format:
      output: text
auth_service:
  enabled: false
proxy_service:
  enabled: false
ssh_service:
  enabled: "yes"
  labels:
    role: ssh
    environment: dev
  commands:
  - name: hostname
    command: [hostname]
    period: 1m0s
EOP

systemctl enable teleport
systemctl start teleport
EOT

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }

  tags = {
    Name = "target_node"
  }
}