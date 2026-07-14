# Mac Disk Space Finder — Roadmap

## Phase 1: Core Foundation (Week 1-2)

### 1.1 Project Setup
- [x] Create Xcode project with SwiftUI + AppKit
- [x] Set minimum deployment target (macOS 14+)
- [x] Configure sandbox entitlements for file system access
- [x] Add usage descriptions in Info.plist for folder access

### 1.2 File System Scanner
- [x] Build recursive directory walker using `FileManager`
- [x] Collect file metadata: size, name, path, type, creation/modification date
- [x] Use `getResourceValues()` for efficient size collection
- [x] Handle permission-denied directories gracefully
- [x] Support scanning specific volumes (`/`, `/Volumes/*`)

### 1.3 Data Model
- [x] FileNode struct with all properties (name, path, size, children, isDirectory, fileExtension, dates)
- [x] FileCategory enum for file type classification
- [x] SortOption enum for sorting children

### 1.4 Background Processing
- [x] Run scans on background thread (Swift async/await)
- [x] Report progress via `@Published` properties
- [x] Allow cancel of in-progress scans
- [x] Live file counter during scan

---

## Phase 2: Visualizations (Week 3-4)

### 2.1 Treemap View (Primary)
- [x] Implement squarified treemap algorithm for optimal rectangle ratios
- [x] Render with SwiftUI `Canvas`
- [x] Color by file type (documents, media, code, etc.)
- [x] Size labels on blocks
- [x] Click to zoom into subdirectory
- [x] Breadcrumb navigation for current depth

### 2.2 Sunburst Chart
- [x] Concentric rings representing directory depth
- [x] Arc width proportional to file size
- [x] Click to drill down
- [x] Implement using SwiftUI `Canvas` with arc paths

### 2.3 Tree View (Sidebar)
- [x] Hierarchical list view
- [x] Columns: Name, Size, File Count, % of Parent
- [x] Sort by any column
- [x] Search/filter by name or extension

### 2.4 Bar/Pie Charts
- [x] Top 10 largest files/directories bar chart
- [x] File type distribution pie chart
- [x] Size distribution histogram
- [x] Use Swift Charts framework

---

## Phase 3: User Features (Week 5-6)

### 3.1 File Type Analysis
- [x] Categorize by extension (Media, Documents, Code, Archives, etc.)
- [x] Custom category definitions
- [x] Show breakdown per category with totals

### 3.2 Duplicate File Detection
- [x] Hash files (SHA256) for exact matches
- [x] Group duplicates with combined wasted space
- [x] Quick scan mode: match by size + name first
- [x] Wire up to main UI

### 3.3 Large/Old File Finder
- [x] Sort by size, find space hogs
- [ ] Filter by age (last accessed/modified)
- [ ] "Last opened" analysis for unused files

### 3.4 Quick Actions
- [x] Reveal in Finder
- [x] Move to Trash (with confirmation)
- [x] Delete from any view (treemap, tree, charts)
- [x] Open file
- [x] Copy path
- [ ] Compress folder

### 3.5 Scan History
- [ ] Save scan snapshots to disk (JSON/SQLite)
- [ ] Compare scans over time
- [ ] Show growth trends

---

## Phase 4: Polish & UX (Week 7-8)

### 4.1 UI/UX
- [x] Native macOS look with sidebar + detail split view
- [x] Dark/light mode support (automatic)
- [x] Drag-and-drop folders onto app to scan
- [x] Progress indicator during scan
- [x] Notification when scan completes
- [x] Keyboard shortcuts (⌘O open, ⌘. cancel, ⌘[ back)

### 4.2 Performance
- [ ] Incremental scanning (only re-scan changed directories)
- [x] Lazy child loading (load on demand when drilling down)
- [ ] Cache scan results to `~/Library/Caches`
- [ ] Use `DispatchSource` for file system monitoring

### 4.3 Disk Overview
- [x] Show all mounted volumes with usage bars
- [ ] APFS container visualization
- [x] Available vs used space

---

## Phase 5: Distribution (Week 9+)

### 5.1 Packaging
- [ ] Code signing with Apple Developer ID
- [ ] Notarization for Gatekeeper
- [ ] DMG or .app distribution
- [ ] Optional: Mac App Store submission

### 5.2 Extras
- [ ] Spotlight integration (metadata import)
- [ ] Menu bar widget for quick disk usage
- [x] Keyboard shortcuts throughout
- [ ] Export reports (CSV, PDF)

---

## Phase 6: Monetization

### 6.1 App Store Preparation
- [ ] Apple Developer Program enrollment ($99/year)
- [ ] App Store icon (1024x1024 + all sizes)
- [ ] App Store screenshots (6.5", 13" MacBook, 14", 16")
- [ ] App Store description and keywords
- [ ] Privacy policy page
- [ ] App Store review guidelines compliance
- [ ] In-app purchase or upfront pricing ($4.99-9.99)

### 6.2 Code Signing & Distribution
- [ ] Developer ID certificate
- [ ] Notarization with Apple
- [ ] DMG installer with custom background
- [ ] Auto-updater (Sparkle framework)
- [ ] Homebrew Cask formula

### 6.3 Landing Page & Marketing
- [ ] Marketing website (domain + hosting)
- [ ] Feature screenshots/GIFs
- [ ] Video demo (30-60 seconds)
- [ ] Product Hunt launch
- [ ] Reddit r/macapps post
- [ ] Twitter/X launch thread
- [ ] Hacker News Show HN

### 6.4 Premium Features (Paid Tier)
- [ ] Duplicate file finder UI (backend exists)
- [ ] Old/unused file finder
- [ ] Scan history & comparison over time
- [ ] Export reports (CSV, PDF)
- [ ] Menu bar widget
- [ ] Quick Look file previews
- [ ] Smart folders (saved searches)

### 6.5 Alternative Revenue Models
- [ ] Free basic + Pro upgrade ($9.99 one-time)
- [ ] Tip jar / coffee link
- [ ] GitHub Sponsors
- [ ] Enterprise site license

---

## Key Technical Decisions

| Decision | Status |
|----------|--------|
| UI Framework | SwiftUI + Canvas ✅ |
| Concurrency | Swift async/await ✅ |
| Min macOS | 14 Sonoma ✅ |
| Charts | Swift Charts framework ✅ |
| File hashing | CryptoKit for SHA256 ✅ |
| Storage | SQLite (not yet implemented) |

## GitHub Repository

https://github.com/gpmarinos114/disk-space-finder
