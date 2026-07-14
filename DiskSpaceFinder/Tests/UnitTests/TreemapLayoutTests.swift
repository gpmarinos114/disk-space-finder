import XCTest
@testable import DiskSpaceFinder

final class TreemapLayoutTests: XCTestCase {

    func test_layout_emptyItems_returnsEmpty() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let items = TreemapLayout.layout(items: [], in: bounds)
        XCTAssertTrue(items.isEmpty)
    }

    func test_layout_singleItem_fillsEntireBounds() {
        let node = FileNode(name: "test", path: "/test", size: 1000, isDirectory: false)
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let items = TreemapLayout.layout(items: [node], in: bounds)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.rect, bounds)
    }

    func test_layout_twoItems_splitsBySize() {
        let large = FileNode(name: "large", path: "/large", size: 900, isDirectory: false)
        let small = FileNode(name: "small", path: "/small", size: 100, isDirectory: false)
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let items = TreemapLayout.layout(items: [large, small], in: bounds)

        XCTAssertEqual(items.count, 2)

        let largeItem = items.first { $0.node.name == "large" }
        let smallItem = items.first { $0.node.name == "small" }

        XCTAssertNotNil(largeItem)
        XCTAssertNotNil(smallItem)

        let largeArea = largeItem!.rect.width * largeItem!.rect.height
        let smallArea = smallItem!.rect.width * smallItem!.rect.height

        XCTAssertTrue(largeArea > smallArea)
    }

    func test_layout_preservesTotalArea() {
        let nodes = (0..<5).map { i in
            FileNode(name: "file\(i)", path: "/\(i)", size: Int64((i + 1) * 1000), isDirectory: false)
        }
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let items = TreemapLayout.layout(items: nodes, in: bounds)

        let totalArea = items.reduce(CGFloat(0)) { $0 + $1.rect.width * $1.rect.height }
        let expectedArea = bounds.width * bounds.height

        XCTAssertEqual(totalArea, expectedArea, accuracy: 1.0)
    }

    func test_layout_zeroSizeBounds_returnsEmpty() {
        let node = FileNode(name: "test", path: "/test", size: 1000, isDirectory: false)
        let bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
        let items = TreemapLayout.layout(items: [node], in: bounds)

        XCTAssertTrue(items.isEmpty)
    }

    func test_layout_allZeroSizes_returnsEmpty() {
        let nodes = [
            FileNode(name: "a", path: "/a", size: 0, isDirectory: false),
            FileNode(name: "b", path: "/b", size: 0, isDirectory: false)
        ]
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let items = TreemapLayout.layout(items: nodes, in: bounds)

        XCTAssertTrue(items.isEmpty)
    }

    func test_layout_rectsDoNotOverlap() {
        let nodes = (0..<10).map { i in
            FileNode(name: "file\(i)", path: "/\(i)", size: Int64.random(in: 100...10000), isDirectory: false)
        }
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let items = TreemapLayout.layout(items: nodes, in: bounds)

        for i in 0..<items.count {
            for j in (i + 1)..<items.count {
                XCTAssertFalse(
                    items[i].rect.intersects(items[j].rect),
                    "Rects \(items[i].node.name) and \(items[j].node.name) overlap"
                )
            }
        }
    }
}
