# Creamos un data del Default VPC
data "aws_vpc" "this" {
  default = true
}

# Creamos un data de las Default Subnets
data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}


# Creamos la política de AssumeRole para las ECS Task
data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Creamos el role de ejecución para ECS
resource "aws_iam_role" "this" {
  name               = "kc-ecs-execution-task-role-thomas"
  assume_role_policy = data.aws_iam_policy_document.this.json
  tags = {
    Name        = "kc-ecs-iam-role"
    Environment = "Dev"
  }
}

# Crear un cluster ECS
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

# Creamos los Capacity Providers FARGATE del Cluster ECS
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Definir la tarea ECS para Nginx
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.cluster_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "nginx"
    image = "thomasalberto/nginx-hola-chamo:latest" //nginx:latest cambio imagen para probar
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# Data del ECS Task Definition
data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.task.family
}

# Creamos el ECS Service
resource "aws_ecs_service" "this" {
  name                 = "kc-ecs-service-thomas"
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = "${aws_ecs_task_definition.task.family}:${max(aws_ecs_task_definition.task.revision, data.aws_ecs_task_definition.this.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = data.aws_subnets.this.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

# Creamos el Security Group del ALB
resource "aws_security_group" "alb" {
  vpc_id = data.aws_vpc.this.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = "kc-ecs-svc-sg"
    Environment = "Dev"
  }
}

# Creamos el Security Group para el Task ECS
resource "aws_security_group" "tasks" {
  name   = "kc-sg-task-ecs-thomas"
  vpc_id = data.aws_vpc.this.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Creamos el ALB
resource "aws_alb" "this" {
  name               = "kc-ecs-alb-thomas"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnets.this.ids
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name        = "kc-ecs-alb"
    Environment = "Dev"
  }
}

# Creamos el Target Group del ALB
resource "aws_lb_target_group" "this" {
  name        = "kc-ecs-lb-tg-thomas"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "kc-ecs-lb-tg"
    Environment = "Dev"
  }
}

# Creamos el Listener del ALB
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_alb.this.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

