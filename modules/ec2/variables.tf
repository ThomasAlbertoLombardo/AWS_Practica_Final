variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde se desplegará la instancia EC2"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "sg_id" {
  description = "ID del grupo de seguridad para la instancia EC2"
  type        = string
}