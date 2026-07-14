# Agents & QA Guidelines

## Testing Philosophy

Every feature must be fully tested before it is considered complete. No feature merges without passing all QA checks.

---

## QA Workflow

After building any feature, follow this checklist:

### 1. Unit Tests
- Write unit tests for all public functions and methods
- Test edge cases: empty inputs, nil values, very large inputs, invalid paths
- Aim for >80% code coverage on new code
- Run: `Cmd+U` in Xcode or `swift test` from CLI

### 2. Integration Tests
- Test that components work together correctly
- File scanner + data model integration
- Data model + view model bindings
- View model + SwiftUI view rendering

### 3. UI Tests
- Use XCTest UI testing for critical user flows
- Test: launch scan → see results → drill down → take action
- Test: switch between treemap, sunburst, and tree views
- Test: drag-and-drop folder onto app
- Test: cancel in-progress scan

### 4. Manual QA Checklist

Run through this after every feature:

- [ ] App launches without crashes
- [ ] Feature works as expected
- [ ] No memory leaks (check with Instruments)
- [ ] Performance acceptable on large directories (100k+ files)
- [ ] Dark mode renders correctly
- [ ] Light mode renders correctly
- [ ] Window resizes without layout issues
- [ ] Keyboard navigation works
- [ ] VoiceOver accessibility labels present
- [ ] No console errors or warnings
- [ ] Graceful handling of permission-denied directories
- [ ] Scan cancellation works mid-scan

### 5. Performance Testing
- Profile with Instruments (Time Allocations, Leaks, Allocations)
- Benchmark scan time on `/Users` directory
- Measure memory usage during scan of 500k+ files
- Verify UI stays responsive during background scan

---

## Test File Organization

```
DiskSpaceFinder/
├── Sources/
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/
│   └── Services/
└── Tests/
    ├── UnitTests/
    │   ├── ScannerTests.swift
    │   ├── FileNodeTests.swift
    │   ├── TreemapLayoutTests.swift
    │   └── DuplicateDetectorTests.swift
    ├── IntegrationTests/
    │   ├── ScanPipelineTests.swift
    │   └── ViewModelTests.swift
    └── UITests/
        ├── LaunchTests.swift
        ├── ScanFlowTests.swift
        └── VisualizationTests.swift
```

---

## Test Naming Convention

```
test_<method>_<scenario>_<expectedResult>
```

Examples:
- `test_scanDirectory_withEmptyFolder_returnsEmptyNode`
- `test_calculateSize_withNestedFiles_returnsTotalBytes`
- `test_treemapLayout_withSingleItem_fillsEntireRect`
- `test_duplicateDetection_withIdenticalFiles_groupsThem`

---

## CI/CD Commands

```bash
# Run all tests
swift test

# Run specific test file
swift test --filter ScannerTests

# Run with coverage
swift test --enable-code-coverage

# Build release
xcodebuild -scheme DiskSpaceFinder -configuration Release build
```

---

## QA Sign-Off Template

Before marking a feature complete, document:

```markdown
## Feature: [Name]

### Tests Written
- [ ] Unit tests: X tests, all passing
- [ ] Integration tests: X tests, all passing
- [ ] UI tests: X tests, all passing

### Manual QA
- [ ] All checklist items verified
- [ ] Tested on macOS version: ___
- [ ] Tested with X files/directories: ___

### Performance
- Scan time for /Users: ___s
- Peak memory usage: ___MB
- UI responsiveness: smooth / degraded

### Notes
- Any known issues or follow-ups
```

---

## Agent Instructions

When implementing features:

1. Write tests FIRST (TDD) or alongside implementation
2. Run full test suite after each change
3. Profile with Instruments if touching file system or rendering code
4. Verify accessibility with VoiceOver
5. Test with both small (<100 files) and large (100k+ files) directories
6. Never leave commented-out code or TODOs without a tracking issue
