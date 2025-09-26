# 🔧 Fixed: File Access Issue in Rawtass

## Problem Diagnosis
The files were appearing greyed out because of **macOS App Sandbox** restrictions. Even though the `Rawtass.entitlements` file didn't explicitly enable the sandbox, Xcode was automatically applying sandbox entitlements during debug builds.

## Root Cause
```
Sandbox Entitlements (automatically applied by Xcode):
{
  "com.apple.security.app-sandbox" = 1;
  "com.apple.security.assets.pictures.read-only" = 1;
  "com.apple.security.files.user-selected.read-only" = 1;
  "com.apple.security.files.downloads.read-only" = 1;
  "com.apple.security.files.bookmarks.app-scope" = 1;
}
```

This means the app can only access:
1. **Pictures folder** (read-only)
2. **Downloads folder** (read-only)  
3. **Files explicitly selected by the user** via file picker

## Solution Implemented

### 1. Smart Default Directory
- App now starts in the **Pictures directory** by default (has sandbox access)
- Fallback to home directory if Pictures folder is not accessible

### 2. User-Friendly UI
- Added helpful messages when no images are found
- Clear instructions on how to access images:
  - Use folder button to select a directory
  - Navigate to Pictures folder
- "Open Pictures Folder" button for quick access

### 3. Sandbox-Aware File Access
- File picker integration for user-selected directories
- Proper security-scoped resource access for dropped files
- Clear visual feedback for accessible vs. restricted files

## How to Use the App Now

### For Users:
1. **Launch the app** - it will start in your Pictures folder
2. **To access other folders:**
   - Click the 📁 folder button in the toolbar
   - Select any folder with images
   - The app will remember this choice
3. **Drag & drop images** directly onto the app
4. **Navigate using the breadcrumb path** at the top

### For Development:
The app works correctly within sandbox constraints. For production release, you have two options:

#### Option A: Keep Sandbox (App Store compatible)
- Current implementation works
- Users need to explicitly select folders
- App Store compliant

#### Option B: Disable Sandbox (Direct distribution only)
```xml
<!-- Remove from entitlements for unrestricted file access -->
<key>com.apple.security.app-sandbox</key>
<false/>
```

## Files Modified
- `FileBrowser.swift`: Added smart defaults, helpful UI, sandbox-aware behavior
- `Rawtass.entitlements`: Configured for development with JIT support
- Debug output added to track file selection issues

## Testing Results
✅ App launches successfully  
✅ Pictures folder accessible by default  
✅ File picker works for other directories  
✅ Clear user guidance when no images found  
✅ Build system works correctly  

The app is now **fully functional** within macOS security constraints! 🎉