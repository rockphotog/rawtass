#!/usr/bin/env bash
set -euo pipefail

# LibRaw Setup Script for Rawtass
# Automatically downloads, builds, and integrates LibRaw for RAW image processing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIBRAW_VERSION="0.21.2"
LIBRAW_URL="https://www.libraw.org/data/LibRaw-${LIBRAW_VERSION}.tar.gz"
BUILD_DIR="${PROJECT_ROOT}/build/libraw"
INSTALL_DIR="${PROJECT_ROOT}/LibRawSupport"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    log_success "Running on macOS"
}

# Check for required tools
check_dependencies() {
    local missing_deps=()
    
    # Check for essential build tools
    for cmd in curl tar make gcc g++ pkg-config; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log_error "Xcode Command Line Tools not found"
        log_info "Install with: xcode-select --install"
        exit 1
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install missing tools with Homebrew or Xcode"
        exit 1
    fi
    
    log_success "All dependencies satisfied"
}

# Try to install LibRaw via Homebrew first
try_homebrew_install() {
    if command -v brew &> /dev/null; then
        log_info "Attempting Homebrew installation..."
        
        if brew list libraw &> /dev/null; then
            log_success "LibRaw already installed via Homebrew"
            
            # Get Homebrew prefix
            BREW_PREFIX=$(brew --prefix)
            echo "LIBRAW_HOMEBREW_PATH=${BREW_PREFIX}" > "${PROJECT_ROOT}/.libraw_config"
            return 0
        else
            log_info "Installing LibRaw via Homebrew..."
            if brew install libraw; then
                log_success "LibRaw installed via Homebrew"
                BREW_PREFIX=$(brew --prefix)
                echo "LIBRAW_HOMEBREW_PATH=${BREW_PREFIX}" > "${PROJECT_ROOT}/.libraw_config"
                return 0
            else
                log_warning "Homebrew installation failed, falling back to source build"
                return 1
            fi
        fi
    else
        log_warning "Homebrew not found, will build from source"
        return 1
    fi
}

# Build LibRaw from source
build_from_source() {
    log_info "Building LibRaw ${LIBRAW_VERSION} from source..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Download LibRaw if not already present
    if [[ ! -f "LibRaw-${LIBRAW_VERSION}.tar.gz" ]]; then
        log_info "Downloading LibRaw ${LIBRAW_VERSION}..."
        curl -L "$LIBRAW_URL" -o "LibRaw-${LIBRAW_VERSION}.tar.gz"
        log_success "Download completed"
    else
        log_info "Using existing LibRaw archive"
    fi
    
    # Extract
    log_info "Extracting LibRaw..."
    tar -xzf "LibRaw-${LIBRAW_VERSION}.tar.gz"
    cd "LibRaw-${LIBRAW_VERSION}"
    
    # Configure build
    log_info "Configuring build..."
    ./configure \
        --prefix="$INSTALL_DIR" \
        --enable-openmp \
        --enable-jpeg \
        --enable-jasper \
        --enable-lcms \
        --disable-static \
        --enable-shared \
        CPPFLAGS="-I/usr/local/include -I/opt/homebrew/include" \
        LDFLAGS="-L/usr/local/lib -L/opt/homebrew/lib"
    
    # Build
    log_info "Building LibRaw (this may take several minutes)..."
    make -j"$(sysctl -n hw.ncpu)"
    
    # Install to project directory
    log_info "Installing LibRaw to project..."
    make install
    
    # Store configuration
    echo "LIBRAW_CUSTOM_PATH=${INSTALL_DIR}" > "${PROJECT_ROOT}/.libraw_config"
    
    log_success "LibRaw built and installed successfully"
}

# Create necessary project directories
create_project_structure() {
    log_info "Creating project structure..."
    
    # Create directories
    mkdir -p "${PROJECT_ROOT}/LibRawSupport/include"
    mkdir -p "${PROJECT_ROOT}/LibRawSupport/lib"
    
    log_success "Project structure created"
}

