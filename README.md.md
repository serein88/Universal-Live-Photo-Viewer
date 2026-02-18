# 项目开发文档：Universal Live Photo Viewer (代号：ULPV)

## 1. 项目愿景与需求 (Project Vision)
**核心目标**：开发一款跨平台（Windows, Android, iOS）的本地实况图片查看器。
**解决痛点**：解决用户更换手机品牌后，由于厂商私有协议壁垒（iOS, 小米, 华为, Vivo, OPPO 等），导致原有的实况照片（Live Photos）变为普通静态图或无法播放的问题。
**产品形态**：
* **Windows**：绿色免安装软件（文件夹形式），解压即用。
* **Android/iOS**：原生 App 安装包。
* **核心体验**：三端 UI 高度一致，操作流畅，支持查看及格式转换导出。

---

## 2. 技术栈架构 (Tech Stack)

本项目采用 **Flutter** 作为唯一开发框架，利用 Dart 语言的强类型和二进制处理能力实现“一套代码，全端运行”。

| 模块分类           | 关键技术选型                    | 详细说明与选型理由                                                            |
| :------------- | :------------------------ | :------------------------------------------------------------------- |
| **开发语言**       | **Dart (v3.x+)**          | 必须使用。利用 `dart:io` 和 `dart:typed_data` 进行高性能二进制流读取和文件指针操作，解析私有协议。     |
| **UI 框架**      | **Flutter (v3.x+)**       | 保证 Windows 和移动端像素级 UI 一致性。Skia/Impeller 引擎渲染，性能优异。                   |
| **图片渲染**       | **extended_image**        | **核心库**。相比原生 Image 组件，它支持复杂的双指缩放、拖拽回弹、滑动切换，是相册类应用的基础。                |
| **视频播放**       | **video_player**          | **核心库**。官方插件，稳定。我们需要在此基础上封装透明层，实现“静图变动图”的效果。                         |
| **多媒体处理**      | **ffmpeg_kit_flutter**    | **核心库**。用于将私有格式转换为通用的 GIF、MP4 或提取静帧。它将 FFmpeg 二进制打包进 App。            |
| **元数据解析**      | **xml** / **exif**        | 用于解析 XMP (Extensible Metadata Platform) 数据，这是识别小米、Google 等安卓系实况图的关键。 |
| **文件选择**       | **file_picker**           | 用于跨平台调用系统文件选择器（选择文件夹或文件）。                                            |
| **状态管理**       | **Provider** (或 Riverpod) | 管理当前文件列表、选中索引 (Index)、播放器生命周期 (Controller) 的状态。                      |
| **Windows 定制** | **bitsdojo_window**       | 用于 Windows 端去除原生丑陋标题栏，自定义“最小化/关闭”按钮，实现现代化 UI。                        |

---

## 3. 核心系统架构 (System Architecture)

系统采用 **分层架构 (Layered Architecture)**，确保解析逻辑与 UI 展示解耦。

### 3.1 架构图示
`[UI Layer]` <-> `[State Management]` <-> `[Domain/Model]` <-> `[Data/Parsing Layer]`

### 3.2 数据层：通用解析引擎 (Parsing Engine)
**设计模式**：策略模式 (Strategy Pattern)。
针对不同厂商的存储协议，定义统一的解析接口，屏蔽底层差异。

* **抽象接口**：
    ```dart
    abstract class LivePhotoParser {
      /// 检查文件特征（后缀名、Magic Hex、XMP 标签）
      Future<bool> match(File file); 
      /// 解析文件，提取视频路径（如果是内嵌视频，则分离出临时文件）
      Future<LivePhotoEntity> parse(File file); 
    }
    ```

* **具体策略实现**：
    1.  **`IOSParser` (双文件流)**：
        * 逻辑：扫描目录，匹配同名 `IMG_xxxx.HEIC` + `IMG_xxxx.MOV`。
        * 特征：基于文件名匹配，或读取 `AssetIdentifier` UUID 匹配。
    2.  **`XiaomiParser` (内嵌流)**：
        * 逻辑：读取 JPG 的 XMP 元数据 -> 获取 `GCamera:MicroVideoOffset` -> 从文件末尾倒推截取视频流。
    3.  **`VivoParser` (内嵌流)**：
        * 逻辑：搜索文件尾部的私有 Hex 标记（通常包含 `vis_associ` 字段）或解析 Exif `MakerNote`。
    4.  **`HuaweiParser` (内嵌流)**：
        * 逻辑：解析 `ubiff` 结构或特定的 XMP 标签。

### 3.3 实体模型 (Domain Model)
UI 层统一使用的数据结构。

```dart
enum LivePhotoType { IOS, XIAOMI, VIVO, HUAWEI, MOTION_PHOTO, UNKNOWN }

class LivePhotoEntity {
  final String id;           // 文件唯一标识
  final String imagePath;    // 高清静态图路径（用于底层展示）
  final String? videoPath;   // 视频路径（可能是原文件，也可能是缓存的 temp.mp4）
  final LivePhotoType type;  // 实况类型
  
  // 核心方法：对象销毁时，如果视频是临时生成的，需要删除以释放空间
  Future<void> dispose() async {
    if (isTempFile(videoPath)) {
      await File(videoPath!).delete();
    }
  }
}
```

### 3.4 交互层：双层播放器 (Dual-Layer Player)

为了实现“无缝播放”和“零卡顿”体验。

