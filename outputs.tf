output "nginx_endpoint" {
  description = "La URL del servidor nginx"
  value       = "http://${module.ec2.instance_public_ip}:80"
}