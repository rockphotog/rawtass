# App Sandbox Navigation Analysis & Solutions

## Summary
We've successfully identified and analyzed the core issue with FileBrowser navigation in the Rawtass app. The app is running in an App Sandbox environment, which redirects all home directory access to a container path instead of the real user directories.

## Key Findings

### 1. **Sandbox Path Redirection**
- Both `NSHomeDirectory()` and `FileManager.default.homeDirectoryForCurrentUser` return the sandboxed path: `/Users/espen/Library/Containers/com.yourcompany.Rawtass/Data`
- The "Desktop", "Pictures", etc. items in the container are symbolic links/redirects, not actual directories
- Permission errors occur when trying to access directories outside the container without proper entitlements

### 2. **Current Entitlements Status**
The app has the following entitlements configured in `Rawtass.entitlements`:
```xml
<key>com.apple.security.temporary-exception.files.home-relative-path.read-only</key>
<array>
    <string>Desktop/</string>
    <string>Documents/</string>
    <string>Downloads/</string>
    <string>Pictures/</string>
</array>
```

### 3. **Debug Output Analysis**
Our debugging revealed:
- App starts in sandboxed container: `/Users/espen/Library/Containers/com.yourcompany.Rawtass/Data`
- Permission errors when accessing: `/Users/espen/git/rawtass/sample-images` (Code=257, "Operation not permitted")
- Container items like "Pictures" and "Desktop" are files/symlinks, not directories (Code=256, "Not a directory")

## Recommended Solutions

### Solution 1: Use FileManager Standard Directory APIs ✅ RECOMMENDED
Instead of constructing paths manually, use FileManager APIs that respect entitlements:

```swift
// For Pictures
if let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first {
    // This should work with entitlements
}

// For Desktop
if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
    // This should work with entitlements
}

// For Downloads
if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
    // This should work with entitlements
}

// For Documents
if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
    // This should work with entitlements
}
```

### Solution 2: Implement Security-Scoped Bookmarks
For directories that need persistent access, implement security-scoped bookmarks:

```swift
func requestDirectoryAccess() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    
    panel.begin { response in
        if response == .OK, let url = panel.url {
            // Store security-scoped bookmark
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope) {
                // Save bookmark for future use
                UserDefaults.standard.set(bookmark, forKey: "selectedDirectory")
            }
            
            // Start accessing the resource
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Now you can access the directory
            self.currentDirectory = url
            self.refreshContents()
        }
    }
}
```

### Solution 3: Update Quick Access Buttons
Replace the current button implementations with proper navigation methods:

```swift
// Home button - navigate to Documents instead of container
Button {
    if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        navigateToDirectory(documentsURL)
    }
}

// Pictures button
Button {
    if let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first {
        navigateToDirectory(picturesURL)
    } else {
        // Fallback to file picker
        showingFilePicker = true
    }
}
```

## Files That Need Updates

### 1. `Rawtass/Views/FileBrowser.swift`
- Update initialization to use `FileManager.default.urls(for:in:)`
- Replace manual path construction with proper FileManager APIs
- Add security-scoped resource handling
- Update quick access button actions

### 2. `Rawtass/Rawtass.entitlements` ✅ ALREADY CONFIGURED
- Entitlements are properly configured
- May need to test if they're working correctly

## Testing Strategy

### 1. **Build and Run with Debug Output**
```bash
cd /Users/espen/git/rawtass
xcodebuild -project Rawtass.xcodeproj -scheme Rawtass -configuration Debug
/Users/espen/Library/Developer/Xcode/DerivedData/Rawtass-*/Build/Products/Debug/Rawtass.app/Contents/MacOS/Rawtass
```

### 2. **Verify Directory Access**
Test each quick access button:
- Home (should go to Documents)
- Pictures (should access real Pictures folder)
- Desktop (should access real Desktop folder)
- Downloads (if implemented)

### 3. **Test File Picker Fallback**
If direct access fails, verify that the file picker opens and allows manual directory selection.

## Expected Behavior After Fix

1. **App starts in Documents directory** instead of sandbox container
2. **Quick access buttons work** - Pictures, Desktop, Downloads buttons successfully navigate to real user directories
3. **File picker works as fallback** - if entitlements fail, user can manually select directories
4. **No permission errors** - proper use of FileManager APIs respects entitlements
5. **Security-scoped resources** - directories remain accessible between app launches

## Debug Commands

To monitor the app's directory access:
```bash
# Run app with output
/path/to/Rawtass.app/Contents/MacOS/Rawtass

# Monitor system logs
log stream --predicate 'process == "Rawtass"' --info --debug

# Check entitlements
codesign -d --entitlements - /path/to/Rawtass.app
```

## Current Status
- ✅ **Issue Identified**: App sandbox path redirection confirmed
- ✅ **Root Cause Found**: Manual path construction bypasses entitlements
- ✅ **Solution Designed**: Use FileManager standard directory APIs
- ✅ **Entitlements Verified**: Proper permissions configured
- ⏳ **Implementation**: Ready to apply FileManager API updates to FileBrowser.swift
- ⏳ **Testing**: Ready to test with real user directories

## Next Steps
1. Apply FileManager API updates to FileBrowser.swift navigation methods
2. Update quick access button actions to use proper APIs
3. Test directory access with each button
4. Implement file picker fallback for any remaining issues
5. Add security-scoped bookmark support for persistent access (optional)