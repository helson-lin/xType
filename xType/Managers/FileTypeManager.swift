import Foundation
import UniformTypeIdentifiers
import SwiftUI
import CoreServices

class FileTypeManager: ObservableObject {
    static let shared = FileTypeManager()
    
    @Published var fileTypes: [FileType] = []
    @Published var filteredFileTypes: [FileType] = []
    @Published var searchText: String = "" {
        didSet {
            filterFileTypes()
        }
    }
    @Published var categoryFilter: FileCategory? = nil {
        didSet {
            filterFileTypes()
        }
    }
    @Published var isLoading: Bool = false
    @Published var toastMessage: String? = nil
    
    private let userDefaultsKey = "com.xtype.filetypes"
    
    init() {
        loadFileTypes()
    }
    
    func resetSavedFileTypes() {
        // Clear saved data
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        // Reload file types
        loadFileTypes()
    }
    
    func refreshDefaultApps() {
        isLoading = true
        
        // Snapshot current types on main thread, compute off-main, publish on main
        let currentTypes = self.fileTypes
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var updatedTypes = currentTypes
            
            // Compute default app information off the main thread
            for i in 0..<updatedTypes.count {
                if let utType = UTType(updatedTypes[i].uti) {
                    let (defaultApp, defaultAppURL) = self.getDefaultApp(for: utType)
                    updatedTypes[i].defaultApp = defaultApp
                    updatedTypes[i].defaultAppURL = defaultAppURL
                }
            }
            
            // Publish updates on the main thread
            DispatchQueue.main.async {
                self.fileTypes = updatedTypes
                self.filterFileTypes()
                self.saveFileTypes()
                self.isLoading = false
                self.showToast(NSLocalizedString("toast.refresh.success", comment: "Refresh success"))
            }
        }
    }
    
    func loadFileTypes() {
        isLoading = true
        
        // Load from UserDefaults first
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            let decoder = JSONDecoder()
            do {
                let decoded = try decoder.decode([FileType].self, from: savedData)
                DispatchQueue.main.async {
                    self.fileTypes = decoded
                    self.filterFileTypes()
                    self.isLoading = false
                }
                return
            } catch {
                print("Error decoding saved file types: \(error)")
                // If decoding fails, reset the saved data
                resetSavedFileTypes()
                return
            }
        }
        
        // If no saved data, load system types
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var types = [FileType]()
            var processedUTIs = Set<String>()
            
            // Known file extensions to include
            let knownExtensions: [String] = [
                // Audio
                "mp3", "wav", "aac", "m4a", "flac", "aiff", "ogg", "wma", "m4b", "alac",
                // Video
                "mp4", "mov", "avi", "mkv", "flv", "wmv", "m4v", "mpeg", "mpg", "webm", "3gp", "m2ts",
                // Images
                "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "svg", "ico", "icns",
                // Documents
                "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "md", "html", "htm",
                // Archives
                "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "pkg", "iso", "cab", "arj", "lzh", "zipx"
            ]
            
            // Process known extensions first
            for ext in knownExtensions {
                guard let type = UTType(filenameExtension: ext),
                      !processedUTIs.contains(type.identifier) else { continue }
                
                processedUTIs.insert(type.identifier)
                
                if let fileType = self.createFileType(from: type) {
                    types.append(fileType)
                }
            }
            
            // Get all declared types that conform to common types
            let commonConformingTypes = [
                UTType.audio, .movie, .image, .text, .pdf, .archive, .zip, .data
            ].compactMap { $0 }
            
            for conformingType in commonConformingTypes {
                // First get types that conform to the current type
                let conformingTypes = UTType.types(tag: "*", tagClass: .filenameExtension, conformingTo: conformingType)
                
                for type in conformingTypes {
                    guard !processedUTIs.contains(type.identifier) else { continue }
                    processedUTIs.insert(type.identifier)
                    
                    if let fileType = self.createFileType(from: type) {
                        types.append(fileType)
                    }
                }
                
                // Also get the type itself if it's not already processed
                if !processedUTIs.contains(conformingType.identifier),
                   let fileType = self.createFileType(from: conformingType) {
                    processedUTIs.insert(conformingType.identifier)
                    types.append(fileType)
                }
            }
            
            // Remove duplicates and sort
            var uniqueTypes = [String: FileType]()
            for type in types {
                uniqueTypes[type.id] = type
            }
            
            let sortedTypes = Array(uniqueTypes.values).sorted { $0.description < $1.description }
            
            DispatchQueue.main.async {
                self.fileTypes = sortedTypes
                self.filterFileTypes()
                self.isLoading = false
                self.saveFileTypes()
            }
        }
    }
    
    func setDefaultApp(for fileType: FileType, appURL: URL) {
        guard let index = fileTypes.firstIndex(where: { $0.id == fileType.id }) else { return }
        
        let appName = appURL.deletingPathExtension().lastPathComponent
        
        // Update the file type with the new default app
        fileTypes[index].defaultApp = appName
        fileTypes[index].defaultAppURL = appURL
        
        // Update the filtered list if needed
        if let filteredIndex = filteredFileTypes.firstIndex(where: { $0.id == fileType.id }) {
            filteredFileTypes[filteredIndex].defaultApp = appName
            filteredFileTypes[filteredIndex].defaultAppURL = appURL
        }
        
        // Set the default application
        if let bundle = Bundle(url: appURL), let bundleIdentifier = bundle.bundleIdentifier {
            for ext in fileType.extensions {
                if let uti = UTType(filenameExtension: ext) {
                    if uti.isDeclared, !uti.isDynamic {
                        LSSetDefaultRoleHandlerForContentType(uti.identifier as CFString, .all, bundleIdentifier as CFString)
                    }
                }
            }
        }
        
        // Save changes
        saveFileTypes()
        
        // Show toast
        showToast(String(format: NSLocalizedString("toast.app.set", comment: "App set toast"), appName, fileType.description))
    }
    
    func setDefaultApp(for category: FileCategory, appURL: URL) {
        let appName = appURL.deletingPathExtension().lastPathComponent
        var updatedCount = 0
        
        for i in 0..<fileTypes.count {
            if fileTypes[i].category == category {
                fileTypes[i].defaultApp = appName
                fileTypes[i].defaultAppURL = appURL
                
                // Set the default application for each extension
                if let bundle = Bundle(url: appURL), let bundleIdentifier = bundle.bundleIdentifier {
                    for ext in fileTypes[i].extensions {
                        if let uti = UTType(filenameExtension: ext) {
                            if uti.isDeclared, !uti.isDynamic {
                                LSSetDefaultRoleHandlerForContentType(uti.identifier as CFString, .all, bundleIdentifier as CFString)
                            }
                        }
                    }
                }
                
                updatedCount += 1
            }
        }
        
        // Update filtered list
        filterFileTypes()
        
        // Save changes
        saveFileTypes()
        
        // Show toast
        showToast(String(format: NSLocalizedString("toast.batch.set", comment: "Batch set toast"), appName, category.displayName, updatedCount))
    }
    
    func categoryDisplayName(_ category: FileCategory?) -> String {
        return category?.displayName ?? NSLocalizedString("category.all", comment: "All categories")
    }
    
    private func filterFileTypes() {
        filteredFileTypes = fileTypes.filter { fileType in
            // Filter by search text
            let matchesSearch = searchText.isEmpty ||
                fileType.description.localizedCaseInsensitiveContains(searchText) ||
                fileType.extensions.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            // Filter by category
            let matchesCategory = categoryFilter == nil || fileType.category == categoryFilter
            
            return matchesSearch && matchesCategory
        }
    }
    
    private func saveFileTypes() {
        if let encoded = try? JSONEncoder().encode(fileTypes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            withAnimation {
                self?.toastMessage = nil
            }
        }
    }
    
    private func createFileType(from type: UTType) -> FileType? {
        guard type.isDeclared,
              !type.isDynamic else { return nil }
        
        // Get all extensions for this type
        let allExtensions = type.tags[.filenameExtension] ?? []
        let preferredExtension = type.preferredFilenameExtension ?? allExtensions.first
        
        // Skip if no extension is available
        guard let primaryExtension = preferredExtension, !primaryExtension.isEmpty else {
            return nil
        }
        
        // Get the default application for this file type
        let (defaultApp, defaultAppURL) = getDefaultApp(for: type)
        
        // Combine all extensions, ensuring no duplicates
        var extensions = Set(allExtensions)
        extensions.insert(primaryExtension)
        
        // Create a readable description
        var description = type.localizedDescription ?? type.identifier
        if description.hasPrefix("public.") {
            description = String(description.dropFirst(7))
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
        
        return FileType(
            id: type.identifier,
            description: description,
            extensions: Array(extensions).sorted(),
            uti: type.identifier,
            defaultApp: defaultApp,
            defaultAppURL: defaultAppURL
        )
    }
    
    private func getDefaultApp(for type: UTType) -> (String?, URL?) {
        var defaultApp: String? = nil
        var defaultAppURL: URL? = nil
        
        #if DEBUG
        let typeId = type.identifier
        let extensions = type.tags[.filenameExtension] ?? []
        print("🔍 Getting default app for UTI: \(typeId), extensions: \(extensions)")
        #endif
        
        // Method 1: Use LSCopyDefaultApplicationURLForContentType
        if let appURL = LSCopyDefaultApplicationURLForContentType(type.identifier as CFString, .all, nil)?.takeRetainedValue() as URL? {
            // Verify the app exists and is accessible
            if FileManager.default.fileExists(atPath: appURL.path) {
                defaultApp = appURL.deletingPathExtension().lastPathComponent
                defaultAppURL = appURL
                #if DEBUG
                print("✅ Method 1 success: \(defaultApp ?? "Unknown") at \(appURL.path)")
                #endif
                return (defaultApp, defaultAppURL)
            } else {
                #if DEBUG
                print("⚠️ Method 1 app not found at path: \(appURL.path)")
                #endif
            }
        }
        
        // Method 2: Try using file extension if UTI method failed
        if let primaryExtension = type.preferredFilenameExtension ?? type.tags[.filenameExtension]?.first {
            do {
                // Create a temporary file path to query the default app
                let tempURL = URL(fileURLWithPath: "/tmp/temp_file.\(primaryExtension)")
                
                if let appURL = NSWorkspace.shared.urlForApplication(toOpen: tempURL) {
                    // Verify the app exists and is accessible
                    if FileManager.default.fileExists(atPath: appURL.path) {
                        defaultApp = appURL.deletingPathExtension().lastPathComponent
                        defaultAppURL = appURL
                        #if DEBUG
                        print("✅ Method 2 success: \(defaultApp ?? "Unknown") at \(appURL.path)")
                        #endif
                        return (defaultApp, defaultAppURL)
                    } else {
                        #if DEBUG
                        print("⚠️ Method 2 app not found at path: \(appURL.path)")
                        #endif
                    }
                }
            } catch {
                #if DEBUG
                print("❌ Method 2 error: \(error.localizedDescription)")
                #endif
            }
        }
        
        // Method 3: Try LSCopyDefaultRoleHandlerForContentType as fallback
        if let bundleID = LSCopyDefaultRoleHandlerForContentType(type.identifier as CFString, .all)?.takeRetainedValue() as String? {
            #if DEBUG
            print("🆔 Method 3 found bundle ID: \(bundleID)")
            #endif
            
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                // Verify the app exists and is accessible
                if FileManager.default.fileExists(atPath: appURL.path) {
                    defaultApp = appURL.deletingPathExtension().lastPathComponent
                    defaultAppURL = appURL
                    #if DEBUG
                    print("✅ Method 3 success: \(defaultApp ?? "Unknown") at \(appURL.path)")
                    #endif
                } else {
                    #if DEBUG
                    print("⚠️ Method 3 app not found at path: \(appURL.path)")
                    #endif
                }
            } else {
                #if DEBUG
                print("⚠️ Method 3 could not find app for bundle ID: \(bundleID)")
                #endif
            }
        }
        
        // Method 4: Try alternative extension-based lookup
        if defaultApp == nil, let extensions = type.tags[.filenameExtension] {
            for ext in extensions {
                if let uti = UTType(filenameExtension: ext) {
                    if let appURL = LSCopyDefaultApplicationURLForContentType(uti.identifier as CFString, .all, nil)?.takeRetainedValue() as URL?,
                       FileManager.default.fileExists(atPath: appURL.path) {
                        defaultApp = appURL.deletingPathExtension().lastPathComponent
                        defaultAppURL = appURL
                        #if DEBUG
                        print("✅ Method 4 success for extension \(ext): \(defaultApp ?? "Unknown") at \(appURL.path)")
                        #endif
                        break
                    }
                }
            }
        }
        
        #if DEBUG
        if defaultApp == nil {
            print("❌ No default app found for UTI: \(typeId)")
        }
        #endif
        
        return (defaultApp, defaultAppURL)
    }
}
