# Práctica Final de AWS - Bootcamp Keepcoding

## Descripción

Este proyecto despliega un servidor Nginx en un cluster ECS de AWS utilizando Terraform. La infraestructura se despliega en la VPC por defecto y utiliza subnets públicas.

## Requisitos

- Terraform instalado
- AWS CLI configurado con las credenciales adecuadas

## Componentes Principales

1. Cluster ECS
2. Tarea ECS con Nginx
3. Servicio ECS
4. Application Load Balancer (ALB)
5. Grupos de Seguridad
6. IAM Role para las tareas ECS

Para una explicación detallada de cada componente, consulte [Explicaciones.md](Explicaciones.md).

## Despliegue

1. Clona este repositorio
2. Navega al directorio del proyecto
3. Inicializa Terraform:

```
terraform init
```
4. Planifica el despliegue:

```
terraform plan
```
5. Aplica los cambios:

```
terraform apply
```
## Outputs

Después del despliegue, Terraform mostrará el endpoint de conexión del ALB.

## Limpieza

Para eliminar todos los recursos creados:

```
terraform destroy
```


## Notas

- Este proyecto utiliza la VPC por defecto y subnets públicas para simplificar el despliegue.
- La imagen de Docker utilizada es `thomasalberto/nginx-hola-chamo:latest`.
- El ALB está configurado para escuchar en el puerto 80.

## Autor

Thomas Alberto
