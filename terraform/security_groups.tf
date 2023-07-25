resource "aws_security_group" "serveraccess" {
  name = "allow_egress"
  vpc_id = aws_vpc.server.id
}

resource "aws_security_group_rule" "egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  security_group_id = aws_security_group.serveraccess.id
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# For this short-lived instance we are opening up 22 to the world for troubleshooting.
# Feel free to comment this rule out or change it to your personal IP for added security
resource "aws_security_group_rule" "ingress" {
  type = "ingress"
  from_port = 0
  to_port = 22
  security_group_id = aws_security_group.serveraccess.id
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}