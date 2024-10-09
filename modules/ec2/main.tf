# Obtener la AMI más reciente optimizada para ECS
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Crear una instancia EC2 para el cluster ECS
resource "aws_instance" "ecs_instance" {
  ami           = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  vpc_security_group_ids = [var.sg_id]

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
EOF

  tags = {
    Name = "${var.cluster_name}-instance"
  }
}

# Crear un perfil de instancia IAM para el agente ECS
resource "aws_iam_instance_profile" "ecs_agent" {
  name = "${var.cluster_name}-ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

# Crear un rol IAM para el agente ECS
resource "aws_iam_role" "ecs_agent" {
  name = "${var.cluster_name}-ecs-agent"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Adjuntar la política necesaria al rol IAM
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}