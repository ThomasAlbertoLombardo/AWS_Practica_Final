variable "region" {
  description = "La región de AWS donde se desplegarán los recursos"
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para nombrar recursos"
  default     = "nginx-ecs-thomas"
}
