#!/bin/bash

# Rawtass Build & Error Resolution Script
# Comprehensive build system with automatic error detection and resolution

set -e  # Exit on any error (can be overridden for error handling)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Rawtass"
SCHEME_NAME="Rawtass"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
LOG_DIR="$PROJECT_ROOT/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="$LOG_DIR/build_$TIMESTAMP.log"
ERROR_LOG="$LOG_DIR/errors_$TIMESTAMP.log"

# Ensure directories exist
mkdir -p "$LOG_DIR"
mkdir -p "$BUILD_DIR"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE} Rawtass Build System${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${CYAN}Timestamp: $(date)${NC}"
    echo -e "${CYAN}Project Root: $PROJECT_ROOT${NC}"
    echo -e "${CYAN}Build Log: $BUILD_LOG${NC}"
    echo ""
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$BUILD_LOG"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$ERROR_LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$BUILD_LOG"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking build prerequisites..."
    log_message "Starting prerequisite check"
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/$PROJECT_NAME.xcodeproj/project.pbxproj" ]]; then
        print_error "Xcode project not found at $PROJECT_ROOT/$PROJECT_NAME.xcodeproj"
        log_error "Xcode project not found"
        exit 1
    fi
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found. Please install Xcode."
        log_error "xcodebuild command not found"
        exit 1
    fi
    
    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
    print_status "Xcode version: $XCODE_VERSION"
    log_message "Xcode version: $XCODE_VERSION"
    
    # Check if we can find the scheme
    AVAILABLE_SCHEMES=$(xcodebuild -project "$PROJECT_ROOT/$PROJECT_NAME.xcodeproj" -list | grep -A 100 "Schemes:" | grep -v "Schemes:" | grep -v "^$" | head -10 | awk '{print $1}')
    if [[ ! "$AVAILABLE_SCHEMES" =~ "$SCHEME_NAME" ]]; then
        print_warning "Scheme '$SCHEME_NAME' not found. Available schemes:"
        echo "$AVAILABLE_SCHEMES"
        log_error "Scheme $SCHEME_NAME not found"
    fi
    
    print_success "Prerequisites check completed"
    log_message "Prerequisites check completed successfully"
}

# Function to validate project structure
validate_project_structure() {
    print_status "Validating project structure..."
    log_message "Starting project structure validation"
    
    local errors=0
    
    # Check essential Swift files
    local required_files=(
        "Rawtass/App.swift"
        "Rawtass/ContentView.swift"
        "Rawtass/Views/RawImageViewer.swift"
        "Rawtass/RawProcessing/RawImageProcessor.swift"
        "Rawtass/RawProcessing/RawFormatDetector.swift"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            print_error "Missing required file: $file"
            log_error "Missing required file: $file"
            errors=$((errors + 1))
        fi
    done
    
    # Check entitlements
    if [[ ! -f "$PROJECT_ROOT/Rawtass/Rawtass.entitlements" ]]; then
        print_error "Missing entitlements file"
        log_error "Missing entitlements file"
        errors=$((errors + 1))
    fi
    
    # Check Assets catalog
    if [[ ! -d "$PROJECT_ROOT/Rawtass/Assets.xcassets" ]]; then
        print_error "Missing Assets.xcassets"
        log_error "Missing Assets.xcassets"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Project structure validation passed"
        log_message "Project structure validation completed successfully"
        return 0
    else
        print_error "Project structure validation failed with $errors errors"
        log_error "Project structure validation failed with $errors errors"
        return 1
    fi
}

# Function to perform syntax check
syntax_check() {
    print_status "Performing Swift syntax check..."
    log_message "Starting Swift syntax check"
    
    local swift_files=$(find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f)
    local syntax_errors=0
    
    for file in $swift_files; do
        # Basic syntax check using Swift compiler
        if ! xcrun swift -parse "$file" &> /dev/null; then
            print_error "Syntax error in: $(basename "$file")"
            log_error "Syntax error in: $file"
            
            # Try to get more details
            xcrun swift -parse "$file" 2>&1 | head -5 >> "$ERROR_LOG"
            syntax_errors=$((syntax_errors + 1))
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        print_success "Swift syntax check passed"
        log_message "Swift syntax check completed successfully"
        return 0
    else
        print_error "Found $syntax_errors syntax errors"
        log_error "Swift syntax check failed with $syntax_errors errors"
        return 1
    fi
}

# Function to clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    log_message "Starting build cleanup"
    
    # Clean Xcode build folder
    xcodebuild -project "$PROJECT_ROOT/$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME_NAME" \
               clean \
               >> "$BUILD_LOG" 2>&1
    
    # Remove derived data for this project
    local derived_data_path="$HOME/Library/Developer/Xcode/DerivedData"
    if [[ -d "$derived_data_path" ]]; then
        find "$derived_data_path" -name "*$PROJECT_NAME*" -type d -exec rm -rf {} + 2>/dev/null || true
    fi
    
    # Clean local build directory
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    print_success "Build cleanup completed"
    log_message "Build cleanup completed successfully"
}

