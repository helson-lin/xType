# DMG 自定义背景图片指南

## 🎨 当前配置

你的 DMG 现在使用 `scripts/background.png` 作为自定义背景图片：

- **图片尺寸**：660 x 400 像素
- **DMG 窗口尺寸**：760 x 500 像素（包含边距）
- **图标尺寸**：96 x 96 像素

## 📐 图标布局

当前的图标位置已针对你的背景图片进行了优化：

- **xType.app**：位置 (165, 180)
- **Applications**：位置 (495, 180) 
- **README.txt**：位置 (330, 320)

## 🔄 更换背景图片

### 1. 替换现有背景

只需将新的背景图片命名为 `background.png` 并放在 `scripts/` 目录中：

```bash
# 备份当前背景
mv scripts/background.png scripts/background_old.png

# 替换为新背景
cp /path/to/your/new/background.png scripts/background.png
```

### 2. 推荐的背景图片规格

**尺寸建议：**
- **最佳尺寸**：660 x 400 像素（与当前图标位置匹配）
- **最小尺寸**：600 x 350 像素
- **最大尺寸**：800 x 500 像素

**格式要求：**
- **格式**：PNG（推荐）或 JPEG
- **分辨率**：72-144 DPI
- **颜色空间**：RGB

### 3. 设计建议

**视觉效果：**
- 使用柔和的背景色，避免过于鲜艳的颜色
- 在图标放置区域保持相对简洁
- 考虑深浅对比，确保应用图标清晰可见

**图标放置区域：**
- **左侧区域**：(100-230, 120-240) - xType.app 图标区域
- **右侧区域**：(430-560, 120-240) - Applications 文件夹区域
- **底部中央**：(260-400, 280-360) - README.txt 区域

## 🛠️ 调整图标位置

如果你想调整图标位置以适配新的背景图片，编辑 `scripts/create_dmg.sh` 文件中的这部分：

```applescript
-- Position items to work well with the custom background
set position of item "$PRODUCT_NAME.app" of container window to {165, 180}
set position of item "Applications" of container window to {495, 180}
set position of item "README.txt" of container window to {330, 320}
```

**坐标系说明：**
- 原点 (0, 0) 在窗口左上角
- X 轴向右增加，Y 轴向下增加
- 坐标表示图标中心点位置

## 🎯 不同尺寸背景的调整

### 如果使用不同尺寸的背景图片

**1. 修改窗口大小**
```applescript
-- 根据背景图片尺寸调整
set the bounds of container window to {100, 100, [100+width], [100+height]}
```

**2. 重新计算图标位置**
- xType.app：通常在左侧 1/4 处
- Applications：通常在右侧 3/4 处  
- README：通常在底部中央

**示例计算：**
```
对于 800x450 的背景：
- xType.app: (200, 180)      # 800/4 = 200
- Applications: (600, 180)   # 800*3/4 = 600  
- README: (400, 350)         # 800/2 = 400
```

## ✨ 高级定制

### 添加更多文件到 DMG

在 `create_dmg.sh` 中的 "Create README file" 部分后添加：

```bash
# 添加其他文件
cp "path/to/your/file.txt" "$DMG_TEMP_DIR/"
```

然后在 AppleScript 中添加位置：

```applescript
set position of item "your-file.txt" of container window to {x, y}
```

### 动态背景选择

你可以修改脚本支持多个背景：

```bash
# 在脚本开头添加
BACKGROUND_NAME="${BACKGROUND_NAME:-background.png}"
BACKGROUND_SOURCE="scripts/$BACKGROUND_NAME"
```

使用时：
```bash
BACKGROUND_NAME="special_background.png" ./scripts/create_dmg.sh
```

## 🧪 测试背景效果

```bash
# 快速测试背景设置
./scripts/create_dmg.sh

# 检查生成的 DMG
open build/xType-*.dmg
```

## 🎨 背景图片创建工具推荐

- **Sketch**：专业设计工具
- **Figma**：免费的在线设计工具
- **Canva**：简单易用的设计平台
- **Preview**：macOS 自带，可做基本编辑
- **GIMP**：免费的图片编辑器

---

💡 **小贴士**：创建背景时，先在这些区域放置占位图标来确保布局效果！
