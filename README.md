# 项目开发文档：Universal Live Photo Viewer (代号：ULPV)

## 1. 项目愿景与需求 (Project Vision)
**核心目标**：开发一款跨平台（Windows, Android, iOS）的本地实况图片查看器。  
**解决痛点**：解决用户更换手机品牌后，由于厂商私有协议壁垒（iOS, 小米, 华为, Vivo, OPPO 等），导致原有实况照片（Live Photos / Motion Photo）变为普通静态图或无法播放的问题。

**产品形态**：
* **Windows**：绿色免安装软件（文件夹形式），解压即用。
* **Android/iOS**：安装包分发。
* **核心体验**：三端交互一致、切图流畅、支持查看与导出。

### 1.1 当前固定决策（2026-02-18）
1. Android 端 **V1 目标为侧载可用**，不以 Google Play 上架为约束。  
2. iOS 端 **V1 采用文件导入到 App 文档目录** 的方案。  
3. V1 先做 `iOS + Xiaomi/Google`，`Vivo/Huawei/OPPO` 保留在后续阶段，不删除需求。

### 1.2 范围分层
**V1（必须交付）**：
* iOS 双文件 Live Photo 解析（HEIC/JPG + MOV）。
* Xiaomi / Google Motion Photo（XMP Offset）解析。
* Windows + Android + iOS 的查看、播放、导出基础能力。

**后续版本（扩展交付）**：
* Vivo / Huawei / OPPO 协议适配与稳定性提升。
* 更丰富的导出参数、批量处理、多语言完善。

---

## 2. 技术栈架构 (Tech Stack)
本项目采用 **Flutter** 作为统一开发框架，利用 Dart 的二进制处理能力实现“一套代码，全端运行”。

| 模块分类 | 关键技术选型 | 详细说明与选型理由 |
| :-- | :-- | :-- |
| **开发语言** | **Dart (v3.x+)** | 使用 `dart:io` 和 `dart:typed_data` 进行二进制读取与文件切片。 |
| **UI 框架** | **Flutter (v3.x+)** | 统一三端 UI 与交互行为。 |
| **图片渲染** | **extended_image** | 支持缩放、拖拽、手势控制。 |
| **视频播放** | **video_player** | 官方插件，稳定，便于封装双层播放。 |
| **多媒体处理** | **ffmpeg_kit_flutter** | 用于 GIF/视频导出。 |
| **元数据解析** | **xml** / **exif** | 用于 XMP / Exif 特征识别。 |
| **文件选择** | **file_picker** | 跨平台文件/目录选择。 |
| **状态管理** | **Provider**（或 Riverpod） | 管理索引、文件列表、播放器状态。 |
| **Windows 定制** | **bitsdojo_window** | 自定义窗口与标题栏交互。 |

---

## 3. 核心系统架构 (System Architecture)
系统采用 **分层架构 (Layered Architecture)**，确保解析逻辑与 UI 解耦。  
`[UI Layer]` <-> `[State Management]` <-> `[Domain/Model]` <-> `[Data/Parsing Layer]`

### 3.1 数据层：通用解析引擎 (Parsing Engine)
**设计模式**：策略模式 (Strategy Pattern)。

```dart
abstract class LivePhotoParser {
  Future<bool> match(File file);
  Future<LivePhotoEntity> parse(File file);
}
```

**V1 必做策略**：
1. `IOSParser`（双文件流）  
   - 逻辑：同目录配对 `HEIC/JPG + MOV`。  
   - 匹配优先级：`AssetIdentifier(UUID)` 优先，文件名匹配为兜底。  
2. `MotionPhotoParser`（Xiaomi/Google 内嵌流）  
   - 逻辑：读取 JPG XMP，提取 `MicroVideoOffset` 后切出视频段。

**后续扩展策略（非 V1）**：
1. `VivoParser`（私有尾部标记 / MakerNote）。  
2. `HuaweiParser`（`ubiff` 或厂商 XMP 标签）。  
3. `OppoParser`（待样本驱动补齐协议特征）。

### 3.2 实体模型 (Domain Model)
```dart
enum LivePhotoType {
  IOS,
  MOTION_PHOTO,
  XIAOMI,
  VIVO,
  HUAWEI,
  OPPO,
  UNKNOWN
}

class LivePhotoEntity {
  final String id;
  final String imagePath;
  final String? videoPath;
  final LivePhotoType type;

  Future<void> dispose() async {
    if (isTempFile(videoPath)) {
      await File(videoPath!).delete();
    }
  }
}
```

### 3.3 交互层：双层播放器 (Dual-Layer Player)
使用 `Stack` 双层渲染：
* Layer 1：`ExtendedImage`（常驻静图底层）。
* Layer 2：`VideoPlayer`（播放时显示）。

播放策略：
1. 触发：翻页稳定或长按。  
2. 加载：异步准备视频（可能包含一次切片）。  
3. 播放：就绪后淡入视频层。  
4. 结束：淡出视频层。  

性能策略（替代“零卡顿”绝对表述）：
* 目标为“**尽量无感切换**”。  
* 保留当前项和相邻项的播放器预热，避免每次播放后立刻销毁 Controller。

---

## 4. 平台差异化实施 (Platform Specifics)

