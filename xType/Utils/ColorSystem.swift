import SwiftUI

// MARK: - Professional Color System for xType
struct AppColors {
    // MARK: - Text Colors with Better Contrast
    static let primaryText = Color.primary
    static let secondaryText = Color(.controlTextColor)
    static let tertiaryText = Color(.tertiaryLabelColor).opacity(0.8)
    static let mutedText = Color(.quaternaryLabelColor)
    
    // MARK: - Semantic Colors for Better UX
    static let accentColor = Color.accentColor
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
    
    // MARK: - Background Colors
    static let primaryBackground = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    
    // MARK: - Border Colors with Good Contrast
    static let lightBorder = Color(NSColor.separatorColor).opacity(0.6)
    static let mediumBorder = Color(NSColor.separatorColor)
    static let strongBorder = Color(NSColor.separatorColor).opacity(1.2)
    
    // MARK: - Category Colors (More Vibrant)
    struct Category {
        static let audio = Color(.systemPurple)
        static let video = Color(.systemBlue)
        static let image = Color(.systemTeal)
        static let text = Color(.systemOrange)
        static let archive = Color(.systemBrown)
        static let other = Color(.systemGray)
    }
    
    // MARK: - Interactive States
    static let hoverOverlay = Color.accentColor.opacity(0.1)
    static let pressedOverlay = Color.accentColor.opacity(0.2)
    
    // MARK: - Extension Tag Colors
    static let tagBackground = Color(NSColor.controlBackgroundColor).opacity(0.8)
    static let tagBorder = Color(NSColor.separatorColor).opacity(0.4)
    static let tagText = Color(.controlTextColor).opacity(0.9)  // Higher contrast than secondary
}

// MARK: - Typography System
struct AppTypography {
    // Main content
    static let title = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 14, weight: .medium)
    static let caption = Font.system(size: 12, weight: .medium)  // More weight for better readability
    static let micro = Font.system(size: 10, weight: .semibold)  // Increased weight
    
    // UI Elements
    static let buttonText = Font.system(size: 13, weight: .semibold)
    static let searchText = Font.system(size: 15, weight: .regular)
    static let statsNumber = Font.system(size: 20, weight: .bold, design: .rounded)
    static let statsLabel = Font.system(size: 14, weight: .semibold)  // Increased weight
}

// MARK: - Design System Constants
struct AppDesign {
    static let cornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 10
    static let cardCornerRadius: CGFloat = 16
    static let iconSize: CGFloat = 16
    static let smallIconSize: CGFloat = 12
    static let shadowRadius: CGFloat = 4
    static let borderWidth: CGFloat = 1.5
    static let selectBtnRadius: CGFloat = 4
}
