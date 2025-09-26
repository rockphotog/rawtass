import SwiftUI
import CoreImage

struct RawImageViewer: View {
    let imageURL: URL
    @State private var image: CGImage?
    @State private var isLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var processingOptions = RawProcessingOptions.default
    @State private var showControls = true
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea(.all)
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Processing RAW image...")
                            .foregroundColor(.white)
                            .font(.title3)
                        
                        Text(imageURL.lastPathComponent)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("Failed to load image")
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        Text(errorMessage)
                            .foregroundColor(.gray)
                            .font(.body)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            loadImage()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let cgImage = image {
                    ZoomableImageView(
                        cgImage: cgImage,
                        scale: $scale,
                        offset: $offset,
                        lastOffset: $lastOffset
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
                
                // Controls overlay
                if showControls && !isLoading {
                    VStack {
                        // Top controls
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Text(imageURL.lastPathComponent)
                                .foregroundColor(.white)
                                .font(.headline)
                                .shadow(color: .black, radius: 1)
                            
                            Spacer()
                            
                            Menu {
                                Button("Fit to Window") {
                                    withAnimation(.easeOut) {
                                        resetZoomAndPan()
                                    }
                                }
                                
                                Button("Actual Size (100%)") {
                                    withAnimation(.easeOut) {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                                
                                Divider()
                                
                                Button("Show in Finder") {
                                    NSWorkspace.shared.selectFile(imageURL.path, inFileViewerRootedAtPath: "")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom controls
                        HStack {
                            Text(formatImageInfo())
                                .foregroundColor(.white)
                                .font(.caption)
                                .shadow(color: .black, radius: 1)
                            
                            Spacer()
                            
                            Text("Scale: \(Int(scale * 100))%")
                                .foregroundColor(.white)
                                .font(.caption)
                                .shadow(color: .black, radius: 1)
                        }
                        .padding()
                    }
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }
        .onAppear {
            loadImage()
        }
        .keyboardShortcut(.escape, modifiers: []) {
            dismiss()
        }
    }
    
    private func loadImage() {
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
                        self.resetZoomAndPan()
                    } else {
                        self.errorMessage = "Unsupported raw format or corrupted file"
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    private func resetZoomAndPan() {
        // Calculate fit-to-window scale
        guard let cgImage = image else { return }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let containerSize = CGSize(width: 800, height: 600) // This should be actual container size
        
        let scaleX = containerSize.width / imageSize.width
        let scaleY = containerSize.height / imageSize.height
        let fitScale = min(scaleX, scaleY, 1.0) // Don't scale up beyond 100%
        
        scale = fitScale
        offset = .zero
        lastOffset = .zero
    }
    
    private func formatImageInfo() -> String {
        guard let cgImage = image else { return "" }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = cgImage.colorSpace?.name ?? "Unknown"
        let bitsPerComponent = cgImage.bitsPerComponent
        
        return "\(width) × \(height) • \(bitsPerComponent) bit • \(colorSpace)"
    }
}

struct ZoomableImageView: View {
    let cgImage: CGImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    
    var body: some View {
        Image(cgImage, scale: 1.0, label: Text("Raw Image"))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    // Zoom gesture
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = scale * value
                            // Limit zoom between 10% and 1000%
                            if newScale >= 0.1 && newScale <= 10.0 {
                                scale = newScale
                            }
                        },
                    
                    // Pan gesture
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            )
    }
}

#Preview {
    // This would need a sample raw image file for testing
    Text("RawImageViewer Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}