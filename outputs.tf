output "user_names" {
  description = "逻辑员工名到实际 IAM 用户名的映射"
  value       = module.identities.user_names
}

output "group_names" {
  description = "本工程用户组逻辑键到实际名称的映射"
  value       = module.foundation.group_names
}

output "project_names" {
  description = "本工程项目逻辑键到实际项目名的映射"
  value       = module.foundation.project_names
}

output "policy_names" {
  description = "通用策略及各项目策略的实际名称"
  value       = module.authorization.policy_names
}

output "access_credentials" {
  description = "可选编程访问凭证；仅通过安全凭证分发流程读取，JSON 输出与 State 含明文"
  sensitive   = true
  value       = module.identities.access_credentials
}
