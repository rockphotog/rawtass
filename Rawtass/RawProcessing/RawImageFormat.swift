import Foundation
import ImageIO

/// Comprehensive image format support with LibRaw integration
enum RawImageFormat {
    case nikon(compression: NikonCompression)
    case fujifilm(compression: FujifilmCompression)
    case canon(type: CanonType)
    case sony(type: SonyType)
    case olympus
    case panasonic
    case pentax
    case leica
    case hasselblad
    case phaseOne
    case sigma
    case kodak
    case epson
    case minolta
    case adobe(type: AdobeType)
    case standardImage(type: StandardImageType)
    case other(String)

    enum NikonCompression {
        case lossless
        case lossy
        case losslessCompressed
        case highEfficiency  // HE
        case highEfficiencyStar  // HE*
    }

    enum FujifilmCompression {
        case lossless
        case compressed
    }

    enum CanonType {
        case cr2  // Canon RAW version 2
        case cr3  // Canon RAW version 3 (newer)
        case crw  // Canon RAW (older)
    }

    enum SonyType {
        case arw  // Sony Alpha RAW
        case srf  // Sony RAW Format
        case sr2  // Sony RAW version 2
    }

    enum AdobeType {
        case dng  // Digital Negative
    }

    enum StandardImageType {
        case jpeg
        case png
        case tiff
        case bmp
        case gif
        case heic
        case webp
    }

    var description: String {
        switch self {
        case .nikon(let compression):
            return "Nikon NEF (\(compression))"
        case .fujifilm(let compression):
            return "Fujifilm RAF (\(compression))"
        case .canon(let type):
            return "Canon \(type)"
        case .sony(let type):
            return "Sony \(type)"
        case .olympus:
            return "Olympus ORF"
        case .panasonic:
            return "Panasonic RW2/RAW"
        case .pentax:
            return "Pentax PEF"
        case .leica:
            return "Leica RWL/DNG"
        case .hasselblad:
            return "Hasselblad 3FR"
        case .phaseOne:
            return "Phase One IIQ"
        case .sigma:
            return "Sigma X3F"
        case .kodak:
            return "Kodak DCR/KDC"
        case .epson:
            return "Epson ERF"
        case .minolta:
            return "Minolta MRW"
        case .adobe(let type):
            return "Adobe \(type)"
        case .standardImage(let type):
            return "\(type)".uppercased()
        case .other(let format):
            return format
        }
    }
}

/// Configuration options for raw image processing
struct RawProcessingOptions {
    var exposureAdjustment: Float = 0.0
    var highlightRecovery: Float = 0.0
    var shadowRecovery: Float = 0.0
    var whiteBalance: WhiteBalanceMode = .auto
    var colorSpace: ColorSpace = .sRGB
    var outputBitDepth: BitDepth = .sixteen

    enum WhiteBalanceMode {
        case auto
        case daylight
        case cloudy
        case shade
        case tungsten
        case fluorescent
        case custom(temperature: Int, tint: Float)
    }

    enum ColorSpace {
        case sRGB
        case adobeRGB
        case prophotoRGB
    }

    enum BitDepth {
        case eight
        case sixteen
    }

    /// Convert processing options to Core Image raw options
    func toCoreImageOptions() -> [CFString: Any]? {
        var options: [CFString: Any] = [:]

        // Map exposure adjustment to Core Image
        if exposureAdjustment != 0.0 {
            // Use string key for compatibility
            options["kCGImageSourceRawExposureBias" as CFString] = NSNumber(
                value: exposureAdjustment)
        }

        // Map highlight/shadow recovery if available
        if highlightRecovery != 0.0 {
            // Core Image doesn't have direct highlight recovery, but we can use exposure compensation
            options["kCGImageSourceRawExposureBias" as CFString] = NSNumber(
                value: -highlightRecovery * 0.5)
        }

        // Map white balance settings
        switch whiteBalance {
        case .custom(let temperature, let tint):
            options["kCGImageSourceRawWhiteBalanceTemperature" as CFString] = NSNumber(
                value: temperature)
            options["kCGImageSourceRawWhiteBalanceTint" as CFString] = NSNumber(value: tint)
        default:
            // Auto white balance is default, no need to set
            break
        }

        return options.isEmpty ? nil : options
    }
}
