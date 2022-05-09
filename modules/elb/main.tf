resource "aws_elb" "web_elb" {
  name            = var.elb_name
  subnets         = var.subnets
  security_groups = [aws_security_group.elb_sg.id]
  instances       = var.instances
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  tags = merge(var.common_tags, { Name = "web_elb--${var.env_name}" })
}

resource "aws_security_group" "elb_sg" {
  name   = var.elb_sg_name
  vpc_id = var.vpc
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "elb_sg--${var.env_name}" })
}