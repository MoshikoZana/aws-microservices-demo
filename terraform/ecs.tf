resource "aws_ecs_cluster" "main" {
  name = "myapp-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition - Microservice 1
resource "aws_ecs_task_definition" "micro1" {
  family                   = "microservice1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "microservice1"
      image     = "moshikozana/microservice1:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "micro2" {
  family                   = "microservice2"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "microservice2"
      image     = "moshikozana/microservice2:${var.image_tag}"
      essential = true
    }
  ])
}

resource "aws_ecs_service" "micro1" {
  name            = "micro1-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.micro1.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.public.ids
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
  target_group_arn = aws_lb_target_group.app_tg.arn
  container_name   = "microservice1"
  container_port   = 8080
}

  depends_on = [aws_iam_role_policy_attachment.ecs_execution_policy]
}


resource "aws_ecs_service" "micro2" {
  name            = "micro2-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.micro2.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.public.ids
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_execution_policy]
}