- **Widget 结构 (Stack)**：
    
    - **Layer 1 (底层)**: `ExtendedImage`。始终显示，保证用户滑动时立刻看到图片。
        
    - **Layer 2 (顶层)**: `VideoPlayer`。初始化时 `Opacity: 0`。
        
- **播放逻辑**：
    
    1. **触发**：用户停止滑动（Page settled）或长按图片。
        
    2. **加载**：异步调用 `entity.videoPath`（此时可能涉及文件切割）。
        
    3. **播放**：VideoPlayer 准备就绪 -> `controller.play()` -> 将 Layer 2 透明度设为 1。
        
    4. **结束**：播放结束 -> 将 Layer 2 透明度设为 0（切回静态图） -> 释放 Controller。
        

---

## 4. 平台差异化实施 (Platform Specifics)

### 4.1 Windows 端

- **权限**：直接使用 `dart:io` 访问文件系统，无特殊限制。
    
- **分发**：使用 `flutter build windows --release`。
    
    - **绿色版制作**：构建后，将 `build/windows/runner/Release` 文件夹打包。用户解压后点击 `.exe` 即可运行，无需安装。
        
- **交互**：支持鼠标滚轮切换图片，键盘左右键切换。
    

### 4.2 Android 端

- **权限痛点**：Android 11+ (API 30+) 的“分区存储”。
    
    - **解决方案**：需申请 `MANAGE_EXTERNAL_STORAGE` 权限（允许管理所有文件），因为本应用不仅是看图，还需要读取非媒体库目录下的私有格式文件。
        
- **缓存管理**：解析内嵌视频生成的临时 `.mp4` 文件，必须存放在 `getExternalCacheDir()` 中，并在应用退出或列表刷新时清理，避免占用用户存储空间。
    

### 4.3 iOS 端

- **沙盒限制**：iOS 无法像 Android 那样直接扫描全盘文件，也无法直接读取“照片”App 的原始数据（系统会自动转码导致原始协议丢失）。
    
- **解决方案**：
    
    1. 开启 **iTunes File Sharing** (`UIFileSharingEnabled` = YES)。
        
    2. 开启 **Documents Support** (`LSSupportsOpeningDocumentsInPlace` = YES)。
        
    3. **使用流程**：用户通过 AirDrop 或 Finder 将存有实况图的文件夹放入 App 的“文档”目录下 -> App 扫描该目录。
        

---

## 5. 导出功能模块 (Export Features)

基于 `ffmpeg_kit_flutter` 实现，运行在独立 Isolate（隔离线程）中，避免阻塞 UI。

1. **转 GIF (To GIF)**：
    
    - 命令参考：`-i input.mp4 -vf "fps=10,scale=480:-1:flags=lanczos" -loop 0 output.gif`
        
    - 用户选项：可调节帧率 (FPS) 和 尺寸 (Scale)。
        
2. **提取视频 (Extract Video)**：
    
    - 对于 **iOS/双文件**：直接复制 `.MOV` 文件。
        
    - 对于 **小米/Vivo**：将解析出的临时 `.mp4` 文件复制到用户指定的导出目录。
        
3. **提取静图 (Extract Image)**：
    
    - 直接复制原始图片文件。
        

---

## 6. 开发阶段规划 (Development Roadmap)

### Phase 1: 协议破解与验证 (The Core)

- **目标**：不写 UI，只写 Dart 脚本。
    
- **任务**：
    
    1. 收集各品牌实况图样本。
        
    2. 编写 `LivePhotoParser` 类。
        
    3. 实现读取二进制流 -> 找到 Offset -> 切割并保存为 `.mp4`。
        
    4. **验证标准**：提取出的 MP4 能在电脑播放器正常播放。
        

### Phase 2: Windows 最小可行性产品 (Windows MVP)

- **目标**：一个能用的 Windows 文件夹查看器。
    
- **任务**：
    
    1. 搭建 Flutter Desktop 工程，配置 `bitsdojo_window`。
        
    2. 实现“选择文件夹” -> “递归扫描”逻辑。
        
    3. 实现 `Stack` 结构的播放器 UI。
        
    4. 实现自动播放逻辑。
        

### Phase 3: 移动端适配 (Mobile Adaptation)

- **目标**：适配 Android/iOS 权限与触控。
    
- **任务**：
    
    1. 处理 Android `MANAGE_EXTERNAL_STORAGE` 权限。
        
    2. 适配 iOS 文件共享目录扫描。
        
    3. 优化双指缩放体验 (`extended_image` 配置)。
        

### Phase 4: 导出与优化 (Export & Polish)

- **目标**：功能完善与发布。
    
- **任务**：
    
    1. 集成 FFmpeg 导出 GIF/视频。
        
    2. 添加缓存清理机制（自动删除过期的临时视频）。
        
    3. UI 美化与多语言支持。
        

---

## 7. 附录：关键协议特征 (Protocol Reference)

- **Xiaomi / Google (Motion Photo)**:
    
    - **关键标识**: XMP 元数据中的 `MicroVideo` 或 `GCamera:MicroVideo`。
        
    - **解析方式**: XML 解析获取 Offset 属性值。
        
- **Vivo**:
    
    - **关键标识**: 文件末尾的 Magic Hex（如 `vis_associ` 附近）。
        
    - **解析方式**: 二进制倒序搜索。
        
- **iOS (Live Photo)**:
    
    - **关键标识**: `AssetIdentifier` (UUID)。
        
    - **解析方式**: 匹配同目录下具有相同 UUID 的 JPG/HEIC 和 MOV 文件。

