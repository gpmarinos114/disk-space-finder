import SwiftUI

struct SunburstView: View {
    let node: FileNode
    let onNodeSelected: (FileNode) -> Void

    @State private var maxDepth: Int = 4

    private let ringWidth: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            sunburstCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Text("Depth:")
                    .font(.caption)
                Picker("Depth", selection: $maxDepth) {
                    ForEach(2...6, id: \.self) { depth in
                        Text("\(depth)").tag(depth)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            .padding(12)
            .background(.bar)
        }
    }

    private var sunburstCanvas: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 - 10
            let calculatedRingWidth = min(ringWidth, maxRadius / CGFloat(maxDepth))

            drawSunburst(
                context: &context,
                node: node,
                center: center,
                innerRadius: 0,
                ringWidth: calculatedRingWidth,
                startAngle: .zero,
                endAngle: .degrees(360),
                depth: 0,
                maxDepth: maxDepth,
                maxRadius: maxRadius
            )
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let location = value.location
                    let center = CGPoint(x: 0, y: 0)
                    let dx = location.x - center.x
                    let dy = location.y - center.y
                    let _ = sqrt(dx * dx + dy * dy)
                }
        )
    }

    private func createArcPath(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Angle,
        endAngle: Angle
    ) -> Path {
        Path { path in
            path.addArc(
                center: center,
                radius: outerRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        }
    }

    private func drawSunburst(
        context: inout GraphicsContext,
        node: FileNode,
        center: CGPoint,
        innerRadius: CGFloat,
        ringWidth: CGFloat,
        startAngle: Angle,
        endAngle: Angle,
        depth: Int,
        maxDepth: Int,
        maxRadius: CGFloat
    ) {
        guard depth < maxDepth else { return }

        let outerRadius = min(innerRadius + ringWidth, maxRadius)
        guard outerRadius > innerRadius else { return }

        let color = colorForNode(node, depth: depth)
        let path = createArcPath(
            center: center,
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle
        )

        context.fill(path, with: .color(color.opacity(0.8)))
        context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)

        let sortedChildren = node.sortedChildren(by: .sizeDescending)
        let totalSize = max(node.size, 1)
        var currentAngle = startAngle
        let angleRange = endAngle.degrees - startAngle.degrees

        for child in sortedChildren {
            let proportion = Double(child.size) / Double(totalSize)
            let childAngle = angleRange * proportion
            let childEndAngle = currentAngle + .degrees(childAngle)

            if childAngle > 0.5 {
                let midRadius = (innerRadius + outerRadius) / 2
                let midAngle = currentAngle + .degrees(childAngle / 2)

                let arcLength = CGFloat(childAngle * .pi / 180) * midRadius
                if childAngle > 8 && arcLength > 30 {
                    let labelPos = CGPoint(
                        x: center.x + cos(midAngle.radians) * midRadius,
                        y: center.y + sin(midAngle.radians) * midRadius
                    )

                    let fontSize = min(11, max(8, ringWidth / 7))
                    let maxChars = Int(arcLength / (fontSize * 0.6))
                    let displayName = child.name.count > maxChars
                        ? String(child.name.prefix(max(0, maxChars - 1))) + "…"
                        : child.name

                    let nameText = Text(displayName)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(.white)
                    context.draw(nameText, at: labelPos)
                }

                drawSunburst(
                    context: &context,
                    node: child,
                    center: center,
                    innerRadius: outerRadius,
                    ringWidth: ringWidth,
                    startAngle: currentAngle,
                    endAngle: childEndAngle,
                    depth: depth + 1,
                    maxDepth: maxDepth,
                    maxRadius: maxRadius
                )
            }

            currentAngle = childEndAngle
        }
    }

    private func colorForNode(_ node: FileNode, depth: Int) -> Color {
        if node.isDirectory {
            let hue = Double(depth % 6) / 6.0
            return Color(hue: hue, saturation: 0.6, brightness: 0.7)
        }
        let category = FileCategory.categorize(fileExtension: node.fileExtension)
        switch category {
        case .documents: return .blue
        case .images: return .green
        case .video: return .purple
        case .audio: return .orange
        case .code: return .cyan
        case .archives: return .brown
        case .applications: return .red
        case .fonts: return .pink
        case .other: return .gray
        }
    }
}
