# Configuración del proveedor AWS
provider "aws" {
  region = var.region
}

# Módulo de red
module "network" {
  source = "./modules/network"
  //vpc_id       = data.aws_vpc.default.id
  project_name = var.project_name
}

# Módulo ECS
module "ecs" {
  source       = "./modules/ecs"
  cluster_name = var.project_name
  subnet_ids   = module.network.subnet_ids
  sg_id        = module.network.security_group_id
}

# Módulo EC2
module "ec2" {
  source        = "./modules/ec2"
  instance_type = var.instance_type
  subnet_id     = module.network.subnet_ids[0]
  cluster_name  = module.ecs.cluster_name
  sg_id         = module.network.security_group_id
}

