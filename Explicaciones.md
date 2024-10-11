# Explicaciones Detalladas del Proyecto

Este documento proporciona una explicación paso a paso de cada componente del proyecto Terraform.

## 1. VPC y Subnets

```h
data "aws_vpc" "this" {
  default = true
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}
```
Estos bloques son cruciales para la configuración de red de nuestra infraestructura:

- **VPC por defecto**: Utilizamos la VPC por defecto de AWS para simplificar la configuración. Esto es útil para pruebas y desarrollo, pero en un entorno de producción, se recomienda crear una VPC personalizada.

- **Subnets por defecto**: Obtenemos todas las subnets asociadas a la VPC por defecto. Estas subnets se utilizarán para desplegar nuestros recursos de ECS y el ALB.

- **Flexibilidad**: Al usar datos existentes en lugar de crear nuevos recursos, mantenemos la flexibilidad para adaptar nuestro despliegue a diferentes entornos de AWS sin modificar el código.


## 2. IAM Role y Política

```h
data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "kc-ecs-execution-task-role-thomas"
  assume_role_policy = data.aws_iam_policy_document.this.json
  tags = {
    Name        = "kc-ecs-iam-role"
    Environment = "Dev"
  }
}
```
La configuración de IAM es esencial para la seguridad y el correcto funcionamiento de ECS:

- **Política de AssumeRole**: Definimos una política que permite a ECS asumir este rol. Esto es fundamental para que las tareas de ECS puedan ejecutarse con los permisos necesarios.

- **Rol de ejecución**: Creamos un rol IAM específico para las tareas de ECS. Este rol otorga los permisos necesarios para que las tareas puedan interactuar con otros servicios de AWS.

- **Principio de mínimo privilegio**: Aunque no se muestra en el código, es importante asignar solo los permisos estrictamente necesarios a este rol, siguiendo las mejores prácticas de seguridad.

## 3. Cluster ECS

```h
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
```
El cluster ECS es el contenedor lógico para nuestros servicios y tareas:

- **Nombre del cluster**: Utilizamos una variable para el nombre del cluster, lo que permite personalizar fácilmente el despliegue.

- **Proveedores de capacidad**: Configuramos el cluster para usar Fargate como proveedor de capacidad. Esto significa que AWS gestionará la infraestructura subyacente, permitiéndonos centrarnos en nuestras aplicaciones.

- **Estrategia de capacidad**: Establecemos Fargate como el proveedor predeterminado con un peso de 100 y una base de 1. Esto asegura que todas las tareas se ejecuten en Fargate.
## 4. Definición de Tarea ECS
```h
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.cluster_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "nginx"
    image = "thomasalberto/nginx-hola-chamo:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}
```
Este bloque define la tarea ECS que ejecutará el contenedor Nginx. Es importante destacar varios aspectos:

1. **Imagen personalizada**: En lugar de usar la imagen base de Nginx (`nginx:latest`), se ha optado por una imagen personalizada: `thomasalberto/nginx-hola-chamo:latest`.

2. **Recursos asignados**: La tarea está configurada para usar 256 unidades de CPU y 512 MB de memoria, lo cual es adecuado para una aplicación Nginx ligera.

3. **Compatibilidad con Fargate**: La tarea está configurada para ser compatible con Fargate (`requires_compatibilities = ["FARGATE"]`), lo que significa que se ejecutará en infraestructura administrada por AWS sin necesidad de gestionar instancias EC2.

4. **Modo de red**: Se utiliza el modo de red `awsvpc`, que proporciona a cada tarea su propia interfaz de red elástica y dirección IP privada.

5. **Mapeo de puertos**: El contenedor expone el puerto 80, que es el puerto estándar para el tráfico HTTP. Esto permite que el tráfico del ALB llegue al servidor Nginx dentro del contenedor.

## 5. Servicio ECS
```h
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
```

El servicio ECS mantiene en ejecución el número deseado de instancias de nuestra tarea:

- **Estrategia de programación**: Usamos "REPLICA" para mantener un número constante de tareas en ejecución.

- **Número deseado**: Configuramos el servicio para mantener una tarea en ejecución, pero esto puede ajustarse según las necesidades.

- **Configuración de red**: Asignamos una IP pública y asociamos el servicio con un grupo de seguridad específico.

- **Integración con el balanceador de carga**: Vinculamos el servicio con un target group del ALB, permitiendo la distribución de tráfico.

## 6. Grupos de Seguridad
```h
resource "aws_security_group" "alb" {
  # ... (configuración del grupo de seguridad del ALB)
}

resource "aws_security_group" "tasks" {
  # ... (configuración del grupo de seguridad de las tareas ECS)
}
```
Los grupos de seguridad actúan como firewalls virtuales para nuestros recursos:

- **Grupo de seguridad del ALB**: Permite el tráfico HTTP entrante desde cualquier lugar y todo el tráfico saliente.

- **Grupo de seguridad de las tareas**: Permite el tráfico HTTP entrante y todo el tráfico saliente, necesario para que las tareas puedan comunicarse con otros servicios.

- **Principio de mínimo privilegio**: Las reglas se configuran para permitir solo el tráfico necesario, mejorando la seguridad general.

## 7. Application Load Balancer (ALB)
```h
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
```
El ALB distribuye el tráfico entrante entre nuestras tareas ECS:

- **Tipo**: Configuramos un balanceador de carga de aplicación, ideal para el tráfico HTTP/HTTPS.

- **Accesibilidad**: Lo configuramos como externo (no interno) para que sea accesible desde Internet.

- **Subnets**: Desplegamos el ALB en las subnets públicas de nuestra VPC.

- **Grupo de seguridad**: Asociamos el ALB con su propio grupo de seguridad para controlar el tráfico.
## 7. Application Load Balancer (ALB)
```h
resource "aws_lb_target_group" "this" {
  # ... (configuración del target group)
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_alb.this.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}
```
Estos componentes son esenciales para dirigir el tráfico desde el ALB a nuestras tareas ECS:

- **Target Group**: Configura cómo el ALB evalúa la salud de las tareas y distribuye el tráfico entre ellas.

- **Health Check**: Definimos cómo el ALB verifica que nuestras tareas están funcionando correctamente.

- **Listener**: Configura el ALB para escuchar en el puerto 80 y reenviar el tráfico al target group.

- **Protocolo**: Utilizamos HTTP para simplificar, pero en un entorno de producción se recomienda usar HTTPS para mayor seguridad.B.
