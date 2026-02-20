# ULPV V1 技术路线与需求边界设计（已确认）

**日期**：2026-02-19  
**范围**：V1 技术边界（架构、依赖、测试、发布）+ 需求边界（In/Out Scope）

---

## 1. 已确认决策

1. 架构复杂度：中等分层（UI + Application + Domain + Data/Parser）
2. 依赖策略：适配层隔离三方插件，业务层不直接依赖插件
3. 测试策略：高强度测试（单测 + 用例 + 组件 + 冒烟 + 多平台回归）
4. 发布策略：侧载优先（Windows 绿色包 + Android APK + iOS 测试分发）

---

## 2. 技术路线对比与结论

### 2.1 候选路线

- 方案 A（快速交付型）：前期快，后期维护压力高
- 方案 B（工程平衡型）：前期适中，长期可维护性平衡
- 方案 C（质量先行型）：治理最强，V1 周期最长

### 2.2 结论

采用 **方案 B（工程平衡型）**。理由：满足 V1 交付速度，同时避免后续因插件耦合和测试缺失导致返工。

---

## 3. 架构边界（Architecture Boundary）

1. 分层固定：`UI -> Application -> Domain -> Data/Parser`
2. 依赖方向单向：禁止反向依赖
3. `Domain` 仅包含实体、值对象、协议接口
4. `Application` 仅编排用例，不做底层解析
5. `Data/Parser` 负责文件 IO、XMP/Exif、协议切片
6. `UI` 不直接访问文件系统、不直接调用第三方插件
7. V1 非目标：不做重型模块拆包与插件深度定制

---

## 4. 依赖边界（Dependency Boundary）

### 4.1 统一 Port

- `MediaPickerPort`
- `VideoPlaybackPort`
- `ExportPort`
- `FileSystemPort`

### 4.2 规则

1. 业务层禁止直接 import `video_player`、`file_picker`、`ffmpeg_kit_flutter`
2. 每个 Port 同时提供 `Adapter`（生产）与 `Fake`（测试）实现
3. 插件异常统一转换为业务错误码（如 `ExportFailure`、`PlaybackInitFailure`）
4. V1 冻结主依赖大版本，升级前先跑回归
5. Adapter 输出结构化日志：任务 ID、文件路径、耗时、结果码

---

## 5. 测试边界（Testing Boundary）

### 5.1 测试层级

- Parser 单测
- Application 用例测试
- UI 组件测试
- E2E 冒烟测试
- 多平台回归测试（Win/Android/iOS）

### 5.2 门禁

1. Parser 核心用例覆盖率 >= 85%
2. Application 用例覆盖率 >= 80%
3. 合入前通过 1 条完整冒烟链路：扫描 -> 识别 -> 播放 -> 导出
4. 发布前 Win/Android/iOS 各至少 1 轮回归通过

### 5.3 数据与失败处理

1. 固定样本集（iOS + Xiaomi/Google）+ 期望结果清单
2. 失败样本必须可复现（输入、日志、错误码、预期/实际）
3. 门禁失败不得标记任务“完成”

---

## 6. 发布边界（Release Boundary）

1. Windows：`flutter build windows --release` + 绿色版压缩包
2. Android：APK 侧载包（V1 不承诺 Play 审核）
3. iOS：测试分发，文档目录导入为主流程
4. Android `MANAGE_EXTERNAL_STORAGE` 仅用于 V1 侧载路径
5. 每个发布包附：版本号、构建时间、提交哈希、已知限制
6. V1 非目标：自动更新、商店素材与审核流程

---

## 7. 需求边界（Scope Boundary）

### 7.1 In Scope（V1 必做）

- 协议：iOS 双文件、Xiaomi/Google Motion Photo
- 流程：扫描、识别、播放、导出
- 导出：视频/静图/GIF
- 缓存：临时文件可追踪并清理
- 日志：关键节点可定位

### 7.2 Out of Scope（V1 不做）

- Vivo/Huawei/OPPO 协议
- iOS 直读系统照片库原始协议
- 云同步、账号体系、在线分享
- 批量高级编辑
- 应用商店合规改造

---

## 8. 验收与失败边界

### 8.1 验收标准

1. 样本识别成功率 >= 95%
2. 已识别样本播放成功率 = 100%
3. 导出三功能均可用且失败可追踪
4. 三平台回归通过
5. 发布文档齐全（限制/回滚/构建信息）

### 8.2 Fail Fast

1. 未识别样本降级为静图，不得崩溃
2. 解析失败不得污染原文件
3. 导出失败必须返回错误码 + 阶段 + 文件路径
4. 任一门禁失败，不得标记“完成”

---

## 9. 后续动作

1. 进入实施计划：按 `docs/plans/2026-02-19-ulpv-v1-foundation.md` 执行
2. 先做 V1，后续协议扩展单开任务（Vivo/Huawei/OPPO）
