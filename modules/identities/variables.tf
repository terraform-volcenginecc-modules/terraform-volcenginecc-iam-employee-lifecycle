variable "name_prefix" {
  type        = string
  description = "工程独占前缀"
}
variable "environment" {
  type        = string
  description = "环境标签"
}
variable "group_names" {
  type        = map(string)
  description = "已创建的用户组名称"
}
variable "offboarding_group" {
  type        = string
  description = "无权限归档组逻辑键"
}
variable "initial_passwords" {
  type        = map(string)
  description = "由运行环境提供的初始密码"
  sensitive   = true
  default     = null
}
variable "iam_users" {
  type = list(object({
    user_name         = string
    display_name      = string
    description       = string
    groups            = set(string)
    projects          = set(string)
    is_offboarding    = bool
    enable_login      = bool
    enable_access_key = bool
  }))
  description = "经过根模块规范化的人员清单"
}
