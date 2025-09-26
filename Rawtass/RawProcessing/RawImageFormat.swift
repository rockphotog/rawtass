import Foundation

/// Supported raw image formats with compression details
enum RawImageFormat {
    case nikon(compression: NikonCompression)
    case fujifilm(compression: FujifilmCompression)
    case canon
    case sony
    case other(String)
    
    enum NikonCompression {
        case lossless
        case lossy
        case losslessCompressed
        case highEfficiency // HE
        case highEfficiencyStar // HE*
    }
    
    enum FujifilmCompression {
        case lossless
        case compressed
    }
    
    var description: String {
        switch self {
        case .nikon(let compression):
            return "Nikon NEF (\(compression))"
        case .fujifilm(let compression):
            return "Fujifilm RAF (\(compression))"
        case .canon:
            return "Canon CR2/CR3"
        case .sony:
            return "Sony ARW"
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
}