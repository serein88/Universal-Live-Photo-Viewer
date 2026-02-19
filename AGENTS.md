# AGENTS.md

## 项目目标与用途
Universal Live Photo Viewer（ULPV）是一个跨平台（Windows / Android / iOS）的本地实况图片查看器。  
V1 目标聚焦 `iOS + Xiaomi/Google` 协议解析，支持查看、播放与导出；`Vivo/Huawei/OPPO` 进入后续迭代。

## 开发流程（必须遵守）
1. 领取一个任务（从 `TASK.md` 选定并将状态改为 `进行中`）。  
2. 开始编码。仅修改该任务直接相关文件，保持最小改动。发现新问题不插队，记入 `TASK.md` 或 `PROGRESS.md`。  
3. 测试验证。提供可复现步骤和关键证据（日志、截图、命令输出、可观察现象）。  
4. 更新任务状态。  
   - 成功：`进行中 -> 待确认`（用户确认后再 `完成`）。  
   - 失败：`进行中 -> 失败`，写明原因、阻塞点、下一步建议。  
   - 本轮摘要仅在“有代码修改”时追加到 `PROGRESS.md`。  
5. 提交代码。每一小步都应可回滚，提交信息必须包含任务名（如：`T3: xxx`）。

## 强约束
- 一轮只做一个任务。  
- 没有验证证据，不得标记 `完成`。  
- 每轮结束必须更新 `TASK.md`。  
- 仅当对代码进行修改时，追加 `PROGRESS.md` 记录。  
- 优先执行最小变更与可回滚变更；避免一次性大改。  
- 若任务目标与现状冲突，先在 `TASK.md` 备注风险；若本轮有代码修改，再同步到 `PROGRESS.md` 后与用户确认。

## Vibe Coding 哲学（2026-02-18 检索整理）
1. **把 vibe coding 用在低风险问题**：原型、实验、低影响工具优先，不直接用于高风险生产路径。  
2. **生产代码必须可解释**：不能解释代码在做什么，就不应提交。  
3. **测试不可外包给模型**：AI 生成再快，也必须通过可复现验证。  
4. **AI 审查是补充，不是替代**：保持人工审查与最终责任归属。  
5. **默认开启安全护栏**：工具调用需要审批；不可信输入必须做结构化隔离；对外部数据和密钥保持最小暴露。  
6. **对“提效”保持经验主义**：不同任务中 AI 可能加速，也可能减速；以实际测量为准。  
7. **小步迭代优于一把梭**：短回路、短提交、快速验证，才能控制“提示-代码-回归”的漂移风险。

## 可复用经验（执行清单）
- 开始前：先写清任务目标、验收标准、非目标。  
- 编码中：每次只改一个小点，先本地验证再继续。  
- 出错时：先回到最近可工作的提交点，再缩小问题面。  
- 收尾时：若本轮有代码修改，把“做了什么、怎么验证、还剩什么风险”写进 `PROGRESS.md`。

## 参考来源
- Simon Willison, *Not all AI-assisted programming is vibe coding (but vibe coding rocks)* (2025-03-19): https://simonwillison.net/2025/Mar/19/vibe-coding/  
- Simon Willison, *Here’s how I use LLMs to help me write code* (2025-03-11): https://simonwillison.net/2025/Mar/11/using-llms-for-code/  
- METR, *Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity* (2025-07-10): https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/  
- GitHub Docs, *Responsible use of GitHub Copilot code review*: https://docs.github.com/en/copilot/responsible-use/code-review  
- OpenAI Docs, *Safety in building agents*: https://platform.openai.com/docs/guides/agent-builder-safety  
