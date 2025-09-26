import CoreGraphics
import CoreImage
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

                                Text("Scale: \(Int(scale * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()

                                Button("Fit") {
                                    withAnimation(.easeOut) {
                                        fitImageToWindow(containerSize: geometry.size)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("1:1") {
                                    withAnimation(.easeOut) {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
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
                        self.imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                        // Auto-fit to window by default
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.fitImageToWindow(containerSize: CGSize(width: 800, height: 600))
                        }
                    } else {
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

        let scaleX = availableSize.width / imageSize.width
        let scaleY = availableSize.height / imageSize.height
        let fitScale = min(scaleX, scaleY, 1.0)  // Don't scale up beyond 100%

        scale = fitScale
        offset = .zero
        lastOffset = .zero
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
