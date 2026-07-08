output "web_url" {
  description = "Open this URL in your browser"
  value       = "http://${aws_instance.web.public_dns}"
}

output "web_public_ip" {
  description = "Public IP of web EC2 instance"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Private RDS endpoint"
  value       = aws_db_instance.mysql.address
}

output "db_username" {
  description = "Database username"
  value       = var.db_username
}

output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}
