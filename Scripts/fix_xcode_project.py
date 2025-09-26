#!/usr/bin/env python3
"""
Add missing Swift files to Xcode project
This script adds FileBrowser.swift and ImageViewerPane.swift to the Xcode project
"""
import uuid
import re
import sys

def generate_uuid():
    """Generate a 24-character UUID for Xcode"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_files_to_xcode_project():
    project_file = "/Users/espen/git/rawtass/Rawtass.xcodeproj/project.pbxproj"
    
    # Generate UUIDs for new files
    file_browser_file_id = generate_uuid()
    file_browser_build_id = generate_uuid()
    image_viewer_file_id = generate_uuid()
    image_viewer_build_id = generate_uuid()
    
    print(f"Adding files to Xcode project...")
    print(f"FileBrowser.swift - File ID: {file_browser_file_id}, Build ID: {file_browser_build_id}")
    print(f"ImageViewerPane.swift - File ID: {image_viewer_file_id}, Build ID: {image_viewer_build_id}")
    
    # Read the project file
    try:
        with open(project_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {project_file}")
        return False
    
    # Create backup
    with open(f"{project_file}.backup", 'w') as f:
        f.write(content)
    
    # Add build file entries
    build_files_pattern = r'(A1B2C3D4E5F6071829AB0015 /\* RawImageViewer\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = A1B2C3D4E5F6071829AB0016 /\* RawImageViewer\.swift \*/; \};)'
    build_files_replacement = f'''\\1
		{file_browser_build_id} /* FileBrowser.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_browser_file_id} /* FileBrowser.swift */; }};
		{image_viewer_build_id} /* ImageViewerPane.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {image_viewer_file_id} /* ImageViewerPane.swift */; }};'''
    
    content = re.sub(build_files_pattern, build_files_replacement, content)
    
    # Add file reference entries
    file_refs_pattern = r'(A1B2C3D4E5F6071829AB0016 /\* RawImageViewer\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = RawImageViewer\.swift; sourceTree = "<group>"; \};)'
    file_refs_replacement = f'''\\1
		{file_browser_file_id} /* FileBrowser.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileBrowser.swift; sourceTree = "<group>"; }};
		{image_viewer_file_id} /* ImageViewerPane.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ImageViewerPane.swift; sourceTree = "<group>"; }};'''
    
    content = re.sub(file_refs_pattern, file_refs_replacement, content)
    
    # Add files to Views group
    views_group_pattern = r'(A1B2C3D4E5F6071829AB0016 /\* RawImageViewer\.swift \*/,)'
    views_group_replacement = f'''\\1
				{file_browser_file_id} /* FileBrowser.swift */,
				{image_viewer_file_id} /* ImageViewerPane.swift */,'''
    
    content = re.sub(views_group_pattern, views_group_replacement, content)
    
    # Add files to Sources build phase
    sources_pattern = r'(A1B2C3D4E5F6071829AB0015 /\* RawImageViewer\.swift in Sources \*/,)'
    sources_replacement = f'''\\1
				{file_browser_build_id} /* FileBrowser.swift in Sources */,
				{image_viewer_build_id} /* ImageViewerPane.swift in Sources */,'''
    
    content = re.sub(sources_pattern, sources_replacement, content)
    
    # Write the modified content back
    try:
        with open(project_file, 'w') as f:
            f.write(content)
        print("✅ Successfully added files to Xcode project!")
        return True
    except Exception as e:
        print(f"❌ Error writing to project file: {e}")
        return False

if __name__ == "__main__":
    success = add_files_to_xcode_project()
    sys.exit(0 if success else 1)