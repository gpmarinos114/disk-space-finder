import XCTest
@testable import DiskSpaceFinder

final class FileCategoryTests: XCTestCase {

    func test_categorize_documents() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "pdf"), .documents)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "docx"), .documents)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "txt"), .documents)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "md"), .documents)
    }

    func test_categorize_images() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "jpg"), .images)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "png"), .images)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "heic"), .images)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "svg"), .images)
    }

    func test_categorize_video() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "mp4"), .video)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "mov"), .video)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "mkv"), .video)
    }

    func test_categorize_audio() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "mp3"), .audio)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "wav"), .audio)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "flac"), .audio)
    }

    func test_categorize_code() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "swift"), .code)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "py"), .code)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "js"), .code)
    }

    func test_categorize_archives() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "zip"), .archives)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "dmg"), .archives)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "tar"), .archives)
    }

    func test_categorize_applications() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "app"), .applications)
    }

    func test_categorize_fonts() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "ttf"), .fonts)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "otf"), .fonts)
    }

    func test_categorize_unknown_returnsOther() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "xyz"), .other)
        XCTAssertEqual(FileCategory.categorize(fileExtension: nil), .other)
    }

    func test_categorize_caseInsensitive() {
        XCTAssertEqual(FileCategory.categorize(fileExtension: "PDF"), .documents)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "JPG"), .images)
        XCTAssertEqual(FileCategory.categorize(fileExtension: "MP3"), .audio)
    }
}
