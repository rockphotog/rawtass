#!/bin/bash

# Add FileBrowser.swift and ImageViewerPane.swift to Xcode project
# This script modifies the project.pbxproj file to include the new Swift files

PROJECT_FILE="/Users/espen/git/rawtass/Rawtass.xcodeproj/project.pbxproj"

# Generate unique UUIDs for the new files
FILEBROWSER_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)
FILEBROWSER_BUILD_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)
IMAGEVIEWER_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)
IMAGEVIEWER_BUILD_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)

echo "Adding FileBrowser.swift and ImageViewerPane.swift to Xcode project..."

# Create backup
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

# Add file references to PBXBuildFile section (after existing RawImageViewer line)
sed -i '' "/A1B2C3D4E5F6071829AB0015.*RawImageViewer.swift.*in Sources/a\\
		${FILEBROWSER_BUILD_UUID} /* FileBrowser.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${FILEBROWSER_FILE_UUID} /* FileBrowser.swift */; };\\
		${IMAGEVIEWER_BUILD_UUID} /* ImageViewerPane.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${IMAGEVIEWER_FILE_UUID} /* ImageViewerPane.swift */; };" "$PROJECT_FILE"

# Add file references to PBXFileReference section (after existing RawImageViewer line)
sed -i '' "/A1B2C3D4E5F6071829AB0016.*RawImageViewer.swift.*sourcecode.swift/a\\
		${FILEBROWSER_FILE_UUID} /* FileBrowser.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileBrowser.swift; sourceTree = \"<group>\"; };\\
		${IMAGEVIEWER_FILE_UUID} /* ImageViewerPane.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ImageViewerPane.swift; sourceTree = \"<group>\"; };" "$PROJECT_FILE"

# Add files to Views group (after existing RawImageViewer line)
sed -i '' "/A1B2C3D4E5F6071829AB0016.*RawImageViewer.swift/a\\
				${FILEBROWSER_FILE_UUID} /* FileBrowser.swift */,\\
				${IMAGEVIEWER_FILE_UUID} /* ImageViewerPane.swift */," "$PROJECT_FILE"

# Add files to Sources build phase (after existing RawImageViewer line)
sed -i '' "/A1B2C3D4E5F6071829AB0015.*RawImageViewer.swift.*in Sources/a\\
				${FILEBROWSER_BUILD_UUID} /* FileBrowser.swift in Sources */,\\
				${IMAGEVIEWER_BUILD_UUID} /* ImageViewerPane.swift in Sources */," "$PROJECT_FILE"

echo "✅ Successfully added new files to Xcode project!"
echo "FileBrowser.swift UUID: $FILEBROWSER_FILE_UUID"
echo "ImageViewerPane.swift UUID: $IMAGEVIEWER_FILE_UUID"