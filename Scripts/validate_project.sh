#!/bin/bash

# Rawtass Project Validator
# Comprehensive pre-build validation system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_validator_status() {
    echo -e "${BLUE}[VALIDATOR]${NC} $1"
}

print_validator_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_validator_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_validator_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_validator_header() {
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE} Rawtass Project Validator${NC}"
    echo -e "${PURPLE}======================================${NC}"
}

# Validate Xcode project structure
validate_xcode_project() {
    print_validator_status "Validating Xcode project structure..."
    
    local project_file="Rawtass.xcodeproj/project.pbxproj"
    local validation_errors=0
    
    # Check if project file exists
    if [[ ! -f "$project_file" ]]; then
        print_validator_error "Project file not found: $project_file"
        return 1
    fi
    
    # Validate project file format
    if ! grep -q "// !.*UTF8.*!" "$project_file"; then
        print_validator_error "Invalid project file format (missing UTF8 header)"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check for required sections
    local required_sections=(
        "PBXBuildFile"
        "PBXFileReference"
        "PBXGroup"
        "PBXNativeTarget"
        "PBXProject"
        "PBXSourcesBuildPhase"
        "XCBuildConfiguration"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "Begin $section section" "$project_file"; then
            print_validator_error "Missing required section: $section"
            validation_errors=$((validation_errors + 1))
        fi
    done
    
    # Check for duplicate UUIDs (common corruption issue)
    local duplicate_uuids=$(grep -o '[A-F0-9]\{24\}' "$project_file" | sort | uniq -d | wc -l)
    if [[ $duplicate_uuids -gt 0 ]]; then
        print_validator_warning "Found $duplicate_uuids duplicate UUIDs in project file"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [[ $validation_errors -eq 0 ]]; then
        print_validator_success "Xcode project structure is valid"
        return 0
    else
        print_validator_error "Xcode project validation failed ($validation_errors issues)"
        return 1
    fi
}

# Validate source code files
validate_source_files() {
    print_validator_status "Validating Swift source files..."
    
    local source_errors=0
    local swift_files=$(find Rawtass -name "*.swift" -type f)
    
    if [[ -z "$swift_files" ]]; then
        print_validator_error "No Swift source files found"
        return 1
    fi
    
    # Validate each Swift file
    for file in $swift_files; do
        # Check file readability
        if [[ ! -r "$file" ]]; then
            print_validator_error "Cannot read file: $file"
            source_errors=$((source_errors + 1))
            continue
        fi
        
        # Check for basic Swift syntax (imports, basic structure)
        if ! grep -q "^import " "$file" && ! grep -q "^//\|^@\|^struct\|^class\|^enum\|^protocol\|^extension" "$file"; then
            print_validator_warning "File may not be valid Swift: $file"
            source_errors=$((source_errors + 1))
        fi
        
        # Check for common encoding issues
        if file -b "$file" | grep -q "Non-ISO extended-ASCII"; then
            print_validator_warning "File contains non-ASCII characters: $file"
        fi
        
        # Check for Windows line endings
        if grep -q $'\r' "$file"; then
            print_validator_warning "File contains Windows line endings: $file"
        fi
        
        # Check for merge conflict markers
        if grep -q "<<<<<<< \|>>>>>>> \|=======" "$file"; then
            print_validator_error "File contains unresolved merge conflicts: $file"
            source_errors=$((source_errors + 1))
        fi
        
        # Basic syntax validation (if swift command is available)
        if command -v swift >/dev/null 2>&1; then
            if ! swift -parse "$file" >/dev/null 2>&1; then
                print_validator_error "Swift syntax error in: $file"
                source_errors=$((source_errors + 1))
            fi
        fi
    done
    
    if [[ $source_errors -eq 0 ]]; then
        print_validator_success "All Swift source files are valid"
        return 0
    else
        print_validator_error "Source file validation failed ($source_errors issues)"
        return 1
    fi
}

# Validate project dependencies and imports
validate_dependencies() {
    print_validator_status "Validating project dependencies..."
    
    local dependency_errors=0
    local swift_files=$(find Rawtass -name "*.swift" -type f)
    
    # Extract all import statements
    local imports=$(grep -h "^import " $swift_files | sort | uniq)
    
    # Check for required system frameworks
    local required_frameworks=(
        "Foundation"
        "SwiftUI"
        "CoreImage"
    )
    
    for framework in "${required_frameworks[@]}"; do
        if ! echo "$imports" | grep -q "import $framework"; then
            print_validator_warning "Missing import for required framework: $framework"
        fi
    done
    
    # Check for problematic imports
    local problematic_imports=(
        "UIKit"  # Should use AppKit on macOS
    )
    
    for import in "${problematic_imports[@]}"; do
        if echo "$imports" | grep -q "import $import"; then
            print_validator_warning "Potentially problematic import for macOS: $import"
            dependency_errors=$((dependency_errors + 1))
        fi
    done
    
    # Validate UniformTypeIdentifiers usage (common issue)
    if grep -r "UTType\|uniformTypeIdentifiers" Rawtass/ >/dev/null 2>&1; then
        if ! echo "$imports" | grep -q "import UniformTypeIdentifiers"; then
            print_validator_error "UTType used but UniformTypeIdentifiers not imported"
            dependency_errors=$((dependency_errors + 1))
        fi
    fi
    
    if [[ $dependency_errors -eq 0 ]]; then
        print_validator_success "Project dependencies are properly configured"
        return 0
    else
        print_validator_error "Dependency validation failed ($dependency_errors issues)"
        return 1
    fi
}

# Validate build configuration
validate_build_configuration() {
    print_validator_status "Validating build configuration..."
    
    local config_errors=0
    local project_file="Rawtass.xcodeproj/project.pbxproj"
    
    # Check deployment target
    if ! grep -q "MACOSX_DEPLOYMENT_TARGET.*14\.0" "$project_file"; then
        print_validator_warning "Deployment target may not be set to macOS 14.0"
    fi
    
    # Check Swift version
    if ! grep -q "SWIFT_VERSION.*5\.0" "$project_file"; then
        print_validator_warning "Swift version may not be properly configured"
    fi
    
    # Check code signing settings
    if grep -q "CODE_SIGN_STYLE.*Manual" "$project_file"; then
        print_validator_warning "Manual code signing configured (may cause issues)"
    fi
    
    # Check for hardened runtime
    if ! grep -q "ENABLE_HARDENED_RUNTIME.*YES" "$project_file"; then
        print_validator_warning "Hardened runtime not enabled"
    fi
    
    # Check app sandbox
    if ! grep -q "com\.apple\.security\.app-sandbox" Rawtass/Rawtass.entitlements 2>/dev/null; then
        print_validator_warning "App sandbox not configured in entitlements"
    fi
    
    if [[ $config_errors -eq 0 ]]; then
        print_validator_success "Build configuration is valid"
        return 0
    else
        print_validator_error "Build configuration validation failed ($config_errors issues)"
        return 1
    fi
}

# Validate assets and resources
validate_resources() {
    print_validator_status "Validating application resources..."
    
    local resource_errors=0
    
    # Check Assets.xcassets
    if [[ ! -d "Rawtass/Assets.xcassets" ]]; then
        print_validator_error "Assets catalog not found"
        resource_errors=$((resource_errors + 1))
    else
        # Check for required assets
        if [[ ! -d "Rawtass/Assets.xcassets/AppIcon.appiconset" ]]; then
            print_validator_warning "App icon not configured"
        fi
        
        if [[ ! -d "Rawtass/Assets.xcassets/AccentColor.colorset" ]]; then
            print_validator_warning "Accent color not configured"
        fi
    fi
    
    # Check entitlements file
    if [[ ! -f "Rawtass/Rawtass.entitlements" ]]; then
        print_validator_error "Entitlements file not found"
        resource_errors=$((resource_errors + 1))
    else
        # Validate entitlements format
        if ! plutil -lint "Rawtass/Rawtass.entitlements" >/dev/null 2>&1; then
            print_validator_error "Invalid entitlements file format"
            resource_errors=$((resource_errors + 1))
        fi
    fi
    
    # Check Preview Content
    if [[ ! -d "Rawtass/Preview Content" ]]; then
        print_validator_warning "Preview Content directory not found"
    fi
    
    if [[ $resource_errors -eq 0 ]]; then
        print_validator_success "Application resources are valid"
        return 0
    else
        print_validator_error "Resource validation failed ($resource_errors issues)"
        return 1
    fi
}

# Validate project file references
validate_file_references() {
    print_validator_status "Validating project file references..."
    
    local reference_errors=0
    local project_file="Rawtass.xcodeproj/project.pbxproj"
    
    # Extract file references from project
    local file_refs=$(grep "path = " "$project_file" | grep -v "sourceTree" | sed 's/.*path = //g' | sed 's/;.*//g' | tr -d '"')
    
    # Check if referenced files exist
    while IFS= read -r file_ref; do
        if [[ -n "$file_ref" && ! -e "Rawtass/$file_ref" && ! -e "$file_ref" ]]; then
            print_validator_error "Referenced file not found: $file_ref"
            reference_errors=$((reference_errors + 1))
        fi
    done <<< "$file_refs"
    
    # Check for unreferenced Swift files
    local swift_files=$(find Rawtass -name "*.swift" -type f)
    for swift_file in $swift_files; do
        local basename=$(basename "$swift_file")
        if ! grep -q "$basename" "$project_file"; then
            print_validator_warning "Swift file not referenced in project: $swift_file"
        fi
    done
    
    if [[ $reference_errors -eq 0 ]]; then
        print_validator_success "Project file references are valid"
        return 0
    else
        print_validator_error "File reference validation failed ($reference_errors issues)"
        return 1
    fi
}

# Generate validation report
generate_validation_report() {
    local overall_status="$1"
    local report_file="logs/validation_report_$(date +%Y%m%d_%H%M%S).md"
    
    mkdir -p logs
    
    cat > "$report_file" << EOF
# Rawtass Project Validation Report

**Date:** $(date)
**Status:** $overall_status

## Validation Results

### ✅ Completed Validations
- Xcode project structure
- Swift source files  
- Project dependencies
- Build configuration
- Application resources
- File references

### 📊 Summary

EOF

    if [[ "$overall_status" == "✅ PASSED" ]]; then
        echo "All validation checks passed successfully." >> "$report_file"
    else
        echo "Some validation checks failed. See details above." >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "**Full validation log available in terminal output**" >> "$report_file"
    
    print_validator_success "Validation report generated: $report_file"
}

# Main validation routine
main() {
    print_validator_header
    
    local overall_success=true
    local validation_steps=(
        "validate_xcode_project"
        "validate_source_files"
        "validate_dependencies"
        "validate_build_configuration"
        "validate_resources"
        "validate_file_references"
    )
    
    echo ""
    print_validator_status "Starting comprehensive project validation..."
    echo ""
    
    for step in "${validation_steps[@]}"; do
        if ! $step; then
            overall_success=false
        fi
        echo ""
    done
    
    # Generate report
    if [[ "$overall_success" == true ]]; then
        generate_validation_report "✅ PASSED"
        print_validator_success "🎉 All validation checks passed!"
        return 0
    else
        generate_validation_report "❌ FAILED"
        print_validator_error "❌ Some validation checks failed"
        print_validator_status "Run the build script for detailed error analysis and fixes"
        return 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "xcode")
        validate_xcode_project
        ;;
    "sources")
        validate_source_files
        ;;
    "deps")
        validate_dependencies
        ;;
    "config")
        validate_build_configuration
        ;;
    "resources")
        validate_resources
        ;;
    "refs")
        validate_file_references
        ;;
    "help"|"-h"|"--help")
        echo "Rawtass Project Validator"
        echo ""
        echo "Usage: $0 [validation_type]"
        echo ""
        echo "Validation Types:"
        echo "  (no args) - Run all validations"
        echo "  xcode     - Validate Xcode project structure"
        echo "  sources   - Validate Swift source files"
        echo "  deps      - Validate dependencies and imports"
        echo "  config    - Validate build configuration"
        echo "  resources - Validate assets and resources"
        echo "  refs      - Validate file references"
        echo "  help      - Show this help"
        echo ""
        exit 0
        ;;
    *)
        main
        ;;
esac