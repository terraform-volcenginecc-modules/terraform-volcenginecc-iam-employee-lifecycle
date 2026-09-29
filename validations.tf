# 跨变量输入校验集中在根模块，通过 terraform_data 的 lifecycle.precondition 实现硬阻断，
# 替代 variable.validation 中对其他变量的引用（1.9 之前不支持），以兼容 Terraform 1.5.7。
# precondition 失败为硬错误，会中止 plan/apply，避免无效配置继续生成资源计划。
# terraform_data 为 Terraform 1.4 引入的内置资源，不创建任何云资源。
resource "terraform_data" "input_validations" {
  lifecycle {
    # 原 offboarding_group 校验：归档组必须存在，且不得加入通用权限授权组。
    precondition {
      condition     = contains(keys(var.groups), var.offboarding_group) && !contains(var.common_policy_groups, var.offboarding_group)
      error_message = "归档组必须存在，并且不得加入通用权限授权组。"
    }

    # 原 common_policy_groups 校验：只能引用 groups 中已定义的组。
    precondition {
      condition     = alltrue([for group in var.common_policy_groups : contains(keys(var.groups), group)])
      error_message = "common_policy_groups 只能引用 groups 中已定义的组。"
    }

    # 原 iam_users 校验：员工的 groups/projects 必须引用本工程已定义的组与项目。
    precondition {
      condition = alltrue([
        for user in var.iam_users :
        alltrue([for group in user.groups : contains(keys(var.groups), group)]) &&
        alltrue([for project in user.projects : contains(keys(var.projects), project)])
      ])
      error_message = "员工的 groups/projects 必须引用本工程已定义的组与项目。"
    }
  }
}
