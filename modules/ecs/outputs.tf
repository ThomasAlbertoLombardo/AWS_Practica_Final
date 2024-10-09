output "cluster_name" {
  description = "Nombre del cluster ECS creado"
  value       = aws_ecs_cluster.cluster.name
}