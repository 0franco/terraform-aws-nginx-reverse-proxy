output "proxy_public_ip" {
  description = "Public IPv4 address of the proxy. This is the Elastic IP when enabled."
  value       = local.proxy_public_ip
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
  description = "SSH command for the default Amazon Linux AMI user."
  value       = var.create_ssh_key ? "terraform output -raw generated_private_key_pem > ${local.selected_key_name}.pem && chmod 600 ${local.selected_key_name}.pem && ssh -i ${local.selected_key_name}.pem ec2-user@${local.proxy_public_ip}" : "ssh ec2-user@${local.proxy_public_ip}"
}

output "key_name" {
  description = "AWS EC2 key pair attached to the proxy instance."
  value       = local.selected_key_name
}

output "generated_private_key_pem" {
  description = "Generated private key for SSH access. Store it securely."
  value       = var.create_ssh_key ? tls_private_key.generated[0].private_key_pem : null
  sensitive   = true
}

output "elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID when enable_elastic_ip is true."
  value       = var.enable_elastic_ip ? aws_eip.proxy[0].id : null
}
