#!/bin/bash

# Rawtass VS Code Development Environment Setup Script
# Run this script after cloning the repository to set up your development environment

set -e

echo "🚀 Setting up Rawtass development environment in VS Code..."
echo

# Check if we're in the right directory
if [[ ! -f "Rawtass.xcodeproj/project.pbxproj" ]]; then
    echo "❌ Error: Please run this script from the Rawtass project root directory"
    echo "   Expected to find: Rawtass.xcodeproj/project.pbxproj"
    exit 1
fi

echo "📋 Checking prerequisites..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the Mac App Store."
    echo "   After installation, run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
else
    echo "✅ Xcode found: $(xcodebuild -version | head -n1)"
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift compiler not found. Please ensure Xcode is properly installed."
    exit 1
else
    echo "✅ Swift found: $(swift --version | head -n1)"
fi

# Check for Git
if ! command -v git &> /dev/null; then
    echo "❌ Git not found. Please install Git or Xcode Command Line Tools."
    exit 1
else
    echo "✅ Git found: $(git --version)"
fi

# Check for VS Code
if ! command -v code &> /dev/null; then
    echo "⚠️  VS Code 'code' command not found in PATH."
    echo "   Install VS Code and enable 'Shell Command: Install code command in PATH'"
    echo "   Or manually open the project: open -a 'Visual Studio Code' ."
else
    echo "✅ VS Code CLI found"
fi

echo

# Create logs directory if it doesn't exist
if [[ ! -d "logs" ]]; then
    echo "📁 Creating logs directory..."
    mkdir -p logs
    echo "✅ Created logs/ directory for build reports"
fi

# Make scripts executable
echo "🔧 Setting up build scripts..."
chmod +x Scripts/*.sh
echo "✅ Made build scripts executable"

# Run project validation
echo
echo "🔍 Running project validation..."
if ./Scripts/validate_project.sh; then
    echo "✅ Project validation passed"
else
    echo "⚠️  Project validation found issues (this is normal for initial setup)"
    echo "   These will be resolved during the first build"
fi

# Test build system
echo
echo "🔨 Testing build system..."
if ./Scripts/build.sh; then
    echo "✅ Build system test passed"
else
    echo "⚠️  Build test found issues. This is expected if Xcode isn't fully configured."
    echo "   Open the project in Xcode to complete setup: open Rawtass.xcodeproj"
fi

echo
echo "📖 Next Steps:"
echo "1. Open the project in VS Code:"
if command -v code &> /dev/null; then
    echo "   code ."
else
    echo "   Open VS Code and use File > Open Folder > Select this directory"
fi

echo "2. Install recommended extensions when prompted"
echo "3. Read the setup guide: .vscode/README.md"
echo "4. Run tasks via Cmd+Shift+P > 'Tasks: Run Task'"
echo
echo "🎉 Setup complete! Happy coding!"
echo
echo "💡 Tip: For advanced debugging and SwiftUI previews, also open: open Rawtass.xcodeproj"