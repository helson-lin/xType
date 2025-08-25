//
//  ContentView.swift
//  xType
//
//  Created by lin on 2025/8/24.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @StateObject private var fileTypeManager = FileTypeManager()
    @FocusState private var searchBarIsFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCategoryIndex: Int = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var pendingFileType: FileType? = nil
    @State private var selectedAppURL: URL? = nil
    @State private var showBatchSheet: Bool = false
    @State private var batchSelectedIDs: Set<String> = []
    @State private var batchSelectedAppURL: URL? = nil
    private let categoryOptions: [FileCategory] = [.audio, .video, .image, .text, .archive]
    
    // MARK: - Helper functions
    private func chooseApp(for fileType: FileType) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = String(format: NSLocalizedString("dialog.choose.app.for.type", comment: "Choose app for type"), fileType.description)
        if panel.runModal() == .OK, let appURL = panel.url {
            fileTypeManager.setDefaultApp(for: fileType, appURL: appURL)
        }
    }
    
    private func chooseAppForCategory(_ category: FileCategory) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = String(format: NSLocalizedString("dialog.choose.app.for.category", comment: "Choose app for category"), fileTypeManager.categoryDisplayName(category))
        if panel.runModal() == .OK, let appURL = panel.url {
            fileTypeManager.setDefaultApp(for: category, appURL: appURL)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Cocoa visual effect background (deeper system blur)
            VisualEffectBackground(material: .underWindowBackground, blending: .behindWindow, state: .active)
                .ignoresSafeArea()
            // Glass background overlay for glow/highlight
            GlassBackground()
            
            VStack(spacing: 20) {
                // Modern search bar (header)
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: AppDesign.iconSize, weight: .medium))
                        .foregroundColor(searchBarIsFocused ? AppColors.accentColor : AppColors.secondaryText)
                        .animation(.easeInOut(duration: 0.2), value: searchBarIsFocused)
                    
                    TextField(NSLocalizedString("search.placeholder", comment: "Search placeholder"), text: $fileTypeManager.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AppTypography.searchText)
                        .focused($searchBarIsFocused)
                    
                    if !fileTypeManager.searchText.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                fileTypeManager.searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.tertiaryText)
                                .opacity(0.9)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(NSLocalizedString("search.clear.help", comment: "Clear search help"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AnyShapeStyle(.regularMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppColors.lightBorder.opacity(0.9),
                                            AppColors.lightBorder.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(
                            // pseudo inner shadow
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(colorScheme == .light ? 0.03 : 0.15), lineWidth: 4)
                                .blur(radius: 2)
                                .mask(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                                )
                                .allowsHitTesting(false)
                        )
                        .shadow(
                            color: Color.black.opacity(colorScheme == .light ? 0.10 : 0.20),
                            radius: 6,
                            x: 0,
                            y: 4
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .offset(y: -min(0, scrollOffset) * 0.08) // subtle parallax for header
                
                VStack(spacing: 20) {
                    if fileTypeManager.isLoading {
                        VStack(spacing: 16) {
                            RefreshSpinner()
                            Text(NSLocalizedString("loading.message", comment: "Loading message"))
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                    } else {
                        // Modern toolbar
                        VStack(spacing: 12) {
                            // Top row - filters and stats
                            HStack(spacing: 16) {
                                // Category Filter - segmented control for better clarity
                                Picker("", selection: $selectedCategoryIndex) {
                                    Text(NSLocalizedString("category.all", comment: "All categories")).tag(0)
                                    ForEach(Array(categoryOptions.enumerated()), id: \.offset) { idx, category in
                                        Text(category.displayName).tag(idx + 1)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 420)
                                .onChange(of: selectedCategoryIndex) { newValue in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        if newValue == 0 {
                                            fileTypeManager.categoryFilter = nil
                                        } else {
                                            fileTypeManager.categoryFilter = categoryOptions[newValue - 1]
                                        }
                                    }
                                }
                                .onChange(of: fileTypeManager.categoryFilter) { newCategory in
                                    if let newCategory = newCategory, let idx = categoryOptions.firstIndex(of: newCategory) {
                                        selectedCategoryIndex = idx + 1
                                    } else {
                                        selectedCategoryIndex = 0
                                    }
                                }
                                .onAppear {
                                    if let current = fileTypeManager.categoryFilter, let idx = categoryOptions.firstIndex(of: current) {
                                        selectedCategoryIndex = idx + 1
                                    } else {
                                        selectedCategoryIndex = 0
                                    }
                                }
                                .padding(.horizontal,12)
                                
                                // Stats with modern design
                                HStack(spacing: 4) {
                                    Text("\(fileTypeManager.filteredFileTypes.count)")
                                        .font(AppTypography.statsNumber)
                                        .foregroundColor(AppColors.accentColor)
                                    Text(NSLocalizedString("fileTypes.count", comment: "File types count"))
                                        .font(AppTypography.statsLabel)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                // Batch operations with modern design
                                Button {
                                    // Start with no preselected items
                                    batchSelectedIDs = []
                                    batchSelectedAppURL = nil
                                    showBatchSheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.stack.3d.up")
                                            .font(.system(size: 12, weight: .medium))
                                        Text(NSLocalizedString("button.batch.setup", comment: "Batch setup"))
                                            .font(AppTypography.caption)
                                    }
                                }
                                .buttonStyle(GlassButtonStyle(tint: AppColors.accentColor))
                                .help(NSLocalizedString("button.batch.setup.help", comment: "Batch setup help"))

                                Spacer(minLength: 0)

                                // Refresh button with modern design
                                Button(action: { fileTypeManager.refreshDefaultApps() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .medium))
                                        Text(NSLocalizedString("button.refresh", comment: "Refresh"))
                                            .font(AppTypography.caption)
                                    }
                                }
                                .buttonStyle(GlassButtonStyle(tint: AppColors.infoColor))
                                .help(NSLocalizedString("button.refresh.help", comment: "Refresh help"))
                                .disabled(fileTypeManager.isLoading)

                                Button(action: { fileTypeManager.resetSavedFileTypes() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 12, weight: .medium))
                                        Text(NSLocalizedString("button.reset", comment: "Reset"))
                                            .font(AppTypography.caption)
                                    }
                                }
                                .buttonStyle(GlassButtonStyle(tint: AppColors.warningColor))
                                .help(NSLocalizedString("button.reset.help", comment: "Reset help"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AnyShapeStyle(.regularMaterial))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(colorScheme == .light ? AppColors.lightBorder.opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)

                            // Modern file type list
                            ScrollView {
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                                }
                                .frame(height: 0)
                                LazyVStack(spacing: 12) {
                                    ForEach(fileTypeManager.filteredFileTypes) { fileType in
                                        FileTypeRow(fileType: fileType) {
                                            // Open in-app sheet to choose application
                                            pendingFileType = fileType
                                            selectedAppURL = fileType.defaultAppURL
                                        }
                                        .padding(.horizontal, 20)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                    }
                                }
                                .padding(.vertical, 16)
                            }
                            .scrollIndicators(.hidden)
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                scrollOffset = value
                            }
                            .animation(.easeInOut(duration: 0.3), value: fileTypeManager.filteredFileTypes.count)
                        }
                    }
                }
                
                // Modern toast message
                if let message = fileTypeManager.toastMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.successColor)
                            .font(.system(size: AppDesign.iconSize, weight: .medium))
                        
                        Text(message)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.primaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thickMaterial)
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fileTypeManager.toastMessage != nil)
                    .zIndex(1)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        // Configure NSWindow appearance via Cocoa
        .background(WindowConfigurator())
        .sheet(item: $pendingFileType) { fileType in
            ChooseAppSheet(
                fileType: fileType,
                selectedAppURL: $selectedAppURL,
                onConfirm: { url in
                    fileTypeManager.setDefaultApp(for: fileType, appURL: url)
                    // Cleanup
                    pendingFileType = nil
                    selectedAppURL = nil
                },
                onCancel: {
                    // Cleanup
                    pendingFileType = nil
                    selectedAppURL = nil
                }
            )
            .frame(minWidth: 460, minHeight: 260)
        }
        .sheet(isPresented: $showBatchSheet) {
            BatchChooseSheet(
                title: NSLocalizedString("sheet.batch.title", comment: "Batch sheet title"),
                allFileTypes: fileTypeManager.filteredFileTypes,
                selectedIDs: $batchSelectedIDs,
                selectedAppURL: $batchSelectedAppURL,
                onConfirm: { appURL, ids in
                    // Apply to selected file types
                    let map = Dictionary(uniqueKeysWithValues: fileTypeManager.fileTypes.map { ($0.id, $0) })
                    for id in ids {
                        if let ft = map[id] { fileTypeManager.setDefaultApp(for: ft, appURL: appURL) }
                    }
                    showBatchSheet = false
                    batchSelectedIDs.removeAll()
                    batchSelectedAppURL = nil
                },
                onCancel: {
                    showBatchSheet = false
                    batchSelectedIDs.removeAll()
                    batchSelectedAppURL = nil
                }
            )
            .frame(minWidth: 560, minHeight: 420)
        }
    }
}

#if DEBUG
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
#endif

// MARK: - Choose App Sheet
struct ChooseAppSheet: View {
        let fileType: FileType
        @Binding var selectedAppURL: URL?
        var onConfirm: (URL) -> Void
        var onCancel: () -> Void
        @State private var showImporter = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text(String(format: NSLocalizedString("sheet.choose.app.title", comment: "Choose app sheet title"), fileType.description))
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                }
                .padding(.bottom, 4)

                // Current selection panel
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                            .frame(width: 56, height: 56)
                        if let url = selectedAppURL {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "questionmark.app")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        if let url = selectedAppURL {
                            Text(url.deletingPathExtension().lastPathComponent)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.primaryText)
                            Text(url.path)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.tertiaryText)
                                .lineLimit(1)
                        } else {
                            Text(NSLocalizedString("sheet.no.app.selected", comment: "No app selected"))
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                            Text(NSLocalizedString("sheet.select.app.instruction", comment: "Select app instruction"))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.tertiaryText)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AnyShapeStyle(.ultraThinMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.lightBorder.opacity(0.6), lineWidth: 1)
                        )
                )

                // Action buttons
                HStack {
                    Button {
                        showImporter = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .medium))
                            Text(NSLocalizedString("button.browse.app", comment: "Browse apps"))
                                .font(AppTypography.caption)
                        }
                    }
                    .buttonStyle(GlassButtonStyle(tint: AppColors.infoColor))
                    .fileImporter(isPresented: $showImporter, allowedContentTypes: [.application], allowsMultipleSelection: false) { result in
                        switch result {
                        case .success(let urls):
                            selectedAppURL = urls.first
                        case .failure:
                            break
                        }
                    }

                    Spacer()

                    Button(NSLocalizedString("button.cancel", comment: "Cancel")) {
                        onCancel()
                    }
                    .buttonStyle(GlassButtonStyle(tint: AppColors.warningColor))

                    Button(NSLocalizedString("button.confirm", comment: "OK")) {
                        if let url = selectedAppURL {
                            onConfirm(url)
                        }
                    }
                    .buttonStyle(GlassButtonStyle(tint: AppColors.successColor))
                    .disabled(selectedAppURL == nil)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
}

// Category Chip Helper
private func categoryChip(category: FileCategory, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
    Button(action: onTap) {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .medium))
            Text(category.displayName)
                .font(AppTypography.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AnyShapeStyle(AppColors.accentColor.opacity(0.15)) : AnyShapeStyle(.regularMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? AppColors.accentColor : AppColors.lightBorder.opacity(0.5), lineWidth: 1)
                )
        )
    }
    .buttonStyle(.plain)
}

// MARK: - Batch Choose Sheet
struct BatchChooseSheet: View {
        let title: String
        let allFileTypes: [FileType]
        @Binding var selectedIDs: Set<String>
        @Binding var selectedAppURL: URL?
        var onConfirm: (URL, Set<String>) -> Void
        var onCancel: () -> Void
        @State private var showImporter = false
        @State private var searchText: String = ""
        @State private var selectedCategory: FileCategory? = nil

        private var filtered: [FileType] {
            let byCategory = allFileTypes.filter { selectedCategory == nil || $0.category == selectedCategory }
            let key = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            guard !key.isEmpty else { return byCategory }
            return byCategory.filter { ft in
                ft.description.lowercased().contains(key) ||
                ft.extensions.joined(separator: ",").lowercased().contains(key)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text(title)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Text(String(format: NSLocalizedString("sheet.selected.count", comment: "Selected count"), selectedIDs.count))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }

                // Search
                // Category chips (single-select)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FileCategory.allCases, id: \.self) { cat in
                            categoryChip(category: cat, isSelected: selectedCategory == cat) {
                                if selectedCategory == cat { selectedCategory = nil } else { selectedCategory = cat }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(NSLocalizedString("search.file.types", comment: "Search file types"), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(AppTypography.body)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AnyShapeStyle(.ultraThinMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.lightBorder.opacity(0.6), lineWidth: 1)
                        )
                )

                // Selection list
                VStack(spacing: 8) {
                    HStack {
                        Button(NSLocalizedString("button.select.all", comment: "Select all")) {
                            selectedIDs = Set(filtered.map { $0.id })
                        }
                        .buttonStyle(GlassButtonStyle(tint: AppColors.infoColor))
                        Button(NSLocalizedString("button.deselect.all", comment: "Deselect all")) {
                            selectedIDs.removeAll()
                        }
                        .buttonStyle(GlassButtonStyle(tint: AppColors.warningColor))
                        Spacer()
                    }
                    .padding(.bottom, 4)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filtered) { ft in
                                HStack(spacing: 12) {
                                    // Checkbox
                                    Toggle(isOn: Binding(
                                        get: { selectedIDs.contains(ft.id) },
                                        set: { isOn in
                                            if isOn { selectedIDs.insert(ft.id) } else { selectedIDs.remove(ft.id) }
                                        }
                                    )) { EmptyView() }
                                    .toggleStyle(.checkbox)
                                    .labelsHidden()

                                    // Icon and text
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.regularMaterial)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "doc")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ft.description)
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.primaryText)
                                        Text(ft.extensions.joined(separator: ", "))
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.tertiaryText)
                                    }
                                    Spacer()

                                    // Current default app display
                                    HStack(spacing: 6) {
                                        if let url = ft.defaultAppURL {
                                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                        Text(ft.defaultApp ?? ft.defaultAppURL?.deletingPathExtension().lastPathComponent ?? NSLocalizedString("status.no.app", comment: "Not set"))
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(AnyShapeStyle(.ultraThinMaterial))
                                            .overlay(
                                                Capsule()
                                                    .stroke(AppColors.lightBorder.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AnyShapeStyle(.ultraThinMaterial))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.lightBorder.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(minHeight: 180)
                }

                // App picker and actions
                HStack(spacing: 12) {
                    Button {
                        showImporter = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "app.badge")
                                .font(.system(size: 12, weight: .medium))
                            Text(selectedAppURL == nil ? NSLocalizedString("button.choose.app", comment: "Choose App"): selectedAppURL!.deletingPathExtension().lastPathComponent)
                                .font(AppTypography.caption)
                        }
                    }
                    .buttonStyle(GlassButtonStyle(tint: AppColors.infoColor))
                    .fileImporter(isPresented: $showImporter, allowedContentTypes: [.application], allowsMultipleSelection: false) { result in
                        if case .success(let urls) = result { selectedAppURL = urls.first }
                    }

                    if let app = selectedAppURL {
                        HStack(spacing: 6) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                .resizable()
                                .frame(width: 18, height: 18)
                            Text(app.path)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.tertiaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button(NSLocalizedString("button.cancel", comment: "Cancel")) { onCancel() }
                        .buttonStyle(GlassButtonStyle(tint: AppColors.warningColor))
                    Button(NSLocalizedString("button.confirm", comment: "OK")) {
                        if let app = selectedAppURL { onConfirm(app, selectedIDs) }
                    }
                    .buttonStyle(GlassButtonStyle(tint: AppColors.successColor))
                    .disabled(selectedAppURL == nil || selectedIDs.isEmpty)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
}

// MARK: - Smooth Refresh Spinner
struct RefreshSpinner: View {
        @State private var rotate = false
        var body: some View {
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor.opacity(0.2),
                            Color.accentColor.opacity(0.8),
                            Color.accentColor.opacity(0.2)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotate)
                .onAppear { rotate = true }
                .accessibilityLabel(NSLocalizedString("spinner.loading", comment: "Loading"))
        }
    }
    
    // MARK: - Scroll Offset Preference
private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
