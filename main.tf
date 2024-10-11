# Configuración del proveedor AWS
provider "aws" {
  region = var.region
}

# Módulo ECS
module "ecs" {
  source       = "./modules/ecs"
  cluster_name = var.project_name
}