# Function to attempt automatic error fixes
auto_fix_errors() {
    local build_output="$1"
    print_status "Attempting automatic error resolution..."
    log_message "Starting automatic error resolution"
    
    local fixes_applied=0
    
    # Fix common import issues
    if echo "$build_output" | grep -q "No such module"; then
        print_status "Detected missing module imports, checking common fixes..."
        
        # Check if UniformTypeIdentifiers needs to be added to project
        if echo "$build_output" | grep -q "UniformTypeIdentifiers"; then
            print_warning "UniformTypeIdentifiers framework may need to be linked"
            log_message "Detected UniformTypeIdentifiers framework issue"
        fi
    fi
    
    # Fix deployment target mismatches
    if echo "$build_output" | grep -q "deployment target"; then
        print_status "Detected deployment target issues..."
        log_message "Detected deployment target issues"
    fi
    
    # Fix code signing issues
    if echo "$build_output" | grep -q "Code Sign error\|Provisioning profile"; then
        print_status "Detected code signing issues..."
        print_warning "Code signing may need manual configuration in Xcode"
        log_message "Detected code signing issues"
    fi
    
    # Fix Swift version issues
    if echo "$build_output" | grep -q "Swift Compiler Error"; then
        print_status "Detected Swift compiler errors..."
        log_message "Detected Swift compiler errors"
        
        # Common Swift fixes could be implemented here
    fi
    
    if [[ $fixes_applied -gt 0 ]]; then
        print_success "Applied $fixes_applied automatic fixes"
        log_message "Applied $fixes_applied automatic fixes"
    else
        print_status "No automatic fixes available for current errors"
        log_message "No automatic fixes applied"
    fi
}

# Function to build the project
build_project() {
    print_status "Building project..."
    log_message "Starting project build"
    
    local build_output_file="/tmp/rawtass_build_output_$TIMESTAMP.log"
    
    # Attempt to build
    set +e  # Don't exit on build failure
    xcodebuild -project "$PROJECT_ROOT/$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME_NAME" \
               -configuration Debug \
               -destination "platform=macOS" \
               -derivedDataPath "$BUILD_DIR" \
               build \
               > "$build_output_file" 2>&1
    
    local build_exit_code=$?
    set -e
    
    # Log build output
    cat "$build_output_file" >> "$BUILD_LOG"
    
    if [[ $build_exit_code -eq 0 ]]; then
        print_success "Build completed successfully!"
        log_message "Build completed successfully"
        
        # Show build artifacts
        local app_path=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
        if [[ -n "$app_path" ]]; then
            print_status "Application built at: $app_path"
            log_message "Application built at: $app_path"
        fi
        
        return 0
    else
        print_error "Build failed with exit code $build_exit_code"
        log_error "Build failed with exit code $build_exit_code"
        
        # Extract and display errors
        echo -e "${RED}Build Errors:${NC}"
        grep -E "(error|Error|ERROR)" "$build_output_file" | head -10
        
        # Log errors
        grep -E "(error|Error|ERROR)" "$build_output_file" >> "$ERROR_LOG"
        
        # Attempt automatic fixes
        auto_fix_errors "$(cat "$build_output_file")"
        
        # Cleanup
        rm -f "$build_output_file"
        
        return 1
    fi
}

