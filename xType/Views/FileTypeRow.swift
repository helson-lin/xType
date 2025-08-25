import SwiftUI

struct FileTypeRow: View {
    let fileType: FileType
    let onChoose: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - file type info with category icon
            HStack(spacing: 12) {
                // Category icon with clean design
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: fileType.category.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileType.description)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                    
                    ExtensionChipsView(extensions: fileType.extensions)
                }
            }
            
            Spacer()
            
            // Right side - app info and button
            HStack(spacing: 16) {
                if let appName = fileType.defaultApp, let appURL = fileType.defaultAppURL {
                    HStack(spacing: 10) {
                        let image = NSWorkspace.shared.icon(forFile: appURL.path)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .frame(width: 32, height: 32)
                            
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appName)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.primaryText)
                                .lineLimit(1)
                            Text(NSLocalizedString("status.default.app", comment: "Default app"))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    .frame(minWidth: 130, alignment: .leading)
                } else {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "questionmark.app.dashed")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("status.no.app", comment: "Not set"))
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                            Text(NSLocalizedString("status.no.default.app", comment: "No default app"))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.tertiaryText)
                        }
                    }
                    .frame(minWidth: 130, alignment: .leading)
                }
                
                Button(action: onChoose) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text(NSLocalizedString("button.choose.app", comment: "Choose App"))
                            .font(AppTypography.caption)
                    }
                }
                .buttonStyle(GlassButtonStyle(tint: AppColors.infoColor))
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                } onPressingChanged: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                .fill(AnyShapeStyle(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(
                            isHovered
                            ? AppColors.accentColor.opacity(colorScheme == .light ? 0.30 : 0.50)
                            : (colorScheme == .light ? AppColors.lightBorder.opacity(0.5) : AppColors.mediumBorder.opacity(0.75)),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: (colorScheme == .light ? Color.black.opacity(0.04) : Color.black.opacity(0.38)),
                    radius: isHovered ? 7 : 4,
                    x: 0,
                    y: isHovered ? 3 : 2
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .tiltEffect(maxTilt: 4, pressScale: 0.985)
    }
    
    private var categoryColor: Color {
        switch fileType.category {
        case .audio:
            return AppColors.Category.audio
        case .video:
            return AppColors.Category.video
        case .image:
            return AppColors.Category.image
        case .text:
            return AppColors.Category.text
        case .archive:
            return AppColors.Category.archive
        case .other:
            return AppColors.Category.other
        }
    }
}

// Modern chips for extensions
struct ExtensionChipsView: View {
    let extensions: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(extensions.prefix(5), id: \.self) { ext in
                    Text("." + ext)
                        .font(AppTypography.micro)
                        .foregroundColor(AppColors.tagText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.tagBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(AppColors.tagBorder, lineWidth: 0.5)
                                )
                        )
                }
                
                if extensions.count > 5 {
                    Text("+\(extensions.count - 5)")
                        .font(AppTypography.micro)
                        .foregroundColor(AppColors.tertiaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.tagBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(AppColors.tagBorder, lineWidth: 0.5)
                                )
                        )
                }
            }
        }
        .frame(height: 24)
    }
}
