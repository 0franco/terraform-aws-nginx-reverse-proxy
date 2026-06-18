output "proxy_public_ip" {
  description = "Public IPv4 address of the proxy instance."
  value       = aws_instance.proxy.public_ip
}

output "proxy_private_ip" {
  description = "Private IPv4 address of the proxy instance."
  value       = aws_instance.proxy.private_ip
}

output "proxy_public_dns" {
  description = "Public DNS name of the proxy instance."
  value       = aws_instance.proxy.public_dns
}

output "security_group_id" {
  description = "Security group attached to the proxy instance."
  value       = aws_security_group.proxy.id
}

output "vpc_id" {
  description = "VPC used by the proxy."
  value       = local.selected_vpc_id
}

output "subnet_id" {
  description = "Public subnet used by the proxy."
  value       = local.selected_subnet_id
}

output "ssh_command" {
  description = "SSH command for the default Ubuntu AMI user."
  value       = "ssh ubuntu@${aws_instance.proxy.public_ip}"
}
