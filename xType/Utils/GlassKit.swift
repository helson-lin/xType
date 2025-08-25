import SwiftUI

// MARK: - Glass Background
struct GlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .controlBackgroundColor).opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Glow layer
            RadialGradient(
                colors: [Color.accentColor.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 500
            )
            .blendMode(.plusLighter)
            .ignoresSafeArea()

            // Subtle noise to break banding
            Color.clear
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [
                                Color.white.opacity(colorScheme == .light ? 0.03 : 0.06),
                                .clear
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .blur(radius: 10)
                        .allowsHitTesting(false)
                )
        }
    }
}

// MARK: - Glass Card Style
struct GlassCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 12
    var highlight: Bool = true
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colorScheme == .light ? AnyShapeStyle(Color(nsColor: .controlBackgroundColor)) : AnyShapeStyle(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(colors: [
                                    Color.white.opacity(colorScheme == .light ? 0.35 : 0.18),
                                    Color.white.opacity(0.06)
                                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.8
                            )
                    )
                    .overlay(
                        Group {
                            if highlight {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(LinearGradient(colors: [
                                        Color.white.opacity(0.18),
                                        Color.white.opacity(0.02)
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .blendMode(.overlay)
                                    .opacity(colorScheme == .light ? 0.5 : 0.35)
                            }
                        }
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .light ? 0.06 : 0.35), radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 12, highlight: Bool = true) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, highlight: highlight))
    }
}

// MARK: - Tilt Effect (gesture-driven)
struct TiltEffect: ViewModifier {
    @GestureState private var drag: CGSize = .zero
    var maxTilt: Double = 6
    var pressScale: CGFloat = 0.98
    func body(content: Content) -> some View {
        let tiltX = Double(-drag.height / 10).clamped(to: -maxTilt...maxTilt)
        let tiltY = Double(drag.width / 10).clamped(to: -maxTilt...maxTilt)
        return content
            .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(drag == .zero ? 1 : pressScale)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($drag) { value, state, _ in
                        state = value.translation
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: drag)
    }
}

extension View {
    func tiltEffect(maxTilt: Double = 6, pressScale: CGFloat = 0.98) -> some View {
        modifier(TiltEffect(maxTilt: maxTilt, pressScale: pressScale))
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    var tint: Color
    var cornerRadius: CGFloat = 12
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(tint.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .light ? 0.05 : 0.25), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
