output "vpc_id" {
  value = aws_default_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnets.public.ids
}

output "security_group_id" {
  value = aws_security_group.nginx_sg.id
}