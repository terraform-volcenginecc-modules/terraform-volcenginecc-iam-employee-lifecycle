variable "name_prefix" {
  type        = string
  description = "工程独占前缀"
}
variable "user_names" {
  type        = map(string)
  description = "实际员工名称"
}
variable "group_names" {
  type        = map(string)
  description = "实际职责组名称"
}
variable "project_names" {
  type        = map(string)
  description = "实际项目名，用作 Project 授权范围"
}
variable "common_policy_groups" {
  type        = set(string)
  description = "获得通用权限的职责组逻辑键"
}
variable "common_policy_actions" {
  type        = set(string)
  description = "全局通用查询操作"
}
variable "project_policy_actions" {
  type        = set(string)
  description = "限定在项目作用域内的业务操作"
}
variable "iam_users" {
  type = list(object({
    user_name      = string
    projects       = set(string)
    is_offboarding = bool
  }))
  description = "项目关联和在职状态；归档自动解除项目授权"
}
