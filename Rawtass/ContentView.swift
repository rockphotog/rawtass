import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedImageURL: URL?

    private let supportedTypes: [UTType] = [
        // RAW formats supported by LibRaw
        UTType(filenameExtension: "nef")!,  // Nikon RAW (including HE/HE*)
        UTType(filenameExtension: "nrw")!,  // Nikon RAW (compact)
        UTType(filenameExtension: "raf")!,  // Fujifilm RAW (including compressed)
        UTType(filenameExtension: "cr2")!,  // Canon RAW
        UTType(filenameExtension: "cr3")!,  // Canon RAW (newer)
        UTType(filenameExtension: "crw")!,  // Canon RAW (older)
        UTType(filenameExtension: "arw")!,  // Sony RAW
        UTType(filenameExtension: "srf")!,  // Sony RAW
        UTType(filenameExtension: "sr2")!,  // Sony RAW
        UTType(filenameExtension: "orf")!,  // Olympus RAW
        UTType(filenameExtension: "rw2")!,  // Panasonic RAW
        UTType(filenameExtension: "raw")!,  // Panasonic RAW
        UTType(filenameExtension: "rwl")!,  // Leica RAW
        UTType(filenameExtension: "dng")!,  // Adobe DNG
        UTType(filenameExtension: "pef")!,  // Pentax RAW
        UTType(filenameExtension: "erf")!,  // Epson RAW
        UTType(filenameExtension: "mrw")!,  // Minolta RAW
        UTType(filenameExtension: "3fr")!,  // Hasselblad RAW
        UTType(filenameExtension: "dcr")!,  // Kodak RAW
        UTType(filenameExtension: "kdc")!,  // Kodak RAW
        UTType(filenameExtension: "iiq")!,  // Phase One RAW
        UTType(filenameExtension: "x3f")!,  // Sigma RAW

        // Standard image formats
        .jpeg,  // JPEG
        .png,  // PNG
        .tiff,  // TIFF
        .bmp,  // BMP
        .gif,  // GIF
        .heic,  // HEIC (iOS/macOS)
        .webP,  // WebP
    ]

    var body: some View {
        HSplitView {
            // Left pane - File Browser
            FileBrowser(
                supportedTypes: supportedTypes,
                onFileSelected: { url in
                    selectedImageURL = url
                }
            )
            .frame(minWidth: 300, maxWidth: 500)

            // Right pane - Image Viewer
            ImageViewerPane(selectedImageURL: $selectedImageURL)
                .frame(minWidth: 400)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onDrop(of: supportedTypes, isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            // Start accessing the security-scoped resource
                            _ = url.startAccessingSecurityScopedResource()
                            self.selectedImageURL = url
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
