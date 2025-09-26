import SwiftUI
import UniformTypeIdentifiers

struct FileBrowser: View {
    @State private var currentDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    @State private var contents: [URL] = []
    @State private var selectedFile: URL?
    @State private var showingFilePicker = false

    let supportedTypes: [UTType]
    let onFileSelected: (URL) -> Void

    private let supportedExtensions = Set([
        "nef", "nrw", "raf", "cr2", "cr3", "crw", "arw", "srf", "sr2",
        "orf", "rw2", "raw", "rwl", "dng", "pef", "erf", "mrw", "3fr",
        "dcr", "kdc", "iiq", "x3f", "jpg", "jpeg", "png", "tiff", "tif",
        "bmp", "gif", "heic", "webp",
    ])

    var body: some View {
        VStack(spacing: 0) {
            // Navigation header
            HStack {
                Button {
                    navigateUp()
                } label: {
                    Image(systemName: "arrow.up")
                }
                .disabled(currentDirectory.path == "/")

                Button {
                    showingFilePicker = true
                } label: {
                    Image(systemName: "folder")
                }

                Spacer()

                Button {
                    refreshContents()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            // Current path
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(pathComponents, id: \.self) { component in
                        Button {
                            navigateToComponent(component)
                        } label: {
                            Text(
                                component.lastPathComponent.isEmpty
                                    ? "/" : component.lastPathComponent
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        if component != pathComponents.last {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 24)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // File list
            List(filteredContents, id: \.path, selection: $selectedFile) { url in
                FileRow(url: url, isSupported: isSupportedFile(url)) {
                    if url.hasDirectoryPath {
                        currentDirectory = url
                        refreshContents()
                    } else if isSupportedFile(url) {
                        onFileSelected(url)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 250)
        .onAppear {
            refreshContents()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    currentDirectory = url
                    refreshContents()
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }

    private var pathComponents: [URL] {
        var components: [URL] = []
        var current = currentDirectory

        while current.path != "/" {
            components.insert(current, at: 0)
            current = current.deletingLastPathComponent()
        }
        components.insert(URL(fileURLWithPath: "/"), at: 0)

        return components
    }

    private var filteredContents: [URL] {
        contents.sorted { url1, url2 in
            // Directories first, then files
            if url1.hasDirectoryPath != url2.hasDirectoryPath {
                return url1.hasDirectoryPath
            }
            // Then alphabetically
            return url1.lastPathComponent.localizedCaseInsensitiveCompare(url2.lastPathComponent)
                == .orderedAscending
        }
    }

    private func refreshContents() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: currentDirectory,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            contents = urls
        } catch {
            print("Error reading directory: \(error)")
            contents = []
        }
    }

    private func navigateUp() {
        currentDirectory = currentDirectory.deletingLastPathComponent()
        refreshContents()
    }

    private func navigateToComponent(_ component: URL) {
        currentDirectory = component
        refreshContents()
    }

    private func isSupportedFile(_ url: URL) -> Bool {
        guard !url.hasDirectoryPath else { return false }
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }
}

struct FileRow: View {
    let url: URL
    let isSupported: Bool
    let action: () -> Void

    @State private var fileSize: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .frame(width: 16)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundColor(isSupported || url.hasDirectoryPath ? .primary : .secondary)

                if let fileSize = fileSize {
                    Text(fileSize)
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondary)
                }
            }

            Spacer()

            if isSupported {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .onAppear {
            loadFileSize()
        }
    }

    private var iconName: String {
        if url.hasDirectoryPath {
            return "folder"
        }

        switch url.pathExtension.lowercased() {
        case "nef", "nrw": return "camera.macro.circle"
        case "raf": return "camera.circle"
        case "cr2", "cr3", "crw": return "camera.aperture"
        case "arw", "srf", "sr2": return "camera.shutter.button"
        case "dng": return "doc.badge.gearshape"
        case "jpg", "jpeg", "png", "tiff", "tif", "bmp", "gif", "heic", "webp": return "photo"
        default: return "doc"
        }
    }

    private var iconColor: Color {
        if url.hasDirectoryPath {
            return .blue
        } else if isSupported {
            return .primary
        } else {
            return .secondary
        }
    }

    private func loadFileSize() {
        guard !url.hasDirectoryPath else { return }

        DispatchQueue.global(qos: .utility).async {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? Int64 {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    let formattedSize = formatter.string(fromByteCount: size)

                    DispatchQueue.main.async {
                        self.fileSize = formattedSize
                    }
                }
            } catch {
                // Ignore file size loading errors
            }
        }
    }
}

struct FileBrowser_Previews: PreviewProvider {
    static var previews: some View {
        FileBrowser(
            supportedTypes: [.jpeg, .png],
            onFileSelected: { _ in }
        )
        .frame(width: 300, height: 500)
    }
}
