import CoreGraphics
import CoreImage
import Foundation
import SwiftUI

struct ImageViewerPane: View {
    @Binding var selectedImageURL: URL?
    @State private var image: CGImage?
    @State private var isLoading = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var processingOptions = RawProcessingOptions()
    @State private var errorMessage: String?
    @State private var imageSize: CGSize = .zero
    @State private var baseScale: CGFloat = 1.0  // The base scale applied by SwiftUI's .fit
    @State private var isInFitMode: Bool = true  // Track current mode for display

    // Calculate the effective scale for display purposes
    // Always show scale relative to fit-to-window as the baseline (100%)
    private var displayScale: Int {
        if baseScale > 0 {
            return Int((scale / baseScale) * 100)
        } else {
            return 100
        }
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
                            // Image info bar
                            HStack {
                                Text(imageURL.lastPathComponent)
                                    .font(.headline)
                                    .lineLimit(1)

                                Spacer()

                                Text(formatImageInfo())
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Divider()
                                    .frame(height: 20)

                                Text("Scale: \(displayScale)%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()

                                Button("Fit") {
                                    print("DEBUG: Fit button pressed, current scale: \(scale)")
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        // Reset to fit mode - always works regardless of current zoom
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                        isInFitMode = true
                                    }
                                    // Update baseScale after animation
                                    fitImageToWindow(containerSize: geometry.size)
                                    print(
                                        "DEBUG: After fit - scale: \(scale), display: \(displayScale)%"
                                    )
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("1:1") {
                                    print("DEBUG: 1:1 button pressed, current scale: \(scale)")
                                    withAnimation(.easeOut) {
                                        setActualSize(containerSize: geometry.size)
                                    }
                                    print("DEBUG: After setActualSize, scale: \(scale)")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))

                            Divider()

                            // Image view
                            ZoomableImageView(
                                cgImage: cgImage,
                                scale: $scale,
                                offset: $offset,
                                lastOffset: $lastOffset
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .background(Color.black)
                            .onAppear {
                                // Auto-fit to window when image first appears
                                fitImageToWindow(containerSize: geometry.size)
                            }
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
            }
        }
    }

    private func loadImage() {
        guard let imageURL = selectedImageURL else { return }

        print("DEBUG: Starting to load image: \(imageURL.path)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                print("DEBUG: Processing image with RawImageProcessor...")
                let cgImage = await RawImageProcessor.processRawImage(
                    from: imageURL,
                    options: processingOptions
                )

                await MainActor.run {
                    if let cgImage = cgImage {
                        print(
                            "DEBUG: Successfully loaded image: \(cgImage.width)x\(cgImage.height)")
                        self.image = cgImage
                        self.imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                        // Auto-fit to window by default - will be called when geometry is available
                    } else {
                        print("DEBUG: Failed to load image - RawImageProcessor returned nil")
                        self.errorMessage = "Unsupported format or corrupted file"
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func fitImageToWindow(containerSize: CGSize) {
        guard let cgImage = image else { return }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let availableSize = CGSize(
            width: max(containerSize.width - 32, 100),  // Account for padding
            height: max(containerSize.height - 100, 100)  // Account for header and padding
        )

        // Calculate what scale SwiftUI's .fit would apply
        let scaleX = availableSize.width / imageSize.width
        let scaleY = availableSize.height / imageSize.height
        let swiftUIFitScale = min(scaleX, scaleY)

        // Update base scale for percentage calculations
        baseScale = swiftUIFitScale

        print(
            "DEBUG: fitImageToWindow - Updated baseScale to \(baseScale), current scale: \(scale), display: \(displayScale)%"
        )
    }

    private func setActualSize(containerSize: CGSize) {
        guard let cgImage = image else { return }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let availableSize = CGSize(
            width: max(containerSize.width - 32, 100),  // Account for padding
            height: max(containerSize.height - 100, 100)  // Account for header and padding
        )

        // Calculate what scale SwiftUI's .fit would apply
        let scaleX = availableSize.width / imageSize.width
        let scaleY = availableSize.height / imageSize.height
        let swiftUIFitScale = min(scaleX, scaleY)

        // Always update base scale
        baseScale = swiftUIFitScale

        // For 1:1 (actual size), we want to show each image pixel as one screen pixel
        // Since SwiftUI already applies fit scaling, we counteract it: scale = 1.0 / fitScale
        // BUT limit this to reasonable values (max 500% zoom)
        let actualSizeScale = 1.0 / swiftUIFitScale
        scale = min(actualSizeScale, 5.0)  // Cap at 500% to avoid extreme zoom
        offset = .zero
        lastOffset = .zero
        isInFitMode = false  // Mark as 1:1 mode

        print(
            "DEBUG: setActualSize - Image: \(Int(imageSize.width))x\(Int(imageSize.height)), Available: \(Int(availableSize.width))x\(Int(availableSize.height))"
        )
        print(
            "DEBUG: setActualSize - fitScale: \(swiftUIFitScale), actualScale: \(actualSizeScale), final scale: \(scale), display: \(displayScale)%"
        )
    }

    private func formatImageInfo() -> String {
        guard let cgImage = image else { return "" }

        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent

        return "\(width) × \(height) • \(bitsPerComponent) bit"
    }
}

struct ImageViewerPane_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerPane(selectedImageURL: .constant(nil))
            .frame(width: 600, height: 400)
    }
}