# Create C++ bridge header
create_bridge_header() {
    log_info "Creating LibRaw bridge header..."
    
    cat > "${PROJECT_ROOT}/LibRawSupport/LibRawBridge.h" << 'EOF'
//
//  LibRawBridge.h
//  Rawtass LibRaw Integration
//
//  C++ bridge for LibRaw functionality
//

#ifndef LibRawBridge_h
#define LibRawBridge_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// Error codes matching LibRaw
typedef enum {
    LIBRAW_SUCCESS = 0,
    LIBRAW_UNSPECIFIED_ERROR = -1,
    LIBRAW_FILE_UNSUPPORTED = -2,
    LIBRAW_REQUEST_FOR_NONEXISTENT_IMAGE = -3,
    LIBRAW_OUT_OF_ORDER_CALL = -4,
    LIBRAW_NO_THUMBNAIL = -5,
    LIBRAW_UNSUPPORTED_THUMBNAIL = -6,
    LIBRAW_INPUT_CLOSED = -7,
    LIBRAW_NOT_IMPLEMENTED = -8,
    LIBRAW_UNSUFFICIENT_MEMORY = -100001,
    LIBRAW_DATA_ERROR = -100002,
    LIBRAW_IO_ERROR = -100003,
    LIBRAW_CANCELLED_BY_CALLBACK = -100004,
    LIBRAW_BAD_CROP = -100005,
    LIBRAW_TOO_BIG = -100006
} LibRawError;

// Image info structure
typedef struct {
    uint32_t width;
    uint32_t height;
    uint32_t colors;
    uint32_t bits_per_sample;
    char make[64];
    char model[64];
    float iso_speed;
    float shutter;
    float aperture;
    float focal_len;
} LibRawImageInfo;

// Processing options
typedef struct {
    float brightness;
    float highlight;
    float shadows;
    int white_balance;
    int color_space;
    int output_bps;
    bool use_camera_wb;
    bool use_auto_wb;
} LibRawProcessingOptions;

// Core functions
LibRawError libraw_open_file(const char* filename, void** processor);
LibRawError libraw_get_image_info(void* processor, LibRawImageInfo* info);
LibRawError libraw_set_processing_options(void* processor, const LibRawProcessingOptions* options);
LibRawError libraw_unpack(void* processor);
LibRawError libraw_process(void* processor);
LibRawError libraw_get_processed_image(void* processor, uint8_t** data, uint32_t* size);
void libraw_close(void* processor);

// Format detection
bool libraw_is_supported_file(const char* filename);
const char* libraw_get_format_name(const char* filename);

// Error handling
const char* libraw_strerror(LibRawError error);

#ifdef __cplusplus
}
#endif

#endif /* LibRawBridge_h */
EOF
    
    log_success "Bridge header created"
}

# Create C++ bridge implementation
create_bridge_implementation() {
    log_info "Creating LibRaw bridge implementation..."
    
    cat > "${PROJECT_ROOT}/LibRawSupport/LibRawBridge.cpp" << 'EOF'
//
//  LibRawBridge.cpp
//  Rawtass LibRaw Integration
//
//  C++ implementation of LibRaw bridge
//

#include "LibRawBridge.h"
#include <libraw/libraw.h>
#include <string>
#include <cstring>

// Convert LibRaw processor to our handle
LibRaw* get_processor(void* handle) {
    return static_cast<LibRaw*>(handle);
}

LibRawError libraw_open_file(const char* filename, void** processor) {
    if (!filename || !processor) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    LibRaw* lr = new LibRaw();
    int ret = lr->open_file(filename);
    
    if (ret != LIBRAW_SUCCESS) {
        delete lr;
        return static_cast<LibRawError>(ret);
    }
    
    *processor = lr;
    return LIBRAW_SUCCESS;
}

LibRawError libraw_get_image_info(void* processor, LibRawImageInfo* info) {
    if (!processor || !info) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    LibRaw* lr = get_processor(processor);
    
    info->width = lr->imgdata.sizes.width;
    info->height = lr->imgdata.sizes.height;
    info->colors = lr->imgdata.idata.colors;
    info->bits_per_sample = lr->imgdata.color.maximum;
    
    std::strncpy(info->make, lr->imgdata.idata.make, sizeof(info->make) - 1);
    std::strncpy(info->model, lr->imgdata.idata.model, sizeof(info->model) - 1);
    
    info->iso_speed = lr->imgdata.other.iso_speed;
    info->shutter = lr->imgdata.other.shutter;
    info->aperture = lr->imgdata.other.aperture;
    info->focal_len = lr->imgdata.other.focal_len;
    
    return LIBRAW_SUCCESS;
}

LibRawError libraw_set_processing_options(void* processor, const LibRawProcessingOptions* options) {
    if (!processor || !options) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    LibRaw* lr = get_processor(processor);
    
    lr->imgdata.params.bright = options->brightness;
    lr->imgdata.params.highlight = static_cast<int>(options->highlight);
    lr->imgdata.params.shadows = static_cast<int>(options->shadows);
    lr->imgdata.params.use_camera_wb = options->use_camera_wb ? 1 : 0;
    lr->imgdata.params.use_auto_wb = options->use_auto_wb ? 1 : 0;
    lr->imgdata.params.output_bps = options->output_bps;
    lr->imgdata.params.output_color = options->color_space;
    
    return LIBRAW_SUCCESS;
}

LibRawError libraw_unpack(void* processor) {
    if (!processor) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    LibRaw* lr = get_processor(processor);
    return static_cast<LibRawError>(lr->unpack());
}

LibRawError libraw_process(void* processor) {
    if (!processor) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    LibRaw* lr = get_processor(processor);
    return static_cast<LibRawError>(lr->dcraw_process());
}

LibRawError libraw_get_processed_image(void* processor, uint8_t** data, uint32_t* size) {
    if (!processor || !data || !size) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    LibRaw* lr = get_processor(processor);
    libraw_processed_image_t* image = lr->dcraw_make_mem_image();
    
    if (!image) {
        return LIBRAW_UNSPECIFIED_ERROR;
    }
    
    *data = image->data;
    *size = image->data_size;
    
    return LIBRAW_SUCCESS;
}

void libraw_close(void* processor) {
    if (processor) {
        LibRaw* lr = get_processor(processor);
        delete lr;
    }
}

bool libraw_is_supported_file(const char* filename) {
    if (!filename) {
        return false;
    }
    
    LibRaw lr;
    int ret = lr.open_file(filename);
    return (ret == LIBRAW_SUCCESS);
}

const char* libraw_get_format_name(const char* filename) {
    // This would need to be implemented based on file extension
    // or by actually opening and analyzing the file
    if (!filename) {
        return "Unknown";
    }
    
    std::string ext = filename;
    size_t pos = ext.find_last_of('.');
    if (pos != std::string::npos) {
        ext = ext.substr(pos + 1);
        std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
        
        if (ext == "nef") return "Nikon NEF";
        if (ext == "cr2" || ext == "cr3") return "Canon RAW";
        if (ext == "arw") return "Sony ARW";
        if (ext == "raf") return "Fujifilm RAF";
        if (ext == "orf") return "Olympus ORF";
        if (ext == "dng") return "Adobe DNG";
    }
    
    return "Unknown RAW";
}

const char* libraw_strerror(LibRawError error) {
    return libraw_strerror(static_cast<int>(error));
}
EOF
    
    log_success "Bridge implementation created"
}

