variable "cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subnets donde se desplegará el servicio ECS"
  type        = list(string)
}

variable "sg_id" {
  description = "ID del grupo de seguridad para el servicio ECS"
  type        = string
}