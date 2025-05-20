resource "aws_security_group" "app_sg" {
  name        = "app_sg_new"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ecs_security_group_id" {
  description = "Security group for ECS tasks"
  value       = aws_security_group.app_sg.id
}
