# Rawtass VS Code Development Setup

This document provides step-by-step instructions for setting up the Rawtass development environment in VS Code from scratch.

## Prerequisites

### Required Software
1. **Xcode** (full version, not just Command Line Tools)
   - Install from Mac App Store or Apple Developer site
   - Required for Swift compilation and iOS/macOS development
   
2. **VS Code**
   - Download from [https://code.visualstudio.com/](https://code.visualstudio.com/)

3. **Git**
   - Usually comes with Xcode Command Line Tools
   - Verify: `git --version`

### System Requirements
- macOS 14.0+ (for SwiftUI and Apple Silicon optimizations)
- Apple Silicon Mac (recommended) or Intel Mac
- 8GB+ RAM, 10GB+ free disk space

## Quick Setup

### 1. Clone and Open Project
```bash
git clone https://github.com/rockphotog/rawtass.git
cd rawtass
code .
```

### 2. Install Recommended Extensions
When you open the project in VS Code, you'll see a notification to install recommended extensions. Click "Install All" or install manually:

**Essential Extensions:**
- `sswg.swift-lang` - Swift Language Support
- `vadimcn.vscode-lldb` - Native Debugger
- `eamodio.gitlens` - Git Integration
- `github.copilot` - AI Assistant (if you have access)

**Optional but Recommended:**
- `yzhang.markdown-all-in-one` - Markdown editing
- `timonwong.shellcheck` - Shell script validation
- `streetsidesoftware.code-spell-checker` - Spell checking

### 3. Verify Swift Installation
Open VS Code terminal (`Ctrl+``) and run:
```bash
swift --version
xcodebuild -version
```

### 4. Test Build System
Run the project validation and build:
```bash
# Validate project structure
./Scripts/validate_project.sh

# Build the project
./Scripts/build.sh
```

## VS Code Tasks (Command Palette: `Cmd+Shift+P`)

The project includes pre-configured tasks accessible via `Tasks: Run Task`:

- **Rawtass: Build Project** - Main build command with error detection
- **Rawtass: Validate Project** - Pre-build validation
- **Rawtass: Fix Build Errors** - Automatic error resolution
- **Rawtass: Clean Build Artifacts** - Clean build files
- **Rawtass: Open Xcode Project** - Open in Xcode for advanced debugging
- **Rawtass: Run Swift Syntax Check** - Quick syntax validation

## Development Workflow

### Daily Development
1. **Start with validation**: `Cmd+Shift+P` → "Tasks: Run Task" → "Rawtass: Validate Project"
2. **Make your changes** in VS Code with Swift intellisense
3. **Build and test**: Use "Rawtass: Build Project" task
4. **Fix errors automatically**: Use "Rawtass: Fix Build Errors" if needed
5. **Open in Xcode** when you need advanced debugging or iOS Simulator

### File Organization
```
Rawtass/
├── .vscode/                 # VS Code configuration (shared)
│   ├── settings.json        # Editor settings and Swift config
│   ├── extensions.json      # Recommended extensions
│   ├── tasks.json          # Build and development tasks
│   └── workspace.code-workspace  # Project workspace (gitignored)
├── Rawtass/                 # Swift source code
│   ├── App.swift           # Main app entry point
│   ├── ContentView.swift   # Main UI
│   ├── Views/              # SwiftUI views
│   └── RawProcessing/      # Raw image processing engine
├── Scripts/                 # Build automation
│   ├── build.sh            # Main build script
│   ├── validate_project.sh # Pre-build validation
│   └── error_resolver.sh   # Automatic error fixing
└── logs/                   # Build logs (gitignored)
```

## Keyboard Shortcuts

**VS Code + Swift Development:**
- `Cmd+Shift+P` - Command palette (access all tasks)
- `Cmd+Shift+B` - Quick build (runs default build task)
- `Cmd+T` - Go to file
- `Cmd+Shift+F` - Search in files
- `F12` - Go to definition
- `Shift+F12` - Find all references
- `Cmd+K Cmd+C` - Comment code
- `Cmd+/` - Toggle line comment

**Custom Tasks:**
- `Cmd+Shift+P` → "Tasks: Run Task" → Select task

## Debugging

### VS Code Debugging
1. Set breakpoints in Swift files (click in gutter)
2. Run "Debug Rawtass (Xcode)" configuration
3. Use VS Code debug console and variables panel

### Xcode Integration
For advanced debugging, UI preview, and iOS Simulator:
1. Run task "Rawtass: Open Xcode Project"
2. Use Xcode for SwiftUI previews and visual debugging
3. Return to VS Code for text editing and git operations

## Troubleshooting

### Swift Language Server Not Working
1. Check Xcode is properly installed: `xcode-select --print-path`
2. If showing Command Line Tools path: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Restart VS Code

### Build Errors
1. Run "Rawtass: Validate Project" to identify issues
2. Check build log in `logs/` directory
3. Use "Rawtass: Fix Build Errors" for automatic resolution
4. If persistent, clean build: "Rawtass: Clean Build Artifacts"

### Extensions Not Loading
1. Check internet connection
2. Restart VS Code
3. Manually install from Extensions panel (`Cmd+Shift+X`)

### Performance Issues
1. Exclude build directories in VS Code settings (already configured)
2. Close unused files/projects
3. Increase VS Code memory limit if needed

## Contributing

### Code Style
- 4 spaces for indentation (configured in settings.json)
- 100-character line limit (soft), 120 hard limit
- SwiftUI view builders for UI code
- Async/await for asynchronous operations

### Git Workflow
1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test with build tasks
3. Commit with meaningful messages
4. Push and create pull request

### File Changes
- Shared VS Code config files (.vscode/settings.json, extensions.json, tasks.json) are committed
- Workspace file (.vscode/workspace.code-workspace) is gitignored (may contain private settings)
- Build logs are gitignored

## Advanced Configuration

### Custom Settings
Create `.vscode/settings.json.local` for personal overrides (this file is gitignored).

### Additional Tasks
Add custom tasks to `.vscode/tasks.json` for project-specific workflows.

### Extensions
The project recommends essential extensions, but you can install additional ones based on your workflow.

---

## Quick Reference

**Start developing:**
```bash
git clone https://github.com/rockphotog/rawtass.git
cd rawtass
code .
# Install recommended extensions when prompted
# Cmd+Shift+P → "Tasks: Run Task" → "Rawtass: Build Project"
```

**Common commands:**
```bash
./Scripts/validate_project.sh  # Validate before building
./Scripts/build.sh            # Build with error detection  
open Rawtass.xcodeproj        # Open in Xcode
```

For questions or issues, refer to the main project README.md or create an issue in the repository.