# Mac Disk Space Finder — Roadmap

## Phase 1: Core Foundation (Week 1-2)

### 1.1 Project Setup
- Create Xcode project with SwiftUI + AppKit
- Set minimum deployment target (macOS 13+ recommended)
- Configure sandbox entitlements for file system access
- Add usage descriptions in Info.plist for folder access

### 1.2 File System Scanner
- Build recursive directory walker using `FileManager`
- Collect file metadata: size, name, path, type, creation/modification date
- Use `stat()` or `getResourceValues()` for efficient size collection
- Handle symlinks, aliases, and permission-denied directories
- Support scanning specific volumes (`/`, `/Volumes/*`)

### 1.3 Data Model

```swift
FileNode {
    name: String
    path: URL
    size: Int64
    children: [FileNode]
    isDirectory: Bool
    fileExtension: String?
    modificationDate: Date?
}
```

### 1.4 Background Processing
- Run scans on background thread (`DispatchQueue` or Swift concurrency)
- Report progress via `AsyncStream` or `@Published` properties
- Allow cancel/pause of in-progress scans

---

## Phase 2: Visualizations (Week 3-4)

### 2.1 Treemap View (Primary)
- Implement squarified treemap algorithm for optimal rectangle ratios
- Render with SwiftUI `Canvas` or custom `NSView`
- Color by file type (documents, media, code, etc.)
- Size labels on blocks, percentage labels
- Click to zoom into subdirectory
- Breadcrumb navigation for current depth

### 2.2 Sunburst Chart
- Concentric rings representing directory depth
- Arc width proportional to file size
- Interactive: hover for details, click to drill down
- Implement using SwiftUI `Canvas` with arc paths

### 2.3 Tree View (Sidebar)
- Hierarchical `OutlineGroup` or custom disclosure view
- Columns: Name, Size, File Count, % of Parent
- Sort by any column
- Expand/collapse directories
- Search/filter by name or extension

### 2.4 Bar/Pie Charts
- Top 10 largest files/directories bar chart
- File type distribution pie chart
- Use Swift Charts framework (macOS 13+)

---

## Phase 3: User Features (Week 5-6)

### 3.1 File Type Analysis
- Categorize by extension (Media, Documents, Code, Archives, etc.)
- Custom category definitions
- Show breakdown per category with totals

### 3.2 Duplicate File Detection
- Hash files (MD5/SHA256) for exact matches
- Group duplicates with combined wasted space
- Quick scan mode: match by size + name first

### 3.3 Large/Old File Finder
- Sort by size, find space hogs
- Filter by age (last accessed/modified)
- "Last opened" analysis for unused files

### 3.4 Quick Actions
- Reveal in Finder
- Move to Trash (with confirmation)
- Open file
- Copy path
- Compress folder

### 3.5 Scan History
- Save scan snapshots to disk (JSON/SQLite)
- Compare scans over time
- Show growth trends

---

## Phase 4: Polish & UX (Week 7-8)

### 4.1 UI/UX
- Native macOS look with sidebar + detail split view
- Dark/light mode support
- Drag-and-drop folders onto app to scan
- Progress indicator during scan with ETA
- Notification when scan completes

### 4.2 Performance
- Incremental scanning (only re-scan changed directories)
- Memory-efficient streaming for large trees
- Cache scan results to `~/Library/Caches`
- Use `DispatchSource` for file system monitoring

### 4.3 Disk Overview
- Show all mounted volumes with usage bars
- APFS container visualization
- Available vs used vs purgeable space

---

## Phase 5: Distribution (Week 9+)

### 5.1 Packaging
- Code signing with Apple Developer ID
- Notarization for Gatekeeper
- DMG or .app distribution
- Optional: Mac App Store submission

### 5.2 Extras
- Spotlight integration (metadata import)
- Menu bar widget for quick disk usage
- Keyboard shortcuts throughout
- Export reports (CSV, PDF)

---

## Key Technical Decisions

| Decision | Recommendation |
|----------|----------------|
| UI Framework | SwiftUI + AppKit interop (Canvas for custom drawing) |
| Concurrency | Swift async/await + `AsyncStream` |
| Storage | SQLite via GRDB or SwiftData |
| Min macOS | 13 Ventura (for Swift Charts, newer SwiftUI) |
| Charts | Swift Charts framework |
| File hashing | `CryptoKit` for SHA256 |

## Open Source References

- **GrandPerspective** — treemap scanning logic (Objective-C)
- **OmniDiskSweepy** — UI patterns for disk cleanup
- **ncdu** — efficient directory traversal
- **squarify** — treemap layout algorithm
