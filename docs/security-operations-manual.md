# 安全操作手册（GitHub 仓库）

## 适用范围
- 仓库：`Universal-Live-Photo-Viewer`
- 目标：约束机器人凭据、发布流程、Secrets 与权限边界，降低凭据泄漏与误发布风险。

## 1. 机器人身份与令牌策略
1. 优先使用 **GitHub App**；次选 **细粒度 PAT（Fine-grained PAT）**。
2. 禁止长期使用个人全权限 Classic PAT。
3. 机器人凭据要求：
   - 独立于个人账号。
   - 到期时间明确（PAT 必须设置过期时间）。
   - 仅授予执行任务必需仓库范围。
4. 建议命名：
   - GitHub App：`ulpv-ci-bot`
   - Fine-grained PAT：`ULPV_CI_BOT_TOKEN`

## 2. 最小权限基线
对自动化机器人（GitHub App 或细粒度 PAT）默认仅授予：
- `contents:write`
- `pull_requests:write`
- `actions:write`

> 如无必要，继续收紧到 `read` 或移除未使用权限。

## 3. 分支保护（main）
对 `main` 启用保护规则：
1. 禁止直接 push。
2. 必须通过 Pull Request 合并。
3. 建议开启：
   - 至少 1 位 Review 批准。
   - 必需状态检查（按仓库实际 CI 任务选择）。
   - 阻止强制推送与删除分支。

## 4. Secrets 分层与隔离
将 secrets 按用途分层：

### 4.1 普通 CI Secrets
- 仅用于编译、测试、静态检查。
- 禁止放入签名证书、发布凭据、商店账户密钥。

### 4.2 发布 Secrets（高敏感）
- 仅用于发布签名/上传。
- 必须绑定到受保护 Environment（如 `production-release`）。
- 仅在发布作业且审批通过后可见。

## 5. Environment 保护规则（发布审批）
发布环境（建议名：`production-release`）必须启用：
1. **Required reviewers**（人工审批）。
2. 可选等待时间（Wait timer）。
3. 限制可部署分支（建议仅 `main` / `release/*`）。

仓库中 `release-governance.yml` 已将发布预检任务绑定到 `production-release`，用于承载审批与高敏感 secrets。 

## 6. 令牌轮换与审计

### 6.1 轮换周期
- GitHub App 私钥：每 **90 天**轮换。
- Fine-grained PAT：每 **30 天**轮换（最长不超过 90 天）。
- 发生权限变更、人员变动、异常访问时立即轮换。

### 6.2 泄漏应急（SOP）
1. 立刻吊销泄漏凭据（App 私钥/PAT）。
2. 在 GitHub 安全日志中确认异常来源与影响范围。
3. 轮换关联 Secrets（发布与 CI）。
4. 暂停发布工作流，完成复盘后恢复。
5. 在 `PROGRESS.md` 或安全事件记录中留档处置时间线。

### 6.3 权限审计责任
- **责任人（Owner）**：仓库管理员（Repo Admin）。
- **审计频率**：每月一次，覆盖：
  - 机器人权限是否超配；
  - 分支保护是否被弱化；
  - Environment 审批人是否仍在岗；
  - Secrets 是否存在过期或无主项。
