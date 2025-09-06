output "ssh_cmd" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.web.public_ip}"
}
