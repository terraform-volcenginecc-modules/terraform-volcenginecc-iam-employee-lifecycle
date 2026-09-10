# 员工用户名为稳定 for_each 键；转岗只修改关联，离职可保留身份供审计。
locals {
  users = { for user in var.iam_users : user.user_name => user }
  existing_login_user_ids = {
    for key, user in local.users : key => one([
      for id in try(data.volcenginecc_iam_users.existing[0].ids, []) : id
      if id == "${var.name_prefix}-${key}"
    ]) if !user.enable_login && contains(try(data.volcenginecc_iam_users.existing[0].ids, []), "${var.name_prefix}-${key}")
  }
}

# 不启用登录的新用户无需登录配置；已有用户则读取实际登录状态，主动关闭仍开放的登录。
data "volcenginecc_iam_users" "existing" {
  count = anytrue([for user in var.iam_users : !user.enable_login]) ? 1 : 0
}

data "volcenginecc_iam_user" "login_state" {
  for_each = local.existing_login_user_ids
  id       = each.value
}

resource "volcenginecc_iam_user" "this" {
  for_each     = local.users
  user_name    = "${var.name_prefix}-${each.key}"
  display_name = each.value.display_name
  description  = each.value.description
  groups = each.value.is_offboarding ? [var.group_names[var.offboarding_group]] : [
    for group in each.value.groups : var.group_names[group]
  ]
  # policies 由 authorization 模块统一管理，避免全局绑定覆盖项目域授权。
  login_profile = each.value.enable_login ? {
    login_allowed           = !each.value.is_offboarding
    password                = try(var.initial_passwords[each.key], null)
    password_reset_required = true
    safe_auth_flag          = false
    } : (
    coalesce(try(data.volcenginecc_iam_user.login_state[each.key].login_profile.login_allowed, null), false) ? {
      login_allowed           = false
      password                = null
      password_reset_required = null
      safe_auth_flag          = null
    } : null
  )
  tags = [
    { key = "Project", value = var.name_prefix },
    { key = "Environment", value = var.environment },
    { key = "Lifecycle", value = each.value.is_offboarding ? "offboarded" : "active" }
  ]
  lifecycle {
    precondition {
      condition     = !each.value.enable_login || try(length(var.initial_passwords[each.key]) >= 12, false)
      error_message = "启用控制台登录的员工必须通过 initial_passwords 提供满足账号策略的初始密码。"
    }
    postcondition {
      condition     = coalesce(try(self.login_profile.login_allowed, null), false) == (each.value.enable_login && !each.value.is_offboarding)
      error_message = "实际登录状态与人员期望状态不一致，停止交付并核对登录配置。"
    }
  }
}

# 归档将已管理密钥禁用；从列表移除员工或关闭密钥开关则删除密钥。
resource "volcenginecc_iam_accesskey" "this" {
  for_each  = { for key, user in local.users : key => user if user.enable_access_key }
  user_name = volcenginecc_iam_user.this[each.key].user_name
  status    = each.value.is_offboarding ? "inactive" : "active"
}
