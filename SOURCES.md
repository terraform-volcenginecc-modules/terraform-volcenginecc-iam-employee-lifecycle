# Provider 与能力依据

生成时间：2026-09-09。固定 Provider：`volcengine/volcenginecc` `0.0.69`。Terraform Schema 来自实际初始化后的 `terraform providers schema -json`，Cloud Control 能力与权限来自实际 `DescribeResourceType` 返回。

- [IAM User](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.69/docs/resources/iam_user)
- [IAM Group](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.69/docs/resources/iam_group)
- [IAM Policy](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.69/docs/resources/iam_policy)
- [IAM Project](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.69/docs/resources/iam_project)
- [IAM AccessKey](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.69/docs/resources/iam_accesskey)

## 采用的具体字段与边界

| 对象 | 已核实的字段或行为 |
| --- | --- |
| User | user_name 不可变；groups 可更新；login_profile 支持 LoginAllowed、Password、PasswordResetRequired；Tags 支持创建和更新 |
| Group | user_group_name 不可变；users 和 attached_policies 为 optional/computed，本模板由关联的其他资源管理 |
| Policy | policy_name、policy_type 不可变；policy_users、policy_user_groups 支持绑定与更新；policy_scope 的可配置字段为 project_name |
| Project | project_name 与 parent_project_name 为创建时字段；本模板只创建独占根级测试项目 |
| AccessKey | user_name 为创建时字段；status 支持 active/inactive；SecretAccessKey 为敏感运行数据，输出与状态必须保护 |

同版本 Registry 示例中可能出现不属于可配置 Schema 的字段，本模板按实际 Schema 选择字段，并通过真实 Terraform validate 检查。

以上依据确认了声明结构和字段能力，不替代服务端创建、绑定、回读、幂等及销毁验证；本次执行范围与未完成项见 VALIDATION.md。

## 只读规范化依据

- 同版本 Provider Schema 的 `iam_policies` / `iam_policy` 数据源提供策略标识与实际绑定；`iam_users` / `iam_user` 提供用户标识与登录状态。
- [Provider 完整分页实现](https://github.com/volcengine/terraform-provider-volcenginecc/blob/v0.0.69/internal/service/cloudcontrol/list.go)：已核实遍历 NextToken 直到结束。
- [官方用户管理说明](https://www.volcengine.com/docs/6257/64977)：控制台登录与编程访问分别配置。

空绑定、全局作用域以及缺少登录配置的行为均由实际 API/Plan/Apply 回读确认，修复与复验过程见 VALIDATION.md。
