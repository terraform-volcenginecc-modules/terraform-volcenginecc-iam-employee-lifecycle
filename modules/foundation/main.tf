# 模块：foundation（基础对象）
# 封装资源：volcenginecc_iam_project（项目）、volcenginecc_iam_group（用户组）。
# 提供功能：按 name_prefix 统一命名，创建本工程独占的游戏项目和职责/归档用户组，
#           并输出逻辑键到实际名称的映射，供 identities 和 authorization 模块引用。
# 典型场景：作为生命周期编排的第一步，先建立项目与组，再由后续模块挂接人员与授权。
#
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
