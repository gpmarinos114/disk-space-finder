import XCTest
@testable import DiskSpaceFinder

final class FileNodeTests: XCTestCase {

    func test_fileNode_init_hasCorrectProperties() {
        let node = FileNode(
            name: "test.txt",
            path: "/Users/test/test.txt",
            size: 1024,
            isDirectory: false,
            fileExtension: "txt",
            modificationDate: Date(),
            creationDate: Date()
        )

        XCTAssertEqual(node.name, "test.txt")
        XCTAssertEqual(node.path, "/Users/test/test.txt")
        XCTAssertEqual(node.size, 1024)
        XCTAssertFalse(node.isDirectory)
        XCTAssertEqual(node.fileExtension, "txt")
    }

    func test_fileNode_directory_hasChildren() {
        let child = FileNode(name: "child.txt", path: "/test/child.txt", size: 500, isDirectory: false)
        let parent = FileNode(
            name: "parent",
            path: "/test",
            size: 500,
            children: [child],
            isDirectory: true
        )

        XCTAssertEqual(parent.children.count, 1)
        XCTAssertEqual(parent.children.first?.name, "child.txt")
    }

    func test_fileNode_formattedSize_formatsCorrectly() {
        let node1 = FileNode(name: "a", path: "", size: 0, isDirectory: false)
        let node2 = FileNode(name: "b", path: "", size: 1024, isDirectory: false)
        let node3 = FileNode(name: "c", path: "", size: 1048576, isDirectory: false)

        XCTAssertEqual(node1.formattedSize, "Zero KB")
        XCTAssertTrue(node2.formattedSize.contains("1"))
        XCTAssertTrue(node3.formattedSize.contains("1"))
    }

    func test_fileNode_childCount_countsDescendants() {
        let grandchild = FileNode(name: "gc", path: "", size: 100, isDirectory: false)
        let child1 = FileNode(name: "c1", path: "", size: 100, children: [grandchild], isDirectory: true)
        let child2 = FileNode(name: "c2", path: "", size: 100, isDirectory: false)
        let parent = FileNode(name: "p", path: "", size: 300, children: [child1, child2], isDirectory: true)

        XCTAssertEqual(parent.childCount, 3)
    }

    func test_fileNode_sortedChildren_sortsBySizeDescending() {
        let small = FileNode(name: "small", path: "", size: 100, isDirectory: false)
        let large = FileNode(name: "large", path: "", size: 1000, isDirectory: false)
        let medium = FileNode(name: "medium", path: "", size: 500, isDirectory: false)
        let parent = FileNode(name: "p", path: "", size: 1600, children: [small, large, medium], isDirectory: true)

        let sorted = parent.sortedChildren(by: .sizeDescending)
        XCTAssertEqual(sorted.map(\.name), ["large", "medium", "small"])
    }

    func test_fileNode_sortedChildren_sortsBySizeAscending() {
        let small = FileNode(name: "small", path: "", size: 100, isDirectory: false)
        let large = FileNode(name: "large", path: "", size: 1000, isDirectory: false)
        let parent = FileNode(name: "p", path: "", size: 1100, children: [small, large], isDirectory: true)

        let sorted = parent.sortedChildren(by: .sizeAscending)
        XCTAssertEqual(sorted.map(\.name), ["small", "large"])
    }

    func test_fileNode_sortedChildren_sortsByName() {
        let alpha = FileNode(name: "Alpha", path: "", size: 100, isDirectory: false)
        let beta = FileNode(name: "Beta", path: "", size: 100, isDirectory: false)
        let parent = FileNode(name: "p", path: "", size: 200, children: [beta, alpha], isDirectory: true)

        let sorted = parent.sortedChildren(by: .nameAscending)
        XCTAssertEqual(sorted.map(\.name), ["Alpha", "Beta"])
    }
}
