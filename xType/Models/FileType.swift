import Foundation
import UniformTypeIdentifiers

struct FileType: Identifiable, Codable, Equatable {
    let id: String
    let description: String
    let extensions: [String]
    let uti: String
    var defaultApp: String?
    var defaultAppURL: URL?
    
    // Custom coding keys to handle URL encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case id, description, extensions, uti, defaultApp, defaultAppURL
    }
    
    init(id: String, description: String, extensions: [String], uti: String, defaultApp: String? = nil, defaultAppURL: URL? = nil) {
        self.id = id
        self.description = description
        self.extensions = extensions
        self.uti = uti
        self.defaultApp = defaultApp
        self.defaultAppURL = defaultAppURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        description = try container.decode(String.self, forKey: .description)
        extensions = try container.decode([String].self, forKey: .extensions)
        uti = try container.decode(String.self, forKey: .uti)
        defaultApp = try container.decodeIfPresent(String.self, forKey: .defaultApp)
        
        // Decode URL from string
        if let urlString = try container.decodeIfPresent(String.self, forKey: .defaultAppURL) {
            defaultAppURL = URL(string: urlString)
        } else {
            defaultAppURL = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(description, forKey: .description)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(uti, forKey: .uti)
        try container.encodeIfPresent(defaultApp, forKey: .defaultApp)
        
        // Encode URL as string
        if let url = defaultAppURL {
            try container.encode(url.absoluteString, forKey: .defaultAppURL)
        }
    }
    
    var category: FileCategory {
        guard let type = UTType(uti) ?? UTType(filenameExtension: extensions.first ?? "") else {
            return .other
        }
        
        if type.conforms(to: .audio) {
            return .audio
        } else if type.conforms(to: .movie) || type.conforms(to: .video) {
            return .video
        } else if type.conforms(to: .image) {
            return .image
        } else if type.conforms(to: .text) || type.conforms(to: .plainText) || type.conforms(to: .rtf) || type.conforms(to: .rtfd) {
            return .text
        } else if type.conforms(to: .archive) || type.conforms(to: .zip) || type.conforms(to: .gzip) || type.conforms(to: .bz2) {
            return .archive
        } else if let filenameExtension = extensions.first?.lowercased() {
            // Additional archive formats check by extension
            let archiveExtensions: Set<String> = ["rar", "7z", "tar", "dmg", "pkg", "iso", "cab", "arj", "lzh", "zipx"]
            if archiveExtensions.contains(filenameExtension) {
                return .archive
            }
        }
        
        return .other
    }
    
    static func == (lhs: FileType, rhs: FileType) -> Bool {
        return lhs.id == rhs.id
    }
}

enum FileCategory: String, CaseIterable, Codable {
    case audio = "audio"
    case video = "video"
    case image = "image"
    case text = "text"
    case archive = "archive"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .audio: return NSLocalizedString("category.audio", comment: "Audio category")
        case .video: return NSLocalizedString("category.video", comment: "Video category")
        case .image: return NSLocalizedString("category.image", comment: "Image category")
        case .text: return NSLocalizedString("category.text", comment: "Text category")
        case .archive: return NSLocalizedString("category.archive", comment: "Archive category")
        case .other: return NSLocalizedString("category.other", comment: "Other category")
        }
    }
    
    var iconName: String {
        switch self {
        case .audio: return "music.note"
        case .video: return "film"
        case .image: return "photo"
        case .text: return "doc.text"
        case .archive: return "archivebox"
        case .other: return "doc"
        }
    }
}
