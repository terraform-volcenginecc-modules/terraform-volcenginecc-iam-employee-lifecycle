name_prefix = "game-iam"
region      = "cn-beijing"
environment = "poc"

# 入职：加入研发组并获得 Alpha 项目的只读权限。
# 默认不创建登录密码或访问密钥，需要时由安全运行环境提供密码并打开开关。
iam_users = [
  {
    user_name         = "employee01"
    display_name      = "示例员工"
    groups            = ["developers"]
    projects          = ["alpha"]
    enable_login      = false
    enable_access_key = false
    is_offboarding    = false
  }
]
