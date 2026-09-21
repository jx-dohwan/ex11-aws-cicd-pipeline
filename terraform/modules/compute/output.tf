output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.app.name
}

output "codedeploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.dg.deployment_group_name
}

output "codestar_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}
