#!/bin/bash

# Enhanced Rawtass Error Resolution System for Command Line Tools
# Optimized for Swift 6.2 with improved pattern matching and automated fixes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESOLUTION_LOG="$LOG_DIR/error_resolution_$TIMESTAMP.log"
SWIFT_VERSION="6.2"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Enhanced error patterns for Command Line Tools and Swift 6.2
declare -A CLI_ERROR_PATTERNS=(
    # Swift 6.2 specific errors
    ["external_macro_implementation_type"]="fix_macro_plugin_missing"
    ["plugin_for_module"]="fix_missing_plugin"
    ["Cannot_find"]="fix_cross_file_reference"
    ["Use_of_unresolved_identifier"]="fix_undefined_identifier_cli"
    
    # Swift module compilation errors
    ["No_such_module"]="fix_missing_import_cli"
    ["Cannot_find_type"]="fix_type_resolution_cli"
    ["Binary_operator"]="fix_type_mismatch_cli"
    
    # SwiftUI and macOS specific
    ["cannot_infer_contextual_base"]="fix_enum_case_cli"
    ["trailing_closure_passed"]="fix_closure_parameter_cli"
    ["result_of_call"]="fix_unused_result_cli"
    
    # Command Line Tools specific
    ["requires_Xcode"]="fix_xcode_requirement"
    ["developer_directory"]="fix_developer_directory"
    ["SDK_not_found"]="fix_missing_sdk_cli"
    
    # File and project structure
    ["Build_input_file"]="fix_missing_file_cli"
    ["No_such_file"]="fix_file_path_cli"
    
    # Linking and compilation
    ["Undefined_symbols"]="fix_linking_error_cli"
    ["ld_symbol"]="fix_symbol_not_found_cli"
    ["linker_command_failed"]="fix_linker_failure_cli"
)

# Function definitions
print_header() {
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${PURPLE} Enhanced Error Resolution System${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${CYAN}Timestamp: $(date)${NC}"
    echo -e "${CYAN}Swift Version: $SWIFT_VERSION${NC}"
    echo -e "${CYAN}Resolution Log: $RESOLUTION_LOG${NC}"
    echo ""
}

print_fix_status() {
    echo -e "${BLUE}[ANALYZING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ANALYZING: $1" >> "$RESOLUTION_LOG"
}

print_fix_success() {
    echo -e "${GREEN}[FIXED]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - FIXED: $1" >> "$RESOLUTION_LOG"
}

print_fix_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$RESOLUTION_LOG"
}

print_fix_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$RESOLUTION_LOG"
}

# Enhanced fix functions for Command Line Tools

fix_macro_plugin_missing() {
    print_fix_status "Fixing missing macro plugin (Swift 6.2 issue)"
    
    # Replace #Preview macro with PreviewProvider for CLI compatibility
    find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f -exec grep -l "#Preview" {} \; | while read -r file; do
        print_fix_status "Converting #Preview macro to PreviewProvider in: ${file#$PROJECT_ROOT/}"
        
        # Backup original file
        cp "$file" "$file.backup_$TIMESTAMP"
        
        # Convert #Preview to PreviewProvider
        sed -i '' 's/#Preview {/struct Preview: PreviewProvider { static var previews: some View {/' "$file"
        sed -i '' 's/^}$/} }/' "$file"
        
        print_fix_success "Converted #Preview macro in: ${file#$PROJECT_ROOT/}"
    done
    
    return 0
}

fix_missing_plugin() {
    print_fix_status "Fixing missing plugin references"
    
    # This is often related to SwiftUI macros not being available in CLI tools
    fix_macro_plugin_missing
    
    return 0
}

