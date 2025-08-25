# xType - File Type Manager

### 🎯 概述

**xType** 是一款现代化、直观的 macOS 文件类型管理器，让您可以轻松管理和配置不同文件类型的默认应用程序。

### ✨ 功能特色

- **🎨 现代界面**：清爽的玻璃效果设计，遵循 macOS 设计原则
- **📁 文件类型管理**：查看和管理系统上所有注册的文件类型
- **⚡ 批量操作**：一次为多个文件类型设置默认应用程序
- **🔍 智能搜索**：通过名称或扩展名快速查找文件类型
- **🏷️ 分类筛选**：按音频、视频、图片、文本、压缩包等类别筛选
- **🌍 国际化支持**：完整支持英文和中文简体
- **🔄 实时更新**：即时刷新默认应用程序信息
- **💫 流畅动画**：通过流畅过渡提供愉悦的用户体验

### 📋 系统要求

- **macOS 12.0** 或更高版本
- **Apple Silicon** 或 **Intel** Mac
- **Xcode 15.0** 或更高版本（从源码构建时需要）

### 📦 安装方法

#### 方法一：下载发布版本（推荐）
1. 从 [Releases](https://github.com/helson-lin/xType/releases) 下载最新的 `.dmg` 文件
2. 打开 DMG 并将 **xType.app** 拖拽到 **应用程序** 文件夹
3. 从应用程序启动 xType 并授予必要权限

#### 方法二：从源码构建
```bash
# 克隆仓库
git clone https://github.com/helson-lin/xType.git
cd xType

# 本地构建
chmod +x scripts/build_local.sh
./scripts/build_local.sh

# 或创建 DMG
chmod +x scripts/create_dmg.sh
./scripts/create_dmg.sh
```

### 🚀 使用方法

1. **启动 xType** - 从应用程序文件夹启动
2. **浏览文件类型** - 查看所有注册的文件类型及其当前默认应用程序
3. **搜索和筛选** - 使用搜索栏或分类筛选器查找特定文件类型
4. **设置默认应用** - 点击"选择应用"来设置新的默认应用程序
5. **批量操作** - 使用"批量设置"一次配置多个文件类型
6. **刷新** - 点击刷新按钮更新默认应用程序信息

### 🔧 功能详解

#### 文件类型管理
- 查看所有系统文件类型的完整列表
- 显示每种文件类型的当前默认应用程序
- 文件类别的可视化指示器（音频、视频、图片等）
- 显示支持文件格式的扩展名标签

#### 批量操作
- 选择多个文件类型进行批量配置
- 按类别筛选以进行有针对性的批量操作
- 应用更改前预览选定项目
- 通过成功通知获得即时反馈

#### 智能界面
- 跨文件类型和扩展名的实时搜索
- 带有可视化图标的基于类别的筛选
- 具有流畅动画的现代玻璃效果设计
- 适应窗口大小的响应式布局

### 🌍 支持语言

- **English** (英文，默认)
- **中文简体**

界面语言自动跟随您的系统语言设置。

### 🛠️ 开发

#### 本地构建
```bash
# 安装依赖项（需要 Xcode）
xcode-select --install

# 克隆并构建
git clone https://github.com/helson-lin/xType.git
cd xType
./scripts/build_local.sh
```

#### CI/CD
本项目使用 GitHub Actions 进行自动化构建和发布：
- 标签推送时自动构建
- 使用自定义背景创建 DMG
- 支持 Intel 和 Apple Silicon
- 可选的代码签名和公证

详细构建说明请参见 [`BUILD_GUIDE.md`](BUILD_GUIDE.md)。

### 📄 许可证

本项目采用 MIT 许可证 - 详情请见 [LICENSE](LICENSE) 文件。

### 🤝 贡献

欢迎贡献！请随时提交 Pull Request。对于重大更改，请先开启 issue 讨论您想要更改的内容。

###  支持

- **问题反馈**：[GitHub Issues](https://github.com/helson-lin/xType/issues)
- **功能请求**：[GitHub Discussions](https://github.com/helson-lin/xType/discussions)
- **文档**：[构建指南](BUILD_GUIDE.md)

