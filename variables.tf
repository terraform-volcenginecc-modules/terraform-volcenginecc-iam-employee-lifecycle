variable "region" {
  type        = string
  description = "Provider API 调用地域；本方案管理账号级 IAM 对象"
  default     = "cn-beijing"
}

variable "name_prefix" {
  type        = string
  description = "本工程独占的资源名称前缀；更改会创建新身份，请勿用于员工转岗"
  default     = "game-iam"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.name_prefix))
    error_message = "name_prefix 使用 3–24 位小写字母、数字或连字符，并以字母开头。"
  }
}

variable "environment" {
  type        = string
  description = "员工资源的环境标签"
  default     = "poc"
}

variable "projects" {
  type = map(object({
    display_name = string
    description  = optional(string, "Game project managed by Terraform")
  }))
  description = "本工程创建的项目，键为逻辑项目名；与员工 projects 引用对应"
  default = {
    alpha = { display_name = "游戏项目 Alpha" }
    beta  = { display_name = "游戏项目 Beta" }
  }
}

variable "groups" {
  type = map(object({
    display_name = string
    description  = optional(string, "Employee role managed by Terraform")
  }))
  description = "本工程创建的用户组，包括无权限的离职归档组"
  default = {
    developers = { display_name = "游戏研发" }
    operations = { display_name = "游戏运维" }
    offboarded = { display_name = "离职归档" }
  }
}

variable "offboarding_group" {
  type        = string
  description = "离职归档组的逻辑键；此组不得被 common_policy_groups 授权"
  default     = "offboarded"
  # 跨变量校验（引用 var.groups、var.common_policy_groups）迁移至根模块 checks.tf 的 check 块，
  # 以兼容 Terraform 1.5.7（1.9 之前不允许 validation 引用其他变量）。
}

variable "common_policy_groups" {
  type        = set(string)
  description = "继承通用只读权限的工作组逻辑键"
  default     = ["developers", "operations"]
  # 跨变量校验（引用 var.groups）迁移至根模块 checks.tf 的 check 块，以兼容 Terraform 1.5.7。
}

variable "common_policy_actions" {
  type        = set(string)
  description = "用户组通用权限；默认仅查询地域，使用全局作用域，不包含项目业务操作"
  default     = ["ecs:DescribeRegions"]
}

variable "project_policy_actions" {
  type        = set(string)
  description = "通过 Project 作用域直接授予员工的操作；默认仅查询 VPC，按业务最小化调整"
  default     = ["vpc:DescribeVpcs"]
}

variable "iam_users" {
  type = list(object({
    user_name         = string
    display_name      = string
    description       = optional(string, "Game employee managed by Terraform")
    groups            = optional(set(string), [])
    projects          = optional(set(string), [])
    is_offboarding    = optional(bool, false)
    enable_login      = optional(bool, false)
    enable_access_key = optional(bool, false)
  }))
  description = "唯一人员配置入口：新增为入职，修改 groups/projects 为转岗，is_offboarding 为归档，移除条目为删除"
  default     = []
  validation {
    condition     = length(distinct([for user in var.iam_users : user.user_name])) == length(var.iam_users)
    error_message = "iam_users 的 user_name 必须唯一。"
  }
  validation {
    condition     = alltrue([for user in var.iam_users : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,29}$", user.user_name))])
    error_message = "员工 user_name 需为 1–30 位英文、数字、下划线、点或连字符。"
  }
  # groups/projects 引用完整性校验（引用 var.groups、var.projects）迁移至根模块 checks.tf 的 check 块，
  # 以兼容 Terraform 1.5.7。
}

variable "initial_passwords" {
  type        = map(string)
  description = "启用控制台登录时传入的初始密码，键对应员工 user_name；仅通过安全运行环境提供"
  sensitive   = true
  default     = null
}