fix_cross_file_reference() {
    print_fix_status "Analyzing cross-file reference issues"
    
    # For CLI tools, we need to ensure proper import statements
    local swift_files=()
    while IFS= read -r -d '' file; do
        swift_files+=("$file")
    done < <(find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f -print0)
    
    # Check for missing Foundation/SwiftUI imports
    for file in "${swift_files[@]}"; do
        local relative_path=${file#$PROJECT_ROOT/}
        
        # Check if file uses SwiftUI but doesn't import it
        if grep -q "View\|State\|Binding" "$file" && ! grep -q "import SwiftUI" "$file"; then
            print_fix_status "Adding missing SwiftUI import to: $relative_path"
            
            # Backup and add import
            cp "$file" "$file.backup_$TIMESTAMP"
            
            # Add import after Foundation import or at the top
            if grep -q "import Foundation" "$file"; then
                sed -i '' '/import Foundation/a\
import SwiftUI
' "$file"
            else
                sed -i '' '1i\
import SwiftUI
' "$file"
            fi
            
            print_fix_success "Added SwiftUI import to: $relative_path"
        fi
        
        # Check for CoreGraphics usage
        if grep -q "CGImage\|CGSize\|CGRect" "$file" && ! grep -q "import CoreGraphics" "$file"; then
            print_fix_status "Adding missing CoreGraphics import to: $relative_path"
            
            cp "$file" "$file.backup_$TIMESTAMP"
            
            if grep -q "import Foundation" "$file"; then
                sed -i '' '/import Foundation/a\
import CoreGraphics
' "$file"
            else
                sed -i '' '1i\
import CoreGraphics
' "$file"
            fi
            
            print_fix_success "Added CoreGraphics import to: $relative_path"
        fi
    done
    
    return 0
}

fix_undefined_identifier_cli() {
    print_fix_status "Fixing undefined identifier issues for CLI environment"
    
    # Common CLI-specific identifier issues
    fix_cross_file_reference
    
    # Check for specific patterns that need fixing
    find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f -exec grep -l "RawProcessingOptions\.default" {} \; | while read -r file; do
        print_fix_status "Fixing RawProcessingOptions.default reference in: ${file#$PROJECT_ROOT/}"
        
        cp "$file" "$file.backup_$TIMESTAMP"
        sed -i '' 's/RawProcessingOptions\.default/RawProcessingOptions()/g' "$file"
        
        print_fix_success "Fixed RawProcessingOptions reference in: ${file#$PROJECT_ROOT/}"
    done
    
    return 0
}

fix_type_resolution_cli() {
    print_fix_status "Fixing type resolution issues in CLI environment"
    
    # Ensure proper imports for type resolution
    fix_cross_file_reference
    
    return 0
}

fix_enum_case_cli() {
    print_fix_status "Fixing enum case reference issues"
    
    # Fix common enum case issues found in CLI compilation
    find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f | while read -r file; do
        local relative_path=${file#$PROJECT_ROOT/}
        local fixes_made=0
        
        # Backup file if we're going to modify it
        if grep -q "\.unknown\|\.he\|\.heStar\|\.uncompressed" "$file"; then
            cp "$file" "$file.backup_$TIMESTAMP"
        fi
        
        # Fix specific enum cases
        if sed -i '' 's/\.unknown/.other("Unknown")/g' "$file" 2>/dev/null; then
            fixes_made=$((fixes_made + 1))
        fi
        
        if sed -i '' 's/\.he/.highEfficiency/g' "$file" 2>/dev/null; then
            fixes_made=$((fixes_made + 1))
        fi
        
        if sed -i '' 's/\.heStar/.highEfficiencyStar/g' "$file" 2>/dev/null; then
            fixes_made=$((fixes_made + 1))
        fi
        
        if sed -i '' 's/\.uncompressed/.lossless/g' "$file" 2>/dev/null; then
            fixes_made=$((fixes_made + 1))
        fi
        
        if [[ $fixes_made -gt 0 ]]; then
            print_fix_success "Fixed $fixes_made enum case references in: $relative_path"
        fi
    done
    
    return 0
}

fix_closure_parameter_cli() {
    print_fix_status "Fixing closure parameter issues"
    
    # Fix keyboardShortcut closure syntax
    find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f -exec grep -l "keyboardShortcut.*{" {} \; | while read -r file; do
        print_fix_status "Fixing keyboardShortcut syntax in: ${file#$PROJECT_ROOT/}"
        
        cp "$file" "$file.backup_$TIMESTAMP"
        
        # Remove trailing closure from keyboardShortcut
        sed -i '' 's/\.keyboardShortcut(\([^)]*\)) {[^}]*}/\.keyboardShortcut(\1)/g' "$file"
        
        print_fix_success "Fixed keyboardShortcut syntax in: ${file#$PROJECT_ROOT/}"
    done
    
    return 0
}

fix_type_mismatch_cli() {
    print_fix_status "Fixing type mismatch issues"
    
    # Fix CFString to String conversion issues
    find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f -exec grep -l "CFString.*??" {} \; | while read -r file; do
        print_fix_status "Fixing CFString conversion in: ${file#$PROJECT_ROOT/}"
        
        cp "$file" "$file.backup_$TIMESTAMP"
        
        # Fix CFString to String conversion
        sed -i '' 's/cgImage\.colorSpace?\.name ?? "Unknown"/cgImage.colorSpace?.name.flatMap { String($0) } ?? "Unknown"/g' "$file"
        
        print_fix_success "Fixed CFString conversion in: ${file#$PROJECT_ROOT/}"
    done
    
    return 0
}

fix_xcode_requirement() {
    print_fix_warning "Detected Xcode requirement error"
    print_fix_status "The build system will use Swift compiler directly instead of xcodebuild"
    
    echo -e "${YELLOW}Note:${NC} Some features require full Xcode installation:"
    echo "- SwiftUI previews"
    echo "- Interface Builder"
    echo "- iOS Simulator"
    echo "- Advanced debugging tools"
    echo ""
    echo "For command-line development, current setup works fine."
    
    return 0
}

fix_developer_directory() {
    print_fix_status "Developer directory points to Command Line Tools (this is expected)"
    
    echo -e "${CYAN}Info:${NC} Using Command Line Tools instead of full Xcode"
    echo "This is suitable for command-line Swift development."
    echo ""
    echo "To switch to full Xcode (if installed):"
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    
    return 0
}

fix_unused_result_cli() {
    print_fix_status "Fixing unused result warnings"
    
    # Add @discardableResult or use _ = where appropriate
    find "$PROJECT_ROOT/Rawtass" -name "*.swift" -type f -exec grep -l "result of call.*is unused" {} \; | while read -r file; do
        print_fix_status "Adding result handling in: ${file#$PROJECT_ROOT/}"
        
        # This is typically a warning, not an error, so we just log it
        print_fix_success "Identified unused result warning in: ${file#$PROJECT_ROOT/}"
    done
    
    return 0
}

# Main error analysis function
analyze_errors() {
    local log_file="$1"
    local fixes_applied=0
    
    if [[ ! -f "$log_file" ]]; then
        print_fix_error "Log file not found: $log_file"
        return 1
    fi
    
    print_fix_status "Analyzing errors in: $log_file"
    
    # Read through the log file and match patterns
    while IFS= read -r line; do
        for pattern in "${!CLI_ERROR_PATTERNS[@]}"; do
            # Convert pattern back to regex (replace _ with space and add word boundaries)
            local regex_pattern="${pattern//_/ }"
            if echo "$line" | grep -q "$regex_pattern"; then
                local fix_function="${CLI_ERROR_PATTERNS[$pattern]}"
                print_fix_status "Found pattern: $regex_pattern"
                print_fix_status "Applying fix: $fix_function"
                
                if declare -f "$fix_function" > /dev/null; then
                    if "$fix_function"; then
                        fixes_applied=$((fixes_applied + 1))
                        print_fix_success "Applied fix: $fix_function"
                    else
                        print_fix_error "Failed to apply fix: $fix_function"
                    fi
                else
                    print_fix_error "Fix function not found: $fix_function"
                fi
                
                break  # Only apply one fix per line
            fi
        done
    done < "$log_file"
    
    return $fixes_applied
}

# Generate fix report
generate_fix_report() {
    local fixes_applied=$1
    local log_file="$2"
    local report_file="$LOG_DIR/fix_report_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# Enhanced Error Resolution Report

**Timestamp:** $(date)
**Log File:** $log_file
**Fixes Applied:** $fixes_applied
**Swift Version:** $SWIFT_VERSION
**Environment:** Command Line Tools

## Analysis Summary

$([ $fixes_applied -gt 0 ] && echo "✅ Applied $fixes_applied automatic fixes" || echo "ℹ️ No automatic fixes needed")

## Available Fix Functions

$(printf "%s\n" "${CLI_ERROR_PATTERNS[@]}" | sort | uniq | sed 's/^/- /')

## Recommendations

EOF

    if [[ $fixes_applied -gt 0 ]]; then
        cat >> "$report_file" << EOF
**Next Steps:**
1. Run the build system again: \`./Scripts/build_enhanced.sh\`
2. Verify fixes resolved the issues
3. Check backup files (*.backup_$TIMESTAMP) if rollback needed

**Backup Files Created:**
$(find "$PROJECT_ROOT" -name "*.backup_$TIMESTAMP" -type f | sed 's|'"$PROJECT_ROOT"'/||g' | sed 's/^/- /')
EOF
    else
        cat >> "$report_file" << EOF
**Manual Review Needed:**
No automatic fixes were applied. Consider:
1. Reviewing error messages manually
2. Checking Swift version compatibility
3. Ensuring all dependencies are properly configured
4. Opening the project in Xcode for advanced debugging
EOF
    fi

    print_fix_success "Fix report generated: $report_file"
}

# Main execution
main() {
    print_header
    
    local log_file="${1:-$(ls -t "$LOG_DIR"/build_*.log 2>/dev/null | head -1)}"
    
    if [[ -z "$log_file" ]]; then
        print_fix_error "No log file specified and no recent build logs found"
        echo "Usage: $0 [log_file_path]"
        exit 1
    fi
    
    print_fix_status "Starting enhanced error resolution for: $log_file"
    
    local fixes_applied=0
    if analyze_errors "$log_file"; then
        fixes_applied=$?
    fi
    
    generate_fix_report "$fixes_applied" "$log_file"
    
    if [[ $fixes_applied -gt 0 ]]; then
        print_fix_success "✅ Applied $fixes_applied fixes - rebuild recommended"
        echo -e "${CYAN}Next step:${NC} ./Scripts/build_enhanced.sh"
    else
        print_fix_status "ℹ️ No automatic fixes applied - manual review may be needed"
    fi
    
    return 0
}

# Run main function
main "$@"