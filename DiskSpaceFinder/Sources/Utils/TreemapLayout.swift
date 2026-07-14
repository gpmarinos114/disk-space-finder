import Foundation

struct TreemapItem: Identifiable {
    let id = UUID()
    let node: FileNode
    let rect: CGRect
    let depth: Int
    let percentage: Double
}

struct TreemapLayout {
    static func layout(items: [FileNode], in bounds: CGRect) -> [TreemapItem] {
        guard !items.isEmpty, bounds.width > 0, bounds.height > 0 else { return [] }

        let totalSize = items.reduce(Int64(0)) { $0 + $1.size }
        guard totalSize > 0 else { return [] }

        let normalizedItems = items.map { item -> (node: FileNode, normalizedSize: Double) in
            let proportion = Double(item.size) / Double(totalSize)
            let area = proportion * bounds.width * bounds.height
            return (node: item, normalizedSize: max(area, 1.0))
        }

        var result: [TreemapItem] = []
        squarify(
            items: normalizedItems.map { ($0.node, $0.normalizedSize) },
            bounds: bounds,
            depth: 0,
            result: &result
        )
        return result
    }

    private static func squarify(
        items: [(node: FileNode, size: Double)],
        bounds: CGRect,
        depth: Int,
        result: inout [TreemapItem]
    ) {
        guard !items.isEmpty else { return }

        let totalSize = items.reduce(0.0) { $0 + $1.size }

        if items.count == 1 {
            let item = items[0]
            let percentage = item.size > 0 ? item.size / totalSize : 0
            result.append(TreemapItem(
                node: item.node,
                rect: bounds,
                depth: depth,
                percentage: percentage
            ))
            return
        }

        let isWide = bounds.width >= bounds.height
        let length = isWide ? bounds.height : bounds.width

        var remaining = items
        var currentBounds = bounds

        while !remaining.isEmpty {
            let (row, rest) = findBestRow(items: remaining, length: length)

            let rowSize = row.reduce(0.0) { $0 + $1.size }
            let rowLength = (rowSize / totalSize) * (isWide ? bounds.width : bounds.height)

            var offset: CGFloat = 0
            for item in row {
                let itemLength = (item.size / rowSize) * length
                let rect: CGRect
                if isWide {
                    rect = CGRect(
                        x: currentBounds.origin.x,
                        y: currentBounds.origin.y + offset,
                        width: rowLength,
                        height: itemLength
                    )
                } else {
                    rect = CGRect(
                        x: currentBounds.origin.x + offset,
                        y: currentBounds.origin.y,
                        width: itemLength,
                        height: rowLength
                    )
                }

                let percentage = item.size > 0 ? item.size / totalSize : 0
                result.append(TreemapItem(
                    node: item.node,
                    rect: rect,
                    depth: depth,
                    percentage: percentage
                ))

                offset += itemLength
            }

            if isWide {
                currentBounds = CGRect(
                    x: currentBounds.origin.x + rowLength,
                    y: currentBounds.origin.y,
                    width: currentBounds.width - rowLength,
                    height: currentBounds.height
                )
            } else {
                currentBounds = CGRect(
                    x: currentBounds.origin.x,
                    y: currentBounds.origin.y + rowLength,
                    width: currentBounds.width,
                    height: currentBounds.height - rowLength
                )
            }

            remaining = rest
        }
    }

    private static func findBestRow(
        items: [(node: FileNode, size: Double)],
        length: CGFloat
    ) -> (row: [(node: FileNode, size: Double)], rest: [(node: FileNode, size: Double)]) {
        var bestRow: [(node: FileNode, size: Double)] = []
        var bestRest: [(node: FileNode, size: Double)] = items
        var bestAspect = CGFloat.greatestFiniteMagnitude

        for i in 1...items.count {
            let row = Array(items.prefix(i))
            let rest = Array(items.dropFirst(i))

            let aspect = worstAspectRatio(row: row, length: length)
            if aspect <= bestAspect {
                bestAspect = aspect
                bestRow = row
                bestRest = rest
            } else {
                break
            }
        }

        return (bestRow, bestRest)
    }

    private static func worstAspectRatio(
        row: [(node: FileNode, size: Double)],
        length: CGFloat
    ) -> CGFloat {
        let totalSize = row.reduce(0.0) { $0 + $1.size }
        let rowLength = totalSize / Double(length)

        var worst: CGFloat = 0
        for item in row {
            let itemLength = CGFloat(item.size / totalSize) * length
            let aspect = max(rowLength / itemLength, itemLength / rowLength)
            worst = max(worst, aspect)
        }
        return worst
    }
}
