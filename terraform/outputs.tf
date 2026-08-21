output "server_public_ip" {
  description = "Javna ip adresa EC2 servera"
  value       = aws_instance.devops-server.public_ip
}

output "vpc_id" {
  description = "ID kreiranog VPC-a"
  value       = aws_vpc.devops_vpc.id
}

output "ssh_connection_command" {
  description = "Komanda za povezivanje na server"
  value       = "ssh -i ~/.ssh/devops-key ubuntu@${aws_instance.devops-server.public_ip}"
}