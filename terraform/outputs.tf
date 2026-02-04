output "instance_ip" {
  description = "Public IP of instance."
  value       = aws_instance.app_server.public_ip
}
