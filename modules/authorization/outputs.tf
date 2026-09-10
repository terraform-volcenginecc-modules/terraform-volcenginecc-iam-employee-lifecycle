output "policy_names" {
  description = "供权限核查使用的策略名称"
  value = {
    common   = volcenginecc_iam_policy.common.policy_name
    projects = { for key, policy in volcenginecc_iam_policy.project : key => policy.policy_name }
  }
}
