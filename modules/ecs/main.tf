# Crear un cluster ECS
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

# Definir la tarea ECS para Nginx
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.cluster_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "nginx"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# Crear un servicio ECS
resource "aws_ecs_service" "service" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "EC2"
  desired_count   = 1

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [var.sg_id]
  }
}