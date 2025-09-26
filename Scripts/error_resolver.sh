#!/bin/bash

# Rawtass Error Detection and Resolution System
# Advanced error pattern matching and automatic fixes

# Error patterns and their solutions
declare -A ERROR_PATTERNS=(
    # Import/Framework errors
    ["No such module 'UniformTypeIdentifiers'"]="fix_uniform_type_identifiers"
    ["No such module"]="fix_missing_framework"
    
    # Swift compiler errors
    ["Use of unresolved identifier"]="fix_undefined_symbol"
    ["Cannot find type.*in scope"]="fix_missing_type"
    ["Value of type.*has no member"]="fix_missing_member"
    
    # SwiftUI specific errors
    ["Cannot convert value of type.*to expected argument type"]="fix_swiftui_type_mismatch"
    ["Initializer 'init' requires that.*conform to"]="fix_protocol_conformance"
    
    # Xcode project errors
    ["The project.*is damaged and cannot be opened"]="fix_project_corruption"
    ["Build input file cannot be found"]="fix_missing_build_file"
    
    # Entitlements errors
    ["Entitlements file.*not found"]="fix_missing_entitlements"
    ["Invalid entitlements"]="fix_invalid_entitlements"
    
    # Code signing errors
    ["Code Sign error"]="fix_code_signing"
    ["No signing certificate"]="fix_missing_certificate"
    
    # Deployment target errors
    ["Minimum deployment target"]="fix_deployment_target"
    ["is only available in.*or newer"]="fix_api_availability"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_fix_status() {
    echo -e "${BLUE}[FIX]${NC} $1"
}

print_fix_success() {
    echo -e "${GREEN}[FIXED]${NC} $1"
}

print_fix_warning() {
    echo -e "${YELLOW}[FIX-WARNING]${NC} $1"
}

print_fix_error() {
    echo -e "${RED}[FIX-ERROR]${NC} $1"
}

# Framework and import fixes
fix_uniform_type_identifiers() {
    print_fix_status "Fixing UniformTypeIdentifiers import issue..."
    
    # Check if we need to add the framework to project settings
    local project_file="Rawtass.xcodeproj/project.pbxproj"
    
    if ! grep -q "UniformTypeIdentifiers.framework" "$project_file"; then
        print_fix_warning "UniformTypeIdentifiers framework not linked in project"
        print_fix_status "Manual action required: Add UniformTypeIdentifiers framework in Xcode"
        return 1
    fi
    
    print_fix_success "UniformTypeIdentifiers framework is properly configured"
    return 0
}

fix_missing_framework() {
    local error_text="$1"
    print_fix_status "Analyzing missing framework error..."
    
    # Extract framework name from error
    local framework_name=$(echo "$error_text" | grep -o "No such module '[^']*'" | sed "s/No such module '//g" | sed "s/'//g")
    
    if [[ -n "$framework_name" ]]; then
        print_fix_warning "Missing framework: $framework_name"
        print_fix_status "Common solutions:"
        echo "  1. Add framework in Xcode: Project Settings > General > Frameworks, Libraries, and Embedded Content"
        echo "  2. Check import statement: import $framework_name"
        echo "  3. Verify framework availability on target macOS version"
    fi
    
    return 1  # Manual intervention required
}

# Swift code fixes
fix_undefined_symbol() {
    local error_text="$1"
    print_fix_status "Analyzing undefined symbol error..."
    
    # Extract symbol name
    local symbol=$(echo "$error_text" | grep -o "Use of unresolved identifier '[^']*'" | sed "s/Use of unresolved identifier '//g" | sed "s/'//g")
    
    if [[ -n "$symbol" ]]; then
        print_fix_warning "Undefined symbol: $symbol"
        print_fix_status "Checking for common typos and solutions..."
        
        # Check for common typos in our codebase
        case "$symbol" in
            "CGImage"|"CGSize"|"CGFloat")
                print_fix_status "CoreGraphics types require: import CoreGraphics"
                ;;
            "NSOpenPanel"|"NSWorkspace")
                print_fix_status "AppKit types require: import AppKit"
                ;;
            "URL"|"Data"|"FileManager")
                print_fix_status "Foundation types require: import Foundation"
                ;;
            *)
                print_fix_status "Check spelling and imports for: $symbol"
                ;;
        esac
    fi
    
    return 1
}

fix_missing_type() {
    local error_text="$1"
    print_fix_status "Analyzing missing type error..."
    
    # Look for common missing imports based on type names in our code
    if echo "$error_text" | grep -q "UTType"; then
        print_fix_status "UTType requires: import UniformTypeIdentifiers"
        return 0
    elif echo "$error_text" | grep -q "CI\|CG"; then
        print_fix_status "Core Image/Graphics types require: import CoreImage or import CoreGraphics"
        return 0
    fi
    
    return 1
}

fix_missing_member() {
    local error_text="$1"
    print_fix_status "Analyzing missing member error..."
    
    # Common SwiftUI fixes
    if echo "$error_text" | grep -q "View.*has no member"; then
        print_fix_warning "SwiftUI View member issue detected"
        print_fix_status "Check SwiftUI version compatibility and import SwiftUI"
    fi
    
    return 1
}

# SwiftUI specific fixes
fix_swiftui_type_mismatch() {
    local error_text="$1"
    print_fix_status "Analyzing SwiftUI type mismatch..."
    
    print_fix_status "Common SwiftUI type fixes:"
    echo "  1. Check @State, @Binding, @ObservedObject usage"
    echo "  2. Verify View protocol conformance"
    echo "  3. Check modifier order and types"
    
    return 1
}

fix_protocol_conformance() {
    local error_text="$1"
    print_fix_status "Analyzing protocol conformance error..."
    
    if echo "$error_text" | grep -q "Identifiable\|Hashable\|Equatable"; then
        print_fix_status "Common protocol conformance issue detected"
        print_fix_status "Add required protocol methods or use automatic synthesis"
    fi
    
    return 1
}

# Project file fixes
fix_project_corruption() {
    print_fix_status "Attempting to fix project corruption..."
    
    local project_file="Rawtass.xcodeproj/project.pbxproj"
    local backup_file="Rawtass.xcodeproj/project.pbxproj.backup_$(date +%s)"
    
    # Create backup
    cp "$project_file" "$backup_file"
    print_fix_status "Created backup: $backup_file"
    
    # Try to fix common pbxproj issues
    # Remove potential conflict markers
    if grep -q "<<<<<<< \|>>>>>>> \|=======" "$project_file"; then
        print_fix_status "Found merge conflict markers, attempting resolution..."
        sed -i '' '/<<<<<<< /d; />>>>>>> /d; /=======/d' "$project_file"
        print_fix_success "Removed merge conflict markers"
        return 0
    fi
    
    # Check for invalid characters
    if grep -q $'\r' "$project_file"; then
        print_fix_status "Found Windows line endings, converting to Unix..."
        sed -i '' 's/\r$//' "$project_file"
        print_fix_success "Converted line endings"
        return 0
    fi
    
    print_fix_warning "Could not automatically fix project corruption"
    print_fix_status "Manual recovery options:"
    echo "  1. Restore from backup: cp $backup_file $project_file"
    echo "  2. Recreate project file from Git history"
    
    return 1
}

fix_missing_build_file() {
    local error_text="$1"
    print_fix_status "Analyzing missing build file error..."
    
    # Extract file path from error
    local missing_file=$(echo "$error_text" | grep -o "file '[^']*'" | sed "s/file '//g" | sed "s/'//g")
    
    if [[ -n "$missing_file" ]]; then
        print_fix_warning "Missing build file: $missing_file"
        
        # Check if file exists but not in project
        local file_basename=$(basename "$missing_file")
        local found_files=$(find . -name "$file_basename" -type f 2>/dev/null)
        
        if [[ -n "$found_files" ]]; then
            print_fix_status "File exists but may not be added to project:"
            echo "$found_files"
            print_fix_status "Add to project in Xcode or check project.pbxproj"
        else
            print_fix_warning "File not found in project directory"
            print_fix_status "Create file or remove reference from project"
        fi
    fi
    
    return 1
}

# Entitlements fixes
fix_missing_entitlements() {
    print_fix_status "Fixing missing entitlements file..."
    
    local entitlements_file="Rawtass/Rawtass.entitlements"
    
    if [[ ! -f "$entitlements_file" ]]; then
        print_fix_status "Creating default entitlements file..."
        
        cat > "$entitlements_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
</dict>
</plist>
EOF
        
        print_fix_success "Created default entitlements file"
        return 0
    fi
    
    print_fix_success "Entitlements file already exists"
    return 0
}

fix_invalid_entitlements() {
    print_fix_status "Validating entitlements file..."
    
    local entitlements_file="Rawtass/Rawtass.entitlements"
    
    if [[ -f "$entitlements_file" ]]; then
        # Check XML validity
        if ! plutil -lint "$entitlements_file" >/dev/null 2>&1; then
            print_fix_warning "Invalid entitlements XML format"
            print_fix_status "Attempting to fix XML format..."
            
            # Try to reformat with plutil
            if plutil -convert xml1 "$entitlements_file" 2>/dev/null; then
                print_fix_success "Fixed entitlements XML format"
                return 0
            else
                print_fix_error "Could not fix entitlements format automatically"
                return 1
            fi
        fi
        
        print_fix_success "Entitlements file is valid"
        return 0
    fi
    
    # If file doesn't exist, create it
    fix_missing_entitlements
}

# Code signing fixes
fix_code_signing() {
    print_fix_status "Analyzing code signing issues..."
    
    print_fix_warning "Code signing issues detected"
    print_fix_status "Common solutions:"
    echo "  1. Set 'Automatically manage signing' in Xcode"
    echo "  2. Select valid development team"
    echo "  3. For debug builds, signing is often optional"
    echo "  4. Check keychain for valid certificates"
    
    return 1  # Manual intervention required
}

fix_missing_certificate() {
    print_fix_status "Checking available certificates..."
    
    # List available code signing identities
    local certificates=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID\|Mac Developer\|iPhone Developer" || echo "")
    
    if [[ -n "$certificates" ]]; then
        print_fix_success "Found code signing certificates:"
        echo "$certificates"
    else
        print_fix_warning "No code signing certificates found"
        print_fix_status "Solutions:"
        echo "  1. Enable 'Automatically manage signing' in Xcode"
        echo "  2. Download certificates from Apple Developer portal"
        echo "  3. Use ad-hoc signing for local development"
    fi
    
    return 1
}

# Deployment target fixes
fix_deployment_target() {
    local error_text="$1"
    print_fix_status "Analyzing deployment target issue..."
    
    # Extract version from error if possible
    if echo "$error_text" | grep -q "macOS"; then
        print_fix_status "macOS deployment target issue detected"
        print_fix_status "Check project settings: Deployment Target should match minimum macOS version"
        print_fix_status "Current project targets macOS 14.0+"
    fi
    
    return 1
}

fix_api_availability() {
    local error_text="$1"
    print_fix_status "Analyzing API availability issue..."
    
    # Extract API and version info
    local api_info=$(echo "$error_text" | grep -o "is only available in [^']*" | head -1)
    
    if [[ -n "$api_info" ]]; then
        print_fix_warning "API availability issue: $api_info"
        print_fix_status "Solutions:"
        echo "  1. Increase deployment target version"
        echo "  2. Add @available() checks in code"
        echo "  3. Use alternative APIs for older versions"
    fi
    
    return 1
}

# Main error detection and resolution function
analyze_and_fix_errors() {
    local error_log="$1"
    
    if [[ ! -f "$error_log" ]]; then
        print_fix_error "Error log not found: $error_log"
        return 1
    fi
    
    print_fix_status "Analyzing errors in: $error_log"
    
    local fixes_applied=0
    local fixes_attempted=0
    
    # Read through error log and match patterns
    while IFS= read -r line; do
        for pattern in "${!ERROR_PATTERNS[@]}"; do
            if echo "$line" | grep -q "$pattern"; then
                fixes_attempted=$((fixes_attempted + 1))
                print_fix_status "Matched error pattern: $pattern"
                
                # Call the appropriate fix function
                local fix_function="${ERROR_PATTERNS[$pattern]}"
                if declare -f "$fix_function" > /dev/null; then
                    if $fix_function "$line"; then
                        fixes_applied=$((fixes_applied + 1))
                    fi
                else
                    print_fix_error "Fix function not found: $fix_function"
                fi
                
                break  # Only match first pattern per line
            fi
        done
    done < "$error_log"
    
    echo ""
    print_fix_status "Error analysis complete:"
    echo "  - Errors analyzed: $(wc -l < "$error_log")"
    echo "  - Fix patterns matched: $fixes_attempted"
    echo "  - Automatic fixes applied: $fixes_applied"
    
    if [[ $fixes_applied -gt 0 ]]; then
        print_fix_success "Applied $fixes_applied automatic fixes"
        return 0
    else
        print_fix_warning "No automatic fixes could be applied"
        return 1
    fi
}

# Export functions for use by build script
export -f analyze_and_fix_errors
export -f fix_uniform_type_identifiers
export -f fix_missing_framework
export -f fix_project_corruption
export -f fix_missing_entitlements

# If script is run directly, analyze provided error log
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <error_log_file>"
        echo "Analyzes error log and attempts automatic fixes"
        exit 1
    fi
    
    analyze_and_fix_errors "$1"
fi