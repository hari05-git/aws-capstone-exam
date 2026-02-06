output "vpc_name" {
  value = aws_vpc.task_vpc.tags["Name"]
}

output "alb_dns_name" {
  value = aws_lb.task_alb.dns_name
}

output "web_instance_ips" {
  value = [
    aws_instance.web_1.public_ip,
    aws_instance.web_2.public_ip
  ]
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