# Create Swift wrapper
create_swift_wrapper() {
    log_info "Creating Swift wrapper for LibRaw..."
    
    cat > "${PROJECT_ROOT}/LibRawSupport/LibRawWrapper.swift" << 'EOF'
//
//  LibRawWrapper.swift
//  Rawtass LibRaw Integration
//
//  Swift wrapper for LibRaw C++ bridge
//

import Foundation
import CoreGraphics

/// Swift wrapper for LibRaw image processing
class LibRawProcessor {
    private var processor: UnsafeMutableRawPointer?
    private var isOpen = false
    
    deinit {
        close()
    }
    
    /// Open a RAW file for processing
    func open(url: URL) throws {
        close() // Close any existing processor
        
        let result = libraw_open_file(url.path, &processor)
        guard result == LIBRAW_SUCCESS else {
            throw LibRawError(rawValue: result.rawValue) ?? .unspecifiedError
        }
        
        isOpen = true
    }
    
    /// Get image information
    func getImageInfo() throws -> ImageInfo {
        guard isOpen, let processor = processor else {
            throw LibRawError.outOfOrderCall
        }
        
        var info = LibRawImageInfo()
        let result = libraw_get_image_info(processor, &info)
        
        guard result == LIBRAW_SUCCESS else {
            throw LibRawError(rawValue: result.rawValue) ?? .unspecifiedError
        }
        
        return ImageInfo(
            width: Int(info.width),
            height: Int(info.height),
            colors: Int(info.colors),
            bitsPerSample: Int(info.bits_per_sample),
            make: String(cString: info.make),
            model: String(cString: info.model),
            isoSpeed: info.iso_speed,
            shutter: info.shutter,
            aperture: info.aperture,
            focalLength: info.focal_len
        )
    }
    
    /// Process the RAW file with given options
    func process(options: ProcessingOptions = ProcessingOptions()) throws -> CGImage {
        guard isOpen, let processor = processor else {
            throw LibRawError.outOfOrderCall
        }
        
        // Set processing options
        var librawOptions = options.toLibRawOptions()
        let optionsResult = libraw_set_processing_options(processor, &librawOptions)
        guard optionsResult == LIBRAW_SUCCESS else {
            throw LibRawError(rawValue: optionsResult.rawValue) ?? .unspecifiedError
        }
        
        // Unpack RAW data
        let unpackResult = libraw_unpack(processor)
        guard unpackResult == LIBRAW_SUCCESS else {
            throw LibRawError(rawValue: unpackResult.rawValue) ?? .unspecifiedError
        }
        
        // Process the image
        let processResult = libraw_process(processor)
        guard processResult == LIBRAW_SUCCESS else {
            throw LibRawError(rawValue: processResult.rawValue) ?? .unspecifiedError
        }
        
        // Get processed image data
        var imageData: UnsafeMutablePointer<UInt8>?
        var imageSize: UInt32 = 0
        let imageResult = libraw_get_processed_image(processor, &imageData, &imageSize)
        
        guard imageResult == LIBRAW_SUCCESS, let data = imageData else {
            throw LibRawError(rawValue: imageResult.rawValue) ?? .unspecifiedError
        }
        
        // Convert to CGImage
        return try createCGImage(from: data, size: imageSize)
    }
    
    /// Close the processor
    func close() {
        if let processor = processor {
            libraw_close(processor)
            self.processor = nil
        }
        isOpen = false
    }
    
    // MARK: - Static Helper Methods
    
    /// Check if a file is supported by LibRaw
    static func isSupported(url: URL) -> Bool {
        return libraw_is_supported_file(url.path)
    }
    
    /// Get format name for a file
    static func formatName(for url: URL) -> String {
        let cString = libraw_get_format_name(url.path)
        return String(cString: cString)
    }
    
    // MARK: - Private Methods
    
    private func createCGImage(from data: UnsafeMutablePointer<UInt8>, size: UInt32) throws -> CGImage {
        // This is a simplified implementation
        // In practice, you'd need to handle different pixel formats, color spaces, etc.
        
        guard let info = try? getImageInfo() else {
            throw LibRawError.unspecifiedError
        }
        
        let bytesPerPixel = info.colors
        let bytesPerRow = info.width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: data,
            width: info.width,
            height: info.height,
            bitsPerComponent: 8, // Simplified - should use actual bit depth
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        
        guard let cgContext = context else {
            throw LibRawError.unspecifiedError
        }
        
        guard let cgImage = cgContext.makeImage() else {
            throw LibRawError.unspecifiedError
        }
        
        return cgImage
    }
}

// MARK: - Supporting Types

/// Image information structure
struct ImageInfo {
    let width: Int
    let height: Int
    let colors: Int
    let bitsPerSample: Int
    let make: String
    let model: String
    let isoSpeed: Float
    let shutter: Float
    let aperture: Float
    let focalLength: Float
}

/// Processing options
struct ProcessingOptions {
    var brightness: Float = 1.0
    var highlight: Float = 0.0
    var shadows: Float = 0.0
    var whiteBalance: WhiteBalance = .camera
    var colorSpace: ColorSpace = .sRGB
    var outputBitDepth: Int = 8
    
    enum WhiteBalance {
        case camera
        case auto
        case daylight
        case custom(temperature: Int, tint: Float)
    }
    
    enum ColorSpace {
        case sRGB
        case adobeRGB
        case prophotoRGB
        
        var rawValue: Int {
            switch self {
            case .sRGB: return 1
            case .adobeRGB: return 2
            case .prophotoRGB: return 3
            }
        }
    }
    
    func toLibRawOptions() -> LibRawProcessingOptions {
        return LibRawProcessingOptions(
            brightness: brightness,
            highlight: highlight,
            shadows: shadows,
            white_balance: whiteBalanceValue,
            color_space: Int32(colorSpace.rawValue),
            output_bps: Int32(outputBitDepth),
            use_camera_wb: whiteBalance == .camera,
            use_auto_wb: whiteBalance == .auto
        )
    }
    
    private var whiteBalanceValue: Int32 {
        switch whiteBalance {
        case .camera: return 0
        case .auto: return 1
        case .daylight: return 2
        case .custom: return 3
        }
    }
}

/// LibRaw error types
enum LibRawError: Int, Error, LocalizedError {
    case success = 0
    case unspecifiedError = -1
    case fileUnsupported = -2
    case requestForNonexistentImage = -3
    case outOfOrderCall = -4
    case noThumbnail = -5
    case unsupportedThumbnail = -6
    case inputClosed = -7
    case notImplemented = -8
    case insufficientMemory = -100001
    case dataError = -100002
    case ioError = -100003
    case cancelledByCallback = -100004
    case badCrop = -100005
    case tooBig = -100006
    
    var errorDescription: String? {
        switch self {
        case .success:
            return "Success"
        case .unspecifiedError:
            return "Unspecified error"
        case .fileUnsupported:
            return "File format not supported"
        case .requestForNonexistentImage:
            return "Request for nonexistent image"
        case .outOfOrderCall:
            return "Out of order function call"
        case .noThumbnail:
            return "No thumbnail available"
        case .unsupportedThumbnail:
            return "Thumbnail format not supported"
        case .inputClosed:
            return "Input stream closed"
        case .notImplemented:
            return "Feature not implemented"
        case .insufficientMemory:
            return "Insufficient memory"
        case .dataError:
            return "Data error"
        case .ioError:
            return "I/O error"
        case .cancelledByCallback:
            return "Operation cancelled"
        case .badCrop:
            return "Bad crop parameters"
        case .tooBig:
            return "Image too large"
        }
    }
}
EOF
    
    log_success "Swift wrapper created"
}

