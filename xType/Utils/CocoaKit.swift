import SwiftUI
import AppKit

// MARK: - NSVisualEffectView (Cocoa) background
public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blending: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(material: NSVisualEffectView.Material = .underWindowBackground,
                blending: NSVisualEffectView.BlendingMode = .behindWindow,
                state: NSVisualEffectView.State = .active) {
        self.material = material
        self.blending = blending
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = state
        view.isEmphasized = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
        nsView.state = state
    }
}

// MARK: - Window styler (transparent titlebar, fullSizeContentView, toolbar style)
public struct WindowConfigurator: NSViewRepresentable {
    public var titlebarTransparent: Bool = true
    public var fullSizeContent: Bool = true
    public var toolbarStyle: NSWindow.ToolbarStyle = .unifiedCompact

    public init(titlebarTransparent: Bool = true,
                fullSizeContent: Bool = true,
                toolbarStyle: NSWindow.ToolbarStyle = .unifiedCompact) {
        self.titlebarTransparent = titlebarTransparent
        self.fullSizeContent = fullSizeContent
        self.toolbarStyle = toolbarStyle
    }

    public func makeNSView(context: Context) -> NSView {
        let hosting = NSView()
        DispatchQueue.main.async {
            if let window = hosting.window {
                configure(window: window)
            }
        }
        return hosting
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            configure(window: window)
        }
    }

    private func configure(window: NSWindow) {
        window.titlebarAppearsTransparent = titlebarTransparent
        window.isOpaque = false
        window.backgroundColor = .clear
        window.toolbarStyle = toolbarStyle
        if fullSizeContent {
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
        }
    }
}

// MARK: - Cocoa-backed ScrollView with fine control
public struct CocoaScrollView<Content: View>: NSViewRepresentable {
    public var hasVerticalScroller: Bool = true
    public var hasHorizontalScroller: Bool = false
    public var verticalScrollElasticity: NSScrollView.Elasticity = .automatic
    public var horizontalScrollElasticity: NSScrollView.Elasticity = .none
    public var scrollerStyle: NSScroller.Style = .overlay
    public var contentInsets: NSEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    public var drawsBackground: Bool = false
    public var content: Content

    public init(hasVerticalScroller: Bool = true,
                hasHorizontalScroller: Bool = false,
                verticalScrollElasticity: NSScrollView.Elasticity = .automatic,
                horizontalScrollElasticity: NSScrollView.Elasticity = .none,
                scrollerStyle: NSScroller.Style = .overlay,
                contentInsets: NSEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0),
                drawsBackground: Bool = false,
                @ViewBuilder content: () -> Content) {
        self.hasVerticalScroller = hasVerticalScroller
        self.hasHorizontalScroller = hasHorizontalScroller
        self.verticalScrollElasticity = verticalScrollElasticity
        self.horizontalScrollElasticity = horizontalScrollElasticity
        self.scrollerStyle = scrollerStyle
        self.contentInsets = contentInsets
        self.drawsBackground = drawsBackground
        self.content = content()
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = drawsBackground
        scroll.hasVerticalScroller = hasVerticalScroller
        scroll.hasHorizontalScroller = hasHorizontalScroller
        scroll.scrollerStyle = scrollerStyle
        scroll.verticalScrollElasticity = verticalScrollElasticity
        scroll.horizontalScrollElasticity = horizontalScrollElasticity
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentInsets = contentInsets

        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        let docView = NSView()
        docView.translatesAutoresizingMaskIntoConstraints = false
        docView.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: docView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: docView.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: docView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: docView.bottomAnchor),
            hosting.widthAnchor.constraint(equalTo: docView.widthAnchor)
        ])

        scroll.documentView = docView
        return scroll
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        nsView.drawsBackground = drawsBackground
        nsView.hasVerticalScroller = hasVerticalScroller
        nsView.hasHorizontalScroller = hasHorizontalScroller
        nsView.scrollerStyle = scrollerStyle
        nsView.verticalScrollElasticity = verticalScrollElasticity
        nsView.horizontalScrollElasticity = horizontalScrollElasticity
        nsView.contentInsets = contentInsets

        if let docView = nsView.documentView,
           let hosting = docView.subviews.compactMap({ $0 as? NSHostingView<Content> }).first {
            hosting.rootView = content
        }
    }
}
