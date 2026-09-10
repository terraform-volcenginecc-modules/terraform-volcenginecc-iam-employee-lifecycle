# 项目与职责组先建立，人员和授权模块通过输出引用实际名称。
resource "volcenginecc_iam_project" "this" {
  for_each     = var.projects
  project_name = "${var.name_prefix}-${each.key}"
  display_name = each.value.display_name
  description  = each.value.description
}

# users 与 attached_policies 由其他资源管理，此处保留为计算属性。
resource "volcenginecc_iam_group" "this" {
  for_each        = var.groups
  user_group_name = "${var.name_prefix}-${each.key}"
  display_name    = each.value.display_name
  description     = each.value.description
}
