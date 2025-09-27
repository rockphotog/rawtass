# Rawtass

A little different. (Because it's not working ATM).

## Status

Under development

## Description

Rawtass is a native macOS application built with Swift and SwiftUI, optimized for Apple Silicon Macs.

## Development plan

Make a fast image viewer for (compressed) raw images, especially the compressed raw formats for Nikon Z (HE/HE* formats) and Fujifilm X camera/sensors, which is not supported by native MacOS. The app should work as a Finder extension.

The Nikon HE/HE* compressed raw formats are patented and specifications is not easily available per now. 

## Development Environment Setup

### Prerequisites

- **Xcode 15.0 or later** - Required for Swift 5.9+ and macOS 14.0+ support
- **macOS 14.0 (Sonoma) or later** - For development and testing
- **Apple Silicon Mac** (M1/M2/M3) - Recommended for optimal performance

### Getting Started

#### Option 1: Xcode Development (Recommended for beginners)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/rockphotog/rawtass.git
   cd rawtass
   ```

2. **Open in Xcode:**
   ```bash
   open Rawtass.xcodeproj
   ```
   
   Or double-click the `Rawtass.xcodeproj` file in Finder.

3. **Build and Run:**
   - Select the "Rawtass" scheme in Xcode
   - Choose your target device (Mac)
   - Press `⌘+R` to build and run

#### Option 2: VS Code Development (Advanced)

For developers who prefer VS Code with automated build tools:

1. **Quick setup:**
   ```bash
   git clone https://github.com/rockphotog/rawtass.git
   cd rawtass
   ./setup-vscode.sh
   code .
   ```

2. **Manual setup:**
   - Install recommended extensions when prompted
   - Use `Cmd+Shift+P` → "Tasks: Run Task" for build operations
   - See detailed guide: [.vscode/README.md](.vscode/README.md)

**VS Code Features:**
- Automated build system with error detection
- Pre-build validation and error resolution
- Integrated Swift syntax checking
- Custom tasks for common operations
- Git integration and debugging support

### Project Structure

```
Rawtass/
├── Rawtass.xcodeproj/          # Xcode project file
├── Rawtass/                    # Source code
│   ├── App.swift              # Main app entry point
│   ├── ContentView.swift      # Main UI view
│   ├── Assets.xcassets/       # App icons and assets
│   ├── Rawtass.entitlements   # App capabilities
│   └── Preview Content/       # SwiftUI preview assets
├── README.md                  # This file
└── .gitignore                # Git ignore rules
```

### Architecture & Technologies

- **SwiftUI** - Modern declarative UI framework
- **Swift 5.9+** - Latest Swift language features
- **macOS 14.0+** - Modern macOS APIs and features
- **Apple Silicon Optimized** - Built specifically for M-series processors

### Build Configuration

The project is configured with:
- **Deployment Target:** macOS 14.0
- **Swift Version:** 5.0
- **Architecture:** Apple Silicon native (arm64)
- **App Sandbox:** Enabled for security
- **Hardened Runtime:** Enabled

### Development Guidelines

1. **Code Style:**
   - Follow Swift API Design Guidelines
   - Use SwiftUI best practices
   - Prefer declarative over imperative patterns

2. **Git Workflow:**
   - Create feature branches for new work
   - Use descriptive commit messages
   - Keep commits atomic and focused

3. **Testing:**
   - Write unit tests for business logic
   - Use SwiftUI previews for UI testing
   - Test on multiple screen sizes

### Troubleshooting

**Build Issues:**
- Ensure you're using Xcode 15.0 or later
- Clean build folder: `⌘+Shift+K`
- Reset Package Caches if using SPM

**Runtime Issues:**
- Check console logs in Xcode
- Verify entitlements for required permissions
- Ensure deployment target matches your macOS version

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is under development. License information will be added when ready for public release.
