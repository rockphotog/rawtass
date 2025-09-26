import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedImageURL: URL?
    @State private var showingFilePicker = false
    @State private var showingImageViewer = false
    @State private var recentFiles: [URL] = []

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
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.magnifyingglass")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 64))

                Text("Rawtass")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Fast RAW Image Viewer")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Professional RAW viewer with LibRaw integration")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(
                    "Supports 50+ RAW formats including Nikon HE/HE*, Fujifilm compressed, and all standard image formats"
                )
                .font(.caption)
                .foregroundStyle(.quaternary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)

            // Actions
            VStack(spacing: 16) {
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text("Open RAW Image")
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    openWithFinder()
                } label: {
                    HStack {
                        Image(systemName: "finder")
                        Text("Browse in Finder")
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            // Recent files
            if !recentFiles.isEmpty {
                Divider()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Files")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    LazyVStack(spacing: 8) {
                        ForEach(recentFiles, id: \.path) { url in
                            RecentFileRow(url: url) {
                                openImage(url)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            Spacer()

            // Status
            HStack(spacing: 20) {
                Label("Supports: NEF, RAF, CR2, CR3, ARW, DNG", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    openImage(url)
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            if let url = selectedImageURL {
                RawImageViewer(imageURL: url)
                    .frame(minWidth: 800, minHeight: 600)
            }
        }
        .onAppear {
            loadRecentFiles()
        }
        .onDrop(of: supportedTypes, isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private func openImage(_ url: URL) {
        // Start accessing the security-scoped resource
        _ = url.startAccessingSecurityScopedResource()

        selectedImageURL = url
        addToRecentFiles(url)
        showingImageViewer = true
    }

    private func openWithFinder() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = supportedTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                openImage(url)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            openImage(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    private func addToRecentFiles(_ url: URL) {
        recentFiles.removeAll { $0.path == url.path }
        recentFiles.insert(url, at: 0)
        recentFiles = Array(recentFiles.prefix(5))  // Keep only 5 recent files
        saveRecentFiles()
    }

    private func loadRecentFiles() {
        // Load recent files from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "RecentFiles"),
            let urls = try? JSONDecoder().decode([URL].self, from: data)
        {
            recentFiles = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: "RecentFiles")
        }
    }
}

struct RecentFileRow: View {
    let url: URL
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: fileIcon)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.body)
                        .lineLimit(1)

                    Text(url.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let fileSize = getFileSize() {
                    Text(fileSize)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    private var fileIcon: String {
        switch url.pathExtension.lowercased() {
        case "nef": return "camera.macro.circle"
        case "raf": return "camera.circle"
        case "cr2", "cr3": return "camera.aperture"
        case "arw": return "camera.shutter.button"
        case "dng": return "doc.badge.gearshape"
        default: return "photo"
        }
    }

    private func getFileSize() -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? Int64
        else {
            return nil
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
