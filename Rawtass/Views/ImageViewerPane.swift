import CoreGraphics
import CoreImage
import SwiftUI

// Professional zoom modes inspired by Lightroom and FastRawViewer
enum ZoomMode: String, CaseIterable {
    case fit = "Fit"  // Fit entire image in window
    case fill = "Fill"  // Fill window (crop if needed)
    case actual = "1:1"  // 100% - one image pixel = one screen pixel
    case quarter = "25%"  // 25% zoom
    case half = "50%"  // 50% zoom
    case double = "200%"  // 200% zoom
    case quad = "400%"  // 400% zoom

    var scale: CGFloat? {
        switch self {
        case .fit, .fill: return nil  // Calculated dynamically
        case .actual: return 1.0
        case .quarter: return 0.25
        case .half: return 0.5
        case .double: return 2.0
        case .quad: return 4.0
        }
    }
}

struct ImageViewerPane: View {
    @Binding var selectedImageURL: URL?
    @State private var image: CGImage?
    @State private var isLoading = false
    @State private var currentZoomMode: ZoomMode = .fit
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    @State private var processingOptions = RawProcessingOptions()
    @State private var errorMessage: String?

    // Computed properties for professional zoom handling
    private var imageSize: CGSize {
        guard let cgImage = image else { return .zero }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    private var availableSize: CGSize {
        CGSize(
            width: max(containerSize.width - 32, 100),
            height: max(containerSize.height - 80, 100)  // Account for toolbar
        )
    }

    private var fitScale: CGFloat {
        guard
            imageSize.width > 0 && imageSize.height > 0 && availableSize.width > 0
                && availableSize.height > 0
        else { return 1.0 }
        let scaleX = availableSize.width / imageSize.width
        let scaleY = availableSize.height / imageSize.height
        return min(scaleX, scaleY)
    }

    private var fillScale: CGFloat {
        guard
            imageSize.width > 0 && imageSize.height > 0 && availableSize.width > 0
                && availableSize.height > 0
        else { return 1.0 }
        let scaleX = availableSize.width / imageSize.width
        let scaleY = availableSize.height / imageSize.height
        return max(scaleX, scaleY)
    }

    private var displayScale: String {
        let percentage = Int(scale * 100)
        return "\(percentage)%"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor.controlBackgroundColor)
                    .ignoresSafeArea(.all)

                if let imageURL = selectedImageURL {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)

                            Text("Loading image...")
                                .font(.title3)
                                .foregroundColor(.secondary)

                            Text(imageURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)

                            Text("Failed to load image")
                                .font(.title2)
                                .foregroundColor(.primary)

                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Try Again") {
                                loadImage()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let cgImage = image {
                        VStack(spacing: 0) {
                            // Professional toolbar
                            HStack {
                                // Image name
                                Text(imageURL.lastPathComponent)
                                    .font(.headline)
                                    .lineLimit(1)

                                Spacer()

                                // Image info
                                Text(formatImageInfo())
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Divider()
                                    .frame(height: 20)

                                // Current zoom display
                                Text(displayScale)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                                    .frame(minWidth: 40)

                                // Zoom mode selector (like Lightroom)
                                Menu {
                                    ForEach(ZoomMode.allCases, id: \.self) { mode in
                                        Button(mode.rawValue) {
                                            setZoomMode(mode)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(currentZoomMode.rawValue)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                // Quick zoom buttons (like FastRawViewer)
                                Button("Fit") {
                                    setZoomMode(.fit)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("1:1") {
                                    setZoomMode(.actual)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))

                            Divider()

                            // Professional image viewer
                            ProfessionalImageView(
                                cgImage: cgImage,
                                scale: $scale,
                                offset: $offset,
                                lastOffset: $lastOffset,
                                containerSize: $containerSize,
                                onDoubleClick: nextZoomMode
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .background(Color.black)
                        }
                    }
                } else {
                    // No image selected state
                    VStack(spacing: 24) {
                        Image(systemName: "photo.badge.magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            Text("No Image Selected")
                                .font(.title2)
                                .foregroundColor(.primary)

                            Text("Select a RAW image from the file browser to view it here")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onChange(of: selectedImageURL) {
            if selectedImageURL != nil {
                loadImage()
            } else {
                image = nil
                errorMessage = nil
                isLoading = false
                currentZoomMode = .fit
                scale = 1.0
                offset = .zero
                lastOffset = .zero
            }
        }
        .onAppear {
            containerSize = CGSize(width: 800, height: 600)  // Default size
        }
    }

    // MARK: - Professional Zoom Controls

    private func setZoomMode(_ mode: ZoomMode) {
        currentZoomMode = mode

        withAnimation(.easeOut(duration: 0.3)) {
            switch mode {
            case .fit:
                scale = fitScale
                centerImage()
            case .fill:
                scale = fillScale
                centerImage()
            case .actual, .quarter, .half, .double, .quad:
                if let targetScale = mode.scale {
                    scale = targetScale
                    constrainOffset()
                }
            }
        }
    }

    private func nextZoomMode() {
        // Professional zoom cycling: Fit -> 1:1 -> 200% -> Fit (like Lightroom)
        let nextMode: ZoomMode
        switch currentZoomMode {
        case .fit:
            nextMode = .actual
        case .actual:
            nextMode = .double
        case .double:
            nextMode = .fit
        default:
            nextMode = .fit
        }
        setZoomMode(nextMode)
    }

    private func centerImage() {
        offset = .zero
        lastOffset = .zero
    }

    private func constrainOffset() {
        guard imageSize.width > 0 && imageSize.height > 0 else { return }

        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        // Calculate maximum allowed offset to keep image within bounds
        let maxOffsetX = max(0, (scaledImageSize.width - availableSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - availableSize.height) / 2)

        // Constrain offset
        let constrainedOffset = CGSize(
            width: max(-maxOffsetX, min(maxOffsetX, offset.width)),
            height: max(-maxOffsetY, min(maxOffsetY, offset.height))
        )

        offset = constrainedOffset
        lastOffset = constrainedOffset
    }

    private func loadImage() {
        guard let imageURL = selectedImageURL else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let cgImage = await RawImageProcessor.processRawImage(
                    from: imageURL,
                    options: processingOptions
                )

                await MainActor.run {
                    if let cgImage = cgImage {
                        self.image = cgImage
                        // Auto-fit to window by default (professional behavior)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.setZoomMode(.fit)
                        }
                    } else {
                        self.errorMessage = "Unsupported format or corrupted file"
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func formatImageInfo() -> String {
        guard let cgImage = image else { return "" }

        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent

        return "\(width) × \(height) • \(bitsPerComponent) bit"
    }
}

// MARK: - Professional Image View Component

struct ProfessionalImageView: View {
    let cgImage: CGImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var containerSize: CGSize
    let onDoubleClick: () -> Void

    @State private var magnificationValue: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            Image(cgImage, scale: 1.0, label: Text("Raw Image"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        // Professional magnification gesture
                        MagnifyGesture()
                            .onChanged { value in
                                let gestureScale = value.magnification
                                let newScale = scale * (gestureScale / magnificationValue)
                                // Professional zoom limits (like Lightroom: 6.25% to 3200%)
                                let clampedScale = max(0.0625, min(32.0, newScale))
                                scale = clampedScale
                                magnificationValue = gestureScale
                            }
                            .onEnded { _ in
                                magnificationValue = 1.0
                                constrainOffsetToBounds(in: geometry.size)
                            },

                        // Professional pan gesture with bounds checking
                        DragGesture()
                            .onChanged { value in
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                offset = constrainOffset(newOffset, in: geometry.size)
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                // Double-click to cycle zoom (professional behavior)
                .onTapGesture(count: 2) {
                    onDoubleClick()
                }
                .onAppear {
                    containerSize = geometry.size
                }
                .onChange(of: geometry.size) {
                    containerSize = geometry.size
                }
        }
    }

    private func constrainOffset(_ newOffset: CGSize, in geometrySize: CGSize) -> CGSize {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        // Calculate available space after accounting for UI
        let availableSize = CGSize(
            width: max(geometrySize.width - 32, 100),
            height: max(geometrySize.height - 32, 100)
        )

        // Calculate bounds
        let maxOffsetX = max(0, (scaledImageSize.width - availableSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - availableSize.height) / 2)

        return CGSize(
            width: max(-maxOffsetX, min(maxOffsetX, newOffset.width)),
            height: max(-maxOffsetY, min(maxOffsetY, newOffset.height))
        )
    }

    private func constrainOffsetToBounds(in geometrySize: CGSize) {
        offset = constrainOffset(offset, in: geometrySize)
        lastOffset = offset
    }
}

struct ImageViewerPane_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerPane(selectedImageURL: .constant(nil))
            .frame(width: 600, height: 400)
    }
}
