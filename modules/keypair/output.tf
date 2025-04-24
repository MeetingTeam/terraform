output "id" {
  value = data.aws_key_pair.keypair.id
}

output "key_name" {
  value = data.aws_key_pair.keypair.key_name
}