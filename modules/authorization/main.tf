# 通用权限通过职责组继承，归档组无绑定；项目权限通过策略绑定的项目范围实现。
# Provider 0.0.69 把空绑定回读为 null。只读查询用于区分“需要清空旧绑定”与
# “远端已经无绑定”，既保留撤权动作，也避免 [] 与 null 的永久差异。
# 列表只返回标识；详情查询严格限定为本工程声明的项目策略。
data "volcenginecc_iam_policies" "existing" {}

locals {
  existing_project_policy_ids = {
    for key in keys(var.project_names) : key => one([
      for id in data.volcenginecc_iam_policies.existing.ids : id
      if id == "${var.name_prefix}-${key}-access|Custom"
    ]) if contains(data.volcenginecc_iam_policies.existing.ids, "${var.name_prefix}-${key}-access|Custom")
  }
  desired_project_users = {
    for project_key, project_name in var.project_names : project_key => [
      for user in var.iam_users : {
        name         = var.user_names[user.user_name]
        policy_scope = [{ project_name = project_name }]
      } if !user.is_offboarding && contains(user.projects, project_key)
    ]
  }
}

data "volcenginecc_iam_policy" "current" {
  for_each = local.existing_project_policy_ids
  id       = each.value
}

resource "volcenginecc_iam_policy" "common" {
  policy_name     = "${var.name_prefix}-common-read"
  policy_type     = "Custom"
  description     = "Minimal global discovery permission for active employee groups"
  policy_document = jsonencode({ Statement = [{ Effect = "Allow", Action = sort(tolist(var.common_policy_actions)), Resource = ["*"] }] })
  policy_user_groups = [
    for group in sort(tolist(var.common_policy_groups)) : {
      name         = var.group_names[group]
      policy_scope = [{ project_name = "" }]
    }
  ]
}

resource "volcenginecc_iam_policy" "project" {
  for_each        = var.project_names
  policy_name     = "${var.name_prefix}-${each.key}-access"
  policy_type     = "Custom"
  description     = "Project scoped employee access managed by Terraform"
  policy_document = jsonencode({ Statement = [{ Effect = "Allow", Action = sort(tolist(var.project_policy_actions)), Resource = ["*"] }] })
  policy_users = length(local.desired_project_users[each.key]) > 0 ? local.desired_project_users[each.key] : (
    try(length(data.volcenginecc_iam_policy.current[each.key].policy_users), 0) > 0 ? [] : null
  )
}
