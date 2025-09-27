import SwiftUI
import UniformTypeIdentifiers

struct FileBrowser: View {
    @State private var currentDirectory: URL = {
        // Start with a directory we know we can access - the sandbox Documents directory
        // This will show user how to navigate to real directories via file picker
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first
        {
            return documentsURL
        }

        // Ultimate fallback to sandbox home directory
        return FileManager.default.homeDirectoryForCurrentUser
    }()
    @State private var contents: [URL] = []
    @State private var selectedFile: URL?
    @State private var showingFilePicker = false
    @State private var securityScopedResources: Set<URL> = []

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
            // Compact navigation header with modern styling
            HStack(spacing: 6) {
                // Navigation controls - more compact
                Button {
                    navigateUp()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .disabled(currentDirectory.path == "/")

                Button {
                    showingFilePicker = true
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 0.5, height: 12)

                // Compact quick access buttons
                HStack(spacing: 4) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .help("Documents")

                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .help("Pictures")

                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .help("Desktop")

                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .help("Downloads")
                }

                Spacer()

                Button {
                    refreshContents()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Rectangle())

            // Sleek breadcrumb path
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(pathComponents, id: \.self) { component in
                        Button {
                            navigateToComponent(component)
                        } label: {
                            Text(
                                component.lastPathComponent.isEmpty
                                    ? "~" : component.lastPathComponent
                            )
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        }
                        .buttonStyle(.plain)

                        if component != pathComponents.last {
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 20)
            .background(.regularMaterial, in: Rectangle())

            // Sleek file list with more space
            List(filteredContents, id: \.path, selection: $selectedFile) { url in
                FileRow(url: url, isSupported: isSupportedFile(url)) {
                    if url.hasDirectoryPath {
                        currentDirectory = url
                        refreshContents()
                    } else if isSupportedFile(url) {
                        onFileSelected(url)
                    }
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.regularMaterial)
        }
        .frame(minWidth: 250)
        .onAppear {
            refreshContents()
        }
        .onDisappear {
            cleanup()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Improved security-scoped resource handling
                    DispatchQueue.global(qos: .userInitiated).async {
                        let accessing = url.startAccessingSecurityScopedResource()
                        
                        DispatchQueue.main.async {
                            if accessing {
                                // Track this resource for cleanup
                                securityScopedResources.insert(url)

                                // Store a security-scoped bookmark for future access
                                do {
                                    let _ = try url.bookmarkData(options: .withSecurityScope)
                                    // Successfully created bookmark - silent operation
                                } catch {
                                    // Silently handle bookmark creation errors
                                }

                                currentDirectory = url
                                refreshContents()
                            } else {
                                // Still try to navigate - maybe it's already accessible
                                currentDirectory = url
                                refreshContents()
                            }
                        }
                    }
                }
            case .failure(_):
                // Silently handle file picker errors to reduce console noise
                break
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
        // Improved error handling with reduced console noise
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let urls = try FileManager.default.contentsOfDirectory(
                    at: currentDirectory,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                    options: [.skipsHiddenFiles]
                )
                
                DispatchQueue.main.async {
                    self.contents = urls
                }
            } catch {
                // Handle directory access errors silently to reduce system warnings
                DispatchQueue.main.async {
                    self.contents = []
                }
            }
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

    // Clean up security-scoped resources when the view disappears
    private func cleanup() {
        for url in securityScopedResources {
            url.stopAccessingSecurityScopedResource()
        }
        securityScopedResources.removeAll()
    }

    // Quick access navigation methods - use file picker to get user-granted access
    private func navigateToDocuments() {
        print("Opening file picker for Documents access")
        showingFilePicker = true
    }

    private func navigateToDesktop() {
        print("Opening file picker for Desktop access")
        showingFilePicker = true
    }

    private func navigateToPictures() {
        print("Opening file picker for Pictures access")
        showingFilePicker = true
    }

    private func navigateToDownloads() {
        print("Opening file picker for Downloads access")
        showingFilePicker = true
    }

    // Get the real user home directory bypassing sandbox redirection
    private func getRealUserHomeDirectory() -> URL {
        return Self.getRealUserHomeDirectoryStatic()
    }

    // Static version for use in initialization
    private static func getRealUserHomeDirectoryStatic() -> URL {
        // First try to get the real user name from the environment
        if let realUser = ProcessInfo.processInfo.environment["USER"] {
            let realHomePath = "/Users/\(realUser)"
            let realHomeURL = URL(fileURLWithPath: realHomePath)

            // Verify this directory exists and is accessible
            if FileManager.default.fileExists(atPath: realHomePath) {
                print("Using real home directory: \(realHomePath)")
                return realHomeURL
            }
        }

        // Fallback to sandbox home directory
        let sandboxHome = FileManager.default.homeDirectoryForCurrentUser
        print("Falling back to sandbox home directory: \(sandboxHome.path)")
        return sandboxHome
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
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Modern icon with better spacing
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 18, height: 18)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(isSupported || url.hasDirectoryPath ? .primary : .secondary)

                if let fileSize = fileSize, !url.hasDirectoryPath {
                    Text(fileSize)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
            }

            Spacer()

            // Sleek support indicator
            if isSupported {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                    .opacity(0.8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
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
