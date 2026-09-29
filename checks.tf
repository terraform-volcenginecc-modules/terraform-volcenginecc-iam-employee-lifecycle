# 跨变量校验集中在根模块的 check 块中，替代 variable.validation 中对其他变量的引用，
# 以兼容 Terraform 1.5.7（1.9 之前 variable.validation 只能引用变量自身）。
# check/assert 为 Terraform 1.5.0 引入特性。

check "variable_relationships" {
  # 原 offboarding_group 校验：归档组必须存在，且不得加入通用权限授权组。
  assert {
    condition = contains(keys(var.groups), var.offboarding_group) && !contains(var.common_policy_groups, var.offboarding_group)
    error_message = "归档组必须存在，并且不得加入通用权限授权组。"
  }

  # 原 common_policy_groups 校验：只能引用 groups 中已定义的组。
  assert {
    condition = alltrue([for group in var.common_policy_groups : contains(keys(var.groups), group)])
    error_message = "common_policy_groups 只能引用 groups 中已定义的组。"
  }

  # 原 iam_users 校验：员工的 groups/projects 必须引用本工程已定义的组与项目。
  assert {
    condition = alltrue([
      for user in var.iam_users :
      alltrue([for group in user.groups : contains(keys(var.groups), group)]) &&
      alltrue([for project in user.projects : contains(keys(var.projects), project)])
    ])
    error_message = "员工的 groups/projects 必须引用本工程已定义的组与项目。"
  }
}
