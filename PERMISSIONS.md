# 执行与验证权限清单

本清单来自 2026-09-09 实际调用 Cloud Control `DescribeResourceType` 返回的 handler.permissions。它是动作依赖清单，管理员需要结合资源 TRN、测试前缀和 IAM 各动作支持的作用域设置策略；不自动为执行身份授权，也不建议直接授予整个账号的管理员权限。

## 权限验证结果

本轮隔离实测已经完成。较早提供的执行身份曾缺少目标测试对象的 iam:GetUser 等必要权限；更换已授权的验证身份后，实际完成了创建、更新、登录配置、绑定、密钥管理、回读及清理。

模板为保证空值规范化与撤权正确性，Plan 阶段需要 ListPolicies；关闭登录的配置还会使用 ListUsers。列表只取标识，详情查询限定为本工程声明的已有对象。相关读取失败会中止 Plan，不以空结果继续执行。

GetAccountSummary 用于本次配额与清理基线核查，不是模板资源编排的必需业务动作。生产环境请按目标资源范围配置所需权限，不直接复制测试身份的权限等级。

## Cloud Control 调用

需要覆盖实际使用的 DescribeResourceType、CreateResource、GetResource、UpdateResource、DeleteResource、GetTask 等动作。Cloud Control 权限与下列底层 IAM 权限须同时满足。列表和残留核查还会使用相关 List 动作，按验证资源范围配置。

## 各类资源依赖

### Volcengine::IAM::Accesskey

`iam:CreateAccessKey`, `iam:DeleteAccessKey`, `iam:GetAccessKeyLastUsed`, `iam:GetLoginProfile`, `iam:GetUser`, `iam:ListAccessKeys`, `iam:UpdateAccessKey`

### Volcengine::IAM::Group

`iam:AddUserToGroup`, `iam:AttachUserGroupPolicy`, `iam:CreateGroup`, `iam:DeleteGroup`, `iam:DetachUserGroupPolicy`, `iam:GetGroup`, `iam:ListAttachedUserGroupPolicies`, `iam:ListUsersForGroup`, `iam:RemoveUserFromGroup`, `iam:UpdateGroup`

### Volcengine::IAM::Policy

`iam:AttachPolicyInProject`, `iam:AttachRolePolicy`, `iam:AttachUserGroupPolicy`, `iam:AttachUserPolicy`, `iam:CreatePolicy`, `iam:DeletePolicy`, `iam:DetachPolicyInProject`, `iam:DetachRolePolicy`, `iam:DetachUserGroupPolicy`, `iam:DetachUserPolicy`, `iam:GetPolicy`, `iam:ListEntitiesForPolicy`, `iam:UpdatePolicy`

### Volcengine::IAM::Project

`iam:CreateProject`, `iam:DeleteProject`, `iam:GetProject`, `iam:UpdateProject`

### Volcengine::IAM::User

`iam:AddUserToGroup`, `iam:AttachUserPolicy`, `iam:CreateLoginProfile`, `iam:CreateUser`, `iam:DeleteUser`, `iam:DetachUserPolicy`, `iam:GetAccessKeyLastUsed`, `iam:GetLoginProfile`, `iam:GetSecurityConfig`, `iam:GetUser`, `iam:ListAccessKeys`, `iam:ListAttachedUserPolicies`, `iam:ListGroupsForUser`, `iam:RemoveUserFromGroup`, `iam:SetSecurityConfig`, `iam:TagResources`, `iam:UntagResources`, `iam:UpdateLoginProfile`, `iam:UpdateUser`

## 验证专用动作

独立员工通过 `ecs:DescribeRegions` 验证用户组继承。项目权限可使用 VPC CreateVpc 的 DryRun 验证允许与拒绝，验证参数才加入 `vpc:CreateVpc`，且必须限定为本轮两个测试项目。默认交付参数只有 `vpc:DescribeVpcs`，不默认授予创建权限。

对 IAM 用户、组、策略、项目及密钥的实际授权范围应限制在本工程的独占测试对象；动作若不支持资源级条件，需要管理员评估最小必要范围。未执行过真实 Apply 的模板仍需验证 handler 的实际调用和服务端限制，不能仅凭此清单宣称权限已满足。
