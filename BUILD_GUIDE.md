# xType Build & Release Guide

本指南说明如何使用 GitHub Actions 自动构建和打包 xType 为 DMG 文件。

## 🚀 功能特性

- ✅ 自动构建 macOS 应用
- ✅ 创建美观的 DMG 安装包
- ✅ 支持 Intel 和 Apple Silicon 架构
- ✅ 可选代码签名和公证
- ✅ 自动发布到 GitHub Releases
- ✅ 本地构建脚本

## 📁 文件结构

```
.github/workflows/
├── build-release.yml      # 主要构建工作流（无签名）
└── build-signed.yml       # 签名构建工作流（可选）

scripts/
├── ExportOptions.plist    # Xcode 导出配置
├── create_dmg.sh         # DMG 创建脚本
└── build_local.sh        # 本地构建脚本
```

## 🔧 工作流说明

### 1. 基础构建工作流 (`build-release.yml`)

**触发条件：**
- 推送标签（如 `v1.0.0`）
- Pull Request 到 main 分支
- 手动触发

**功能：**
- 构建应用程序
- 创建 DMG 文件
- 上传构建产物
- 发布到 GitHub Releases（仅标签触发时）

### 2. 签名构建工作流 (`build-signed.yml`)

**触发条件：**
- 推送标签
- 手动触发

**额外功能：**
- 代码签名
- 应用公证（可选）
- DMG 签名

## 🛠️ 使用方法

### 快速开始（无签名）

1. **推送代码到 GitHub**
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

2. **创建版本标签**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **自动构建**
   - GitHub Actions 会自动开始构建
   - 完成后会创建 GitHub Release
   - DMG 文件会作为 Release 资产上传

### 本地构建和测试

```bash
# 构建应用
chmod +x scripts/build_local.sh
./scripts/build_local.sh

# 仅创建 DMG
chmod +x scripts/create_dmg.sh
./scripts/create_dmg.sh
```

## 🔐 代码签名配置（可选）

如果你有 Apple Developer 账户，可以配置代码签名：

### 1. 准备证书和配置文件

1. 在 Apple Developer 中心创建证书和 Provisioning Profile
2. 导出 .p12 证书文件
3. 下载 Provisioning Profile

### 2. 配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

| Secret 名称 | 描述 |
|------------|------|
| `BUILD_CERTIFICATE_BASE64` | .p12 证书文件的 base64 编码 |
| `P12_PASSWORD` | .p12 证书密码 |
| `PROVISIONING_PROFILE_BASE64` | Provisioning Profile 的 base64 编码 |
| `TEAM_ID` | Apple Developer Team ID |
| `CODE_SIGN_IDENTITY` | 代码签名身份 |
| `PROVISIONING_PROFILE_NAME` | Provisioning Profile 名称 |
| `NOTARIZATION_USERNAME` | Apple ID（用于公证）|
| `NOTARIZATION_PASSWORD` | App-specific 密码 |

### 3. 获取 base64 编码

```bash
# 编码证书文件
base64 -i certificate.p12 -o certificate.txt

# 编码 Provisioning Profile
base64 -i profile.mobileprovision -o profile.txt
```

## 📦 DMG 特性

创建的 DMG 文件包含：

- ✨ 美观的窗口布局
- 🔗 Applications 文件夹快捷方式
- 📄 README 说明文件
- 🎨 **自定义背景图片**（`scripts/background.png`）
- 📏 优化的窗口尺寸（760x500）和图标位置
- 🖼️ 针对 660x400 背景图片的布局优化

## 🏗️ 架构支持

- **Intel (x86_64)**：兼容 Intel Mac
- **Apple Silicon (arm64)**：优化的 M1/M2/M3 Mac 支持  
- **Universal Binary**：同时支持两种架构

## 🎨 自定义 DMG 背景

### 使用自定义背景图片

你的 DMG 使用 `scripts/background.png` 作为背景：

```bash
# 查看当前背景信息
sips -g pixelWidth -g pixelHeight scripts/background.png

# 替换背景图片
cp /path/to/new/background.png scripts/background.png
```

### 背景图片要求

- **推荐尺寸**：660 x 400 像素
- **格式**：PNG 或 JPEG
- **设计建议**：在图标放置区域保持简洁

### 图标布局

当前布局针对你的背景优化：
- **xType.app**：左侧区域 (165, 180)
- **Applications**：右侧区域 (495, 180)
- **README.txt**：底部中央 (330, 320)

详细指南请参考：`scripts/DMG_BACKGROUND_GUIDE.md`

## 🧪 测试构建

### 在 Pull Request 中测试

1. 创建 PR 到 main 分支
2. GitHub Actions 会自动构建
3. 检查 Actions 页面查看构建状态
4. 下载 Artifacts 进行测试

### 手动触发构建

1. 访问 GitHub Actions 页面
2. 选择工作流
3. 点击 "Run workflow"
4. 选择分支并运行

## 📋 发布检查清单

在发布新版本之前：

- [ ] 更新版本号（在 Xcode 项目中）
- [ ] 更新 CHANGELOG 或 Release Notes
- [ ] 测试应用功能
- [ ] 确认本地化正常工作
- [ ] 运行本地构建测试
- [ ] 创建版本标签
- [ ] 验证 GitHub Release

## 🛠️ 故障排除

### 常见问题

**构建失败：**
1. 检查 Xcode 版本兼容性
2. 确认 scheme 和配置名称正确
3. 查看 GitHub Actions 日志

**DMG 创建失败：**
1. 检查应用是否成功构建
2. 确认脚本有执行权限
3. 查看 DMG 脚本输出

**代码签名问题：**
1. 验证 Secrets 配置正确
2. 检查证书是否过期
3. 确认 Bundle ID 匹配

### 调试技巧

```bash
# 查看构建产物
ls -la build/

# 检查应用信息
plutil -p build/export/xType.app/Contents/Info.plist

# 验证签名
codesign -dv --verbose=4 build/export/xType.app

# 测试 DMG 挂载
hdiutil attach build/xType-*.dmg
```

## 🔄 版本管理

建议的版本号格式：
- `v1.0.0` - 主要版本
- `v1.0.1` - 补丁版本
- `v1.1.0` - 功能版本
- `v2.0.0-beta.1` - 预发布版本

## 📚 更多资源

- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

🎉 **恭喜！** 现在你可以使用 GitHub Actions 自动构建和发布 xType 了！
