import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Core raw image processing engine with LibRaw integration
class RawImageProcessor {

    /// Processing backend options
    enum ProcessingBackend {
        case coreImage  // macOS native (limited RAW support)
        case libRaw  // Industry standard (comprehensive RAW support)
        case automatic  // Choose best backend for format
    }

    /// Detects the raw image format from file data
    /// - Parameter url: File URL to analyze
    /// - Returns: Detected raw format
    static func detectFormat(from url: URL) -> RawImageFormat {
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            return .other("Unknown")
        }

        // Check file extension first
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "nef":
            return detectNikonCompression(from: data)
        case "raf":
            return detectFujifilmCompression(from: data)
        default:
            return .other("Unknown")
        }
    }

    /// Process raw image file and return CGImage
    /// - Parameters:
    ///   - url: Raw image file URL
    ///   - options: Processing options
    ///   - backend: Processing backend to use
    /// - Returns: Processed CGImage or nil if processing fails
    static func processRawImage(
        from url: URL,
        options: RawProcessingOptions = RawProcessingOptions(),
        backend: ProcessingBackend = .automatic
    ) async -> CGImage? {
        let format = detectFormat(from: url)
        let selectedBackend = selectBackend(for: format, requested: backend)

        switch selectedBackend {
        case .libRaw:
            return await processWithLibRaw(url: url, options: options)
        case .coreImage:
            return await processWithCoreImage(url: url, options: options)
        case .automatic:
            // This case shouldn't occur after selectBackend, but fallback to LibRaw
            return await processWithLibRaw(url: url, options: options)
        }
    }

    /// Select the best processing backend for a given format
    private static func selectBackend(for format: RawImageFormat, requested: ProcessingBackend)
        -> ProcessingBackend
    {
        switch requested {
        case .coreImage, .libRaw:
            return requested
        case .automatic:
            // Choose LibRaw for compressed formats that Core Image doesn't support well
            switch format {
            case .nikon(let compression):
                switch compression {
                case .highEfficiency, .highEfficiencyStar:
                    return .libRaw  // Core Image doesn't support HE/HE*
                default:
                    return .libRaw  // LibRaw generally better for all RAW
                }
            case .fujifilm(let compression):
                switch compression {
                case .compressed:
                    return .libRaw  // Better compressed RAW support
                default:
                    return .libRaw
                }
            default:
                return .libRaw  // LibRaw is more comprehensive
            }
        }
    }

    // MARK: - Private Processing Methods

    private static func detectNikonCompression(from data: Data) -> RawImageFormat {
        // Basic TIFF header analysis for Nikon NEF files
        // This is a simplified implementation - real implementation would need
        // to parse TIFF/EXIF headers to detect HE/HE* compression

        if data.count < 16 { return .nikon(compression: .lossless) }

        // Check for TIFF magic number
        let tiffMagic = data.subdata(in: 0..<4)
        let isBigEndian = tiffMagic == Data([0x4D, 0x4D, 0x00, 0x2A])
        let isLittleEndian = tiffMagic == Data([0x49, 0x49, 0x2A, 0x00])

        guard isBigEndian || isLittleEndian else {
            return .nikon(compression: .lossless)
        }

        // TODO: Parse TIFF IFD entries to detect specific Nikon compression
        // For now, return lossless as default
        return .nikon(compression: .lossless)
    }

    private static func detectFujifilmCompression(from data: Data) -> RawImageFormat {
        // Basic RAF format detection
        // RAF files have a specific header structure

        if data.count < 16 { return .fujifilm(compression: .lossless) }

        // Check for RAF magic number "FUJIFILMCCD-RAW"
        let rafMagic = "FUJIFILMCCD-RAW".data(using: .ascii) ?? Data()

        if data.starts(with: rafMagic) {
            // TODO: Parse RAF header to detect compression type
            return .fujifilm(compression: .lossless)
        }

        return .fujifilm(compression: .lossless)
    }

    private static func processNikonNEF(
        url: URL, compression: RawImageFormat.NikonCompression, options: RawProcessingOptions
    ) async -> CGImage? {
        // For HE/HE* formats, we would need a specialized decoder
        // This is where LibRaw or a custom decoder would be integrated

        switch compression {
        case .highEfficiency, .highEfficiencyStar:
            // These formats require special handling as they're not supported by Core Image
            // Would integrate with LibRaw or custom decoder here
            return await processWithFallbackDecoder(url: url, options: options)
        case .lossless, .lossy, .losslessCompressed:
            // These can be handled by Core Image
            return await processWithCoreImage(url: url, options: options)
        }
    }

    private static func processFujifilmRAF(
        url: URL, compression: RawImageFormat.FujifilmCompression, options: RawProcessingOptions
    ) async -> CGImage? {
        // Fujifilm compressed RAW also needs special handling
        return await processWithCoreImage(url: url, options: options)
    }

    private static func processWithCoreImage(url: URL, options: RawProcessingOptions) async
        -> CGImage?
    {
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<CGImage?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    continuation.resume(returning: nil)
                    return
                }

                var imageOptions: [CFString: Any] = [:]

                // Apply raw processing options
                if let rawOptions = options.toCoreImageOptions() {
                    imageOptions.merge(rawOptions) { _, new in new }
                }

                let image = CGImageSourceCreateImageAtIndex(
                    imageSource, 0, imageOptions as CFDictionary)
                continuation.resume(returning: image)
            }
        }
    }

    /// Process with LibRaw (comprehensive RAW support)
    private static func processWithLibRaw(url: URL, options: RawProcessingOptions) async -> CGImage?
    {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    #if LIBRAW_AVAILABLE
                        // LibRaw processing (when integrated)
                        let processor = LibRawProcessor()
                        try processor.open(url: url)

                        // Convert RawProcessingOptions to LibRaw ProcessingOptions
                        let librawOptions = ProcessingOptions(
                            brightness: options.exposureAdjustment,
                            highlight: options.highlightRecovery,
                            shadows: options.shadowRecovery,
                            whiteBalance: convertWhiteBalance(options.whiteBalance),
                            colorSpace: convertColorSpace(options.colorSpace),
                            outputBitDepth: options.outputBitDepth == .sixteen ? 16 : 8
                        )

                        let cgImage = try processor.process(options: librawOptions)
                        continuation.resume(returning: cgImage)
                    #else
                        // Fallback to Core Image if LibRaw not available
                        Task {
                            let fallbackImage = await processWithCoreImage(
                                url: url, options: options)
                            continuation.resume(returning: fallbackImage)
                        }
                    #endif
                } catch {
                    // If LibRaw fails, try Core Image as fallback
                    Task {
                        let fallbackImage = await processWithCoreImage(url: url, options: options)
                        continuation.resume(returning: fallbackImage)
                    }
                }
            }
        }
    }

    #if LIBRAW_AVAILABLE
        /// Convert RawProcessingOptions white balance to LibRaw format
        private static func convertWhiteBalance(_ wb: RawProcessingOptions.WhiteBalanceMode)
            -> ProcessingOptions.WhiteBalance
        {
            switch wb {
            case .auto:
                return .auto
            case .daylight:
                return .daylight
            case .custom(let temp, let tint):
                return .custom(temperature: temp, tint: tint)
            default:
                return .camera
            }
        }

        /// Convert RawProcessingOptions color space to LibRaw format
        private static func convertColorSpace(_ cs: RawProcessingOptions.ColorSpace)
            -> ProcessingOptions.ColorSpace
        {
            switch cs {
            case .sRGB:
                return .sRGB
            case .adobeRGB:
                return .adobeRGB
            case .prophotoRGB:
                return .prophotoRGB
            }
        }
    #endif

    private static func processWithFallbackDecoder(url: URL, options: RawProcessingOptions) async
        -> CGImage?
    {
        // Legacy method - now redirects to LibRaw
        return await processWithLibRaw(url: url, options: options)
    }
}
