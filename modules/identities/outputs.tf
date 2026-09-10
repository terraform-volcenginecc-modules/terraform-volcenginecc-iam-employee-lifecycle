output "user_names" {
  description = "实际用户名，用于项目策略绑定及操作核对"
  value       = { for key, user in volcenginecc_iam_user.this : key => user.user_name }
}
output "access_credentials" {
  description = "可选密钥，用于安全分发；Provider 将其保存到 State"
  sensitive   = true
  value = {
    for key, access in volcenginecc_iam_accesskey.this : key => {
      access_key_id     = access.access_key_id
      secret_access_key = access.secret_access_key
      status            = access.status
    }
  }
}