# Copy or link library files
setup_library_files() {
    log_info "Setting up library files..."
    
    # Read configuration
    if [[ -f "${PROJECT_ROOT}/.libraw_config" ]]; then
        source "${PROJECT_ROOT}/.libraw_config"
    fi
    
    if [[ -n "${LIBRAW_HOMEBREW_PATH:-}" ]]; then
        # Link from Homebrew installation
        ln -sf "$LIBRAW_HOMEBREW_PATH/lib/libraw.dylib" "${PROJECT_ROOT}/LibRawSupport/lib/"
        ln -sf "$LIBRAW_HOMEBREW_PATH/include/libraw" "${PROJECT_ROOT}/LibRawSupport/include/"
        log_success "Linked Homebrew LibRaw installation"
        
    elif [[ -n "${LIBRAW_CUSTOM_PATH:-}" ]]; then
        # Custom build already installed to correct location
        log_success "Using custom LibRaw build"
        
    else
        log_error "LibRaw installation not found"
        exit 1
    fi
}

# Update Xcode project settings
create_xcode_config() {
    log_info "Creating Xcode configuration helper..."
    
    cat > "${PROJECT_ROOT}/LibRawSupport/XcodeConfig.md" << 'EOF'
# Xcode Configuration for LibRaw

After running the setup script, configure your Xcode project:

## 1. Add Files to Project
- Add all files in `LibRawSupport/` to your Xcode project
- Ensure `LibRawBridge.h` is added to the target

## 2. Build Settings

### Library Search Paths
Add these paths to "Library Search Paths":
```
$(PROJECT_DIR)/LibRawSupport/lib
/usr/local/lib
/opt/homebrew/lib
```

### Header Search Paths
Add these paths to "Header Search Paths":
```
$(PROJECT_DIR)/LibRawSupport/include
/usr/local/include
/opt/homebrew/include
```

### Other Linker Flags
Add:
```
-lraw
```

### C++ Language Dialect
Set to: **C++17**

### C++ Standard Library
Set to: **libc++**

## 3. Bridging Header
Set "Objective-C Bridging Header" to:
```
LibRawSupport/LibRawBridge.h
```

## 4. Framework Search Paths
Ensure these frameworks are linked:
- CoreGraphics.framework
- ImageIO.framework
- Foundation.framework

## 5. Build Phases
In "Link Binary With Libraries", ensure libraw.dylib is included.

## Testing
After configuration, build the project. LibRaw functionality will be available through the `LibRawProcessor` class.
EOF
    
    log_success "Xcode configuration guide created"
}

# Main execution
main() {
    echo "======================================="
    echo " LibRaw Setup for Rawtass"
    echo "======================================="
    echo "Installing industry-standard RAW processing library"
    echo
    
    check_macos
    check_dependencies
    create_project_structure
    
    # Try Homebrew first, fallback to source build
    if ! try_homebrew_install; then
        build_from_source
    fi
    
    setup_library_files
    create_bridge_header
    create_bridge_implementation
    create_swift_wrapper
    create_xcode_config
    
    echo
    log_success "✅ LibRaw setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Open Rawtass.xcodeproj in Xcode"
    echo "2. Add LibRawSupport files to the project"
    echo "3. Follow configuration in LibRawSupport/XcodeConfig.md"
    echo "4. Build and test with RAW files"
    echo
    echo "Supported formats:"
    echo "• Nikon NEF (including HE/HE*)"
    echo "• Fujifilm RAF (including compressed)"
    echo "• Canon CR2/CR3"
    echo "• Sony ARW"
    echo "• Adobe DNG"
    echo "• And 50+ more RAW formats"
    echo
}

# Cleanup function
cleanup() {
    log_warning "Setup interrupted"
    exit 1
}

# Set trap for cleanup
trap cleanup INT TERM

# Run main function
main "$@"