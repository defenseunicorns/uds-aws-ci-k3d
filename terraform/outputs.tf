output "instance_id" {
  value = aws_instance.ec2_instance.id
}

output "secret_name" {
  value = aws_secretsmanager_secret.kubeconfig.name
}
