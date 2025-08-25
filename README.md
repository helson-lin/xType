# xType - File Type Manager
<div align="center">

**Made with ❤️ for the macOS community**

[![GitHub stars](https://img.shields.io/github/stars/helson-lin/xType?style=social)](https://github.com/helson-lin/xType/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/helson-lin/xType?style=social)](https://github.com/helson-lin/xType/network)
[![GitHub license](https://img.shields.io/github/license/helson-lin/xType)](https://github.com/helson-lin/xType/blob/main/LICENSE)

<!-- Language Switch -->
[**🇺🇸 English**](#) | [**🇨🇳 中文**](./README-ZH.md)

---
</div>

### 🎯 Overview

**xType** is a modern, intuitive file type manager for macOS that allows you to easily manage and configure default applications for different file types.

### ✨ Features

- **🎨 Modern Interface**: Clean, glass-effect design that follows macOS design principles
- **📁 File Type Management**: View and manage all registered file types on your system
- **⚡ Batch Operations**: Set default applications for multiple file types at once
- **🔍 Smart Search**: Quickly find file types by name or extension
- **🏷️ Category Filtering**: Filter by audio, video, image, text, archive, and other categories
- **🌍 Internationalization**: Full support for English and Chinese (Simplified)
- **🔄 Real-time Updates**: Refresh default application information instantly
- **💫 Smooth Animations**: Delightful user experience with fluid transitions

### 📋 System Requirements

- **macOS 12.0** or later
- **Apple Silicon** or **Intel** Mac
- **Xcode 15.0** or later (for building from source)

### 📦 Installation

#### Option 1: Download Release (Recommended)
1. Download the latest `.dmg` file from [Releases](https://github.com/helson-lin/xType/releases)
2. Open the DMG and drag **xType.app** to your **Applications** folder
3. Launch xType from Applications and grant necessary permissions

#### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/helson-lin/xType.git
cd xType

# Build locally
chmod +x scripts/build_local.sh
./scripts/build_local.sh

# Or create DMG
chmod +x scripts/create_dmg.sh
./scripts/create_dmg.sh
```

### 🚀 Usage

1. **Launch xType** from your Applications folder
2. **Browse file types** - view all registered file types with their current default applications
3. **Search and filter** - use the search bar or category filters to find specific file types
4. **Set default apps** - click "Choose App" to set a new default application
5. **Batch operations** - use "Batch Setup" to configure multiple file types at once
6. **Refresh** - click the refresh button to update default application information

### 🔧 Features in Detail

#### File Type Management
- View comprehensive list of all system file types
- See current default applications for each file type
- Visual indicators for file categories (audio, video, image, etc.)
- Extension tags showing supported file formats

#### Batch Operations
- Select multiple file types for bulk configuration
- Filter by category for targeted batch operations
- Preview selected items before applying changes
- Instant feedback with success notifications

#### Smart Interface
- Real-time search across file types and extensions
- Category-based filtering with visual icons
- Modern glass effect design with smooth animations
- Responsive layout that adapts to window size

### 🌍 Supported Languages

- **English** (Default)
- **中文简体** (Chinese Simplified)

The interface language automatically follows your system language setting.

### 🛠️ Development

#### Building Locally
```bash
# Install dependencies (Xcode required)
xcode-select --install

# Clone and build
git clone https://github.com/helson-lin/xType.git
cd xType
./scripts/build_local.sh
```

#### CI/CD
This project uses GitHub Actions for automated building and release:
- Automatic builds on tag push
- DMG creation with custom background
- Support for both Intel and Apple Silicon
- Optional code signing and notarization

See [`BUILD_GUIDE.md`](BUILD_GUIDE.md) for detailed build instructions.

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Support

- **Issues**: [GitHub Issues](https://github.com/helson-lin/xType/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/helson-lin/xType/discussions)
- **Documentation**: [Build Guide](BUILD_GUIDE.md)
