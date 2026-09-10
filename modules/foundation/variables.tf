variable "name_prefix" {
  type        = string
  description = "工程独占前缀"
}
variable "projects" {
  type        = map(object({ display_name = string, description = string }))
  description = "要创建的项目"
}
variable "groups" {
  type        = map(object({ display_name = string, description = string }))
  description = "要创建的职责组及归档组"
}
