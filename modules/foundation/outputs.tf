output "project_names" {
  description = "项目名称，用于 Project 作用域授权"
  value       = { for key, project in volcenginecc_iam_project.this : key => project.project_name }
}
output "group_names" {
  description = "用户组名称，用于员工入组和策略绑定"
  value       = { for key, group in volcenginecc_iam_group.this : key => group.user_group_name }
}