### 4.1 Windows 端
* 使用 `dart:io` 访问文件系统。  
* 构建：`flutter build windows --release`。  
* 分发：打包 `build/windows/runner/Release` 为绿色版本。  
* 交互：滚轮切图、键盘左右切换。

### 4.2 Android 端（V1 = 侧载）
* **约束**：V1 仅要求侧载可用，不以 Play 审核通过为目标。  
* **权限方案**：申请 `MANAGE_EXTERNAL_STORAGE`，用于扫描和读取非媒体库目录中的实况文件。  
* **缓存方案**：临时 `.mp4` 存放于 `getExternalCacheDir()`，在退出/重扫时清理。  
* **后续（若上架 Play）**：需重构为更严格的 SAF/媒体库访问模式。

### 4.3 iOS 端（V1 = 文件导入）
* iOS 沙盒下，V1 不直接依赖照片库原始协议读取。  
* 开启 `UIFileSharingEnabled = YES`。  
* 开启 `LSSupportsOpeningDocumentsInPlace = YES`。  
* 用户通过 AirDrop/Finder 将文件导入 App 文档目录，App 仅扫描该目录。

---

## 5. 导出功能模块 (Export Features)
基于 `ffmpeg_kit_flutter` 实现异步导出，避免阻塞主界面。

1. **转 GIF (To GIF)**  
   - 参考：`-i input.mp4 -vf "fps=10,scale=480:-1:flags=lanczos" -loop 0 output.gif`  
   - 参数：FPS、尺寸可调。
2. **提取视频 (Extract Video)**  
   - iOS 双文件：复制 `.MOV`。  
   - Motion Photo：复制解析生成的 `.mp4` 到导出目录。  
3. **提取静图 (Extract Image)**  
   - 复制原始图片文件。

---

## 6. 开发阶段规划 (Development Roadmap)

### Phase 1: 协议验证核心 (V1 Core)
* 目标：先做无 UI 的 Dart 解析验证。  
* 范围：`IOSParser + MotionPhotoParser`。  
* 验收标准：
  1. V1 样本集识别成功率 >= 95%。  
  2. 提取视频可播放率 = 100%。  
  3. 同一批次重复解析无临时文件泄漏。  

### Phase 2: Windows MVP
* 搭建 Flutter Desktop 工程。  
* 实现目录选择、递归扫描、双层播放器。  
* 明确仅支持 V1 协议类型。

### Phase 3: 移动端落地
* Android：侧载权限流程与缓存回收。  
* iOS：文档目录导入与扫描流程。  
* 手势与交互一致性优化。

### Phase 4: 导出与产品化
* 集成 GIF/视频/静图导出。  
* 增加缓存治理、错误提示、日志。  
* UI 打磨与多语言支持。

### Phase 5: 协议扩展（非 V1）
* 新增并稳定 `Vivo/Huawei/OPPO` 解析器。  
* 建立样本回归测试集，持续提高覆盖率。

---

## 7. 质量门禁与发布检查 (Quality Gates)
* 一键门禁脚本：`powershell -ExecutionPolicy Bypass -File tool/test_matrix.ps1`
* 门禁与发布检查清单：`docs/testing/v1-gates.md`
* 样本统计命令：`$env:USERPROFILE\flutter-sdk\bin\dart.bat run bin/evaluate_v1_samples.dart sample`
* 失败报告命令：`$env:USERPROFILE\flutter-sdk\bin\dart.bat run bin/report_v1_failures.dart sample`
* Windows 云端构建：GitHub Actions `Windows Build`（`.github/workflows/windows-build.yml`）

### 7.1 如何手动触发 Windows 构建并下载产物
1. 打开 GitHub 仓库页面 → `Actions` → 选择 `Windows Build` workflow。
2. 点击 `Run workflow`，按需填写输入参数：
   - `sample_tag`：关联样本/任务编号（如 `T4-5`）。
   - `build_note`：补充本次构建说明（可选）。
3. 等待三个 Job 顺序完成：
   - `quality-check`：核心测试 + 静态检查摘要（静态检查为 early phase non-blocking，失败会写入 `GITHUB_STEP_SUMMARY` 并标注 :warning:）。
   - `build-windows`：仅在 `quality-check` 完成后执行 Windows Release 构建。
   - `publish-artifact`：生成并发布规范命名产物。
4. 在本次 run 的 `Artifacts` 区域下载产物，命名规则为：`ulpv-win-x64-{short_sha}-{date}`。
5. 对照 run 的 `Summary` 页面核验：
   - 是否存在 :warning:（表示 non-blocking 项失败）。
   - `sample_tag` / `build_note` 是否与本次任务一致。
   - 产物名中的 `short_sha` 与 run commit 是否对应。

## 8. 附录：关键协议特征 (Protocol Reference)
* **Xiaomi / Google (Motion Photo)**  
  - 关键标识：XMP 中 `MicroVideo` / `GCamera:MicroVideo`。  
  - 解析方式：读取 Offset 后二进制切片。

* **iOS (Live Photo)**  
  - 关键标识：`AssetIdentifier (UUID)`。  
  - 解析方式：配对同 UUID 的 `JPG/HEIC + MOV`。

* **Vivo / Huawei / OPPO（后续）**  
  - 关键标识：厂商私有尾部结构、MakerNote、专有 XMP。  
  - 解析方式：样本驱动逆向，逐步收敛稳定规则。