# Function to run post-build validation
post_build_validation() {
    print_status "Running post-build validation..."
    log_message "Starting post-build validation"
    
    local app_path=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
    
    if [[ -z "$app_path" ]]; then
        print_error "Built application not found"
        log_error "Built application not found"
        return 1
    fi
    
    # Check if app bundle is valid
    if ! codesign --verify --deep --strict "$app_path" &> /dev/null; then
        print_warning "App bundle signature verification failed (expected for debug builds)"
        log_message "App bundle signature verification failed"
    fi
    
    # Check app structure
    local required_contents=(
        "Contents/MacOS/$PROJECT_NAME"
        "Contents/Info.plist"
    )
    
    local validation_errors=0
    for content in "${required_contents[@]}"; do
        if [[ ! -e "$app_path/$content" ]]; then
            print_error "Missing app content: $content"
            log_error "Missing app content: $content"
            validation_errors=$((validation_errors + 1))
        fi
    done
    
    if [[ $validation_errors -eq 0 ]]; then
        print_success "Post-build validation passed"
        log_message "Post-build validation completed successfully"
        return 0
    else
        print_error "Post-build validation failed"
        log_error "Post-build validation failed with $validation_errors errors"
        return 1
    fi
}

# Function to generate build report
generate_build_report() {
    print_status "Generating build report..."
    
    local report_file="$LOG_DIR/build_report_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# Rawtass Build Report

**Date:** $(date)
**Build ID:** $TIMESTAMP
**Project:** $PROJECT_NAME

## Build Configuration
- **Scheme:** $SCHEME_NAME
- **Configuration:** Debug
- **Platform:** macOS
- **Xcode Version:** $(xcodebuild -version | head -1)

## Build Results

EOF

    if [[ -f "$ERROR_LOG" ]] && [[ -s "$ERROR_LOG" ]]; then
        echo "**Status:** ❌ FAILED" >> "$report_file"
        echo "" >> "$report_file"
        echo "## Errors Found" >> "$report_file"
        echo '```' >> "$report_file"
        tail -20 "$ERROR_LOG" >> "$report_file"
        echo '```' >> "$report_file"
    else
        echo "**Status:** ✅ SUCCESS" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "## Build Log" >> "$report_file"
    echo "Full build log available at: \`$BUILD_LOG\`" >> "$report_file"
    
    print_success "Build report generated: $report_file"
    log_message "Build report generated: $report_file"
    
    # Show summary
    echo ""
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE} Build Summary${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${CYAN}Report: $report_file${NC}"
    echo -e "${CYAN}Logs: $LOG_DIR${NC}"
}

# Main build routine
main() {
    print_header
    
    local overall_success=true
    
    # Step 1: Prerequisites
    if ! check_prerequisites; then
        overall_success=false
    fi
    
    # Step 2: Project validation
    if ! validate_project_structure; then
        overall_success=false
    fi
    
    # Step 3: Syntax check
    if ! syntax_check; then
        overall_success=false
    fi
    
    # Step 4: Clean build
    clean_build
    
    # Step 5: Build project
    if ! build_project; then
        overall_success=false
        
        # If build failed, try once more after cleaning
        print_status "Retrying build after comprehensive cleanup..."
        clean_build
        
        if build_project; then
            overall_success=true
            print_success "Build succeeded on retry!"
        fi
    fi
    
    # Step 6: Post-build validation (only if build succeeded)
    if [[ "$overall_success" == true ]]; then
        if ! post_build_validation; then
            overall_success=false
        fi
    fi
    
    # Step 7: Generate report
    generate_build_report
    
    # Final status
    echo ""
    if [[ "$overall_success" == true ]]; then
        print_success "🎉 Build process completed successfully!"
        log_message "Build process completed successfully"
        exit 0
    else
        print_error "❌ Build process failed. Check logs for details."
        log_error "Build process failed"
        echo -e "${YELLOW}Check the error log: $ERROR_LOG${NC}"
        echo -e "${YELLOW}Check the build log: $BUILD_LOG${NC}"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        print_header
        clean_build
        exit 0
        ;;
    "check")
        print_header
        check_prerequisites
        validate_project_structure
        syntax_check
        exit 0
        ;;
    "build-only")
        print_header
        build_project
        exit $?
        ;;
    "help"|"-h"|"--help")
        echo "Rawtass Build Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)   - Run full build process"
        echo "  clean       - Clean build artifacts only"
        echo "  check       - Run pre-build checks only"
        echo "  build-only  - Build without pre-checks"
        echo "  help        - Show this help"
        echo ""
        exit 0
        ;;
    *)
        # Default: run full build process
        main
        ;;
esac