# App Store Review Checklist

Before submitting to the Mac App Store, complete this checklist:

## Required Steps

### 1. Apple Developer Program
- [ ] Enroll in Apple Developer Program ($99/year)
  - https://developer.apple.com/programs/enroll/
  - Takes 24-48 hours for approval

### 2. App Icon
- [ ] Create 1024x1024 icon
- [ ] Export all required sizes:
  - 16x16, 16x16@2x
  - 32x32, 32x32@2x
  - 128x128, 128x128@2x
  - 256x256, 256x256@2x
  - 512x512, 512x512@2x
- [ ] Add icon to Asset Catalog in Xcode

### 3. Screenshots (Required Sizes)
- [ ] 13-inch MacBook Air (2560 x 1664)
- [ ] 14-inch MacBook Pro (3024 x 1964)
- [ ] 16-inch MacBook Pro (3456 x 2234)
- [ ] Take 3-5 screenshots showing key features:
  1. Treemap view scanning a folder
  2. Duplicate finder results
  3. Scan history with trends
  4. Disk overview
  5. Old files finder

### 4. Build & Archive
- [ ] Set version to 1.0.0
- [ ] Set build number to 1
- [ ] Set deployment target to macOS 14.0
- [ ] Enable Hardened Runtime
- [ ] Archive in Xcode (Product → Archive)
- [ ] Validate archive
- [ ] Upload to App Store Connect

### 5. App Store Connect
- [ ] Create new app listing
- [ ] Add app name, subtitle, description
- [ ] Add keywords
- [ ] Add screenshots
- [ ] Add app icon
- [ ] Set category (Utilities)
- [ ] Set pricing (Free or $4.99)
- [ ] Add privacy policy URL
- [ ] Add support URL

### 6. Privacy & Compliance
- [ ] Fill out App Privacy questionnaire
- [ ] Answer: No data collected (since we don't collect anything)
- [ ] Confirm no encryption export requirements
- [ ] Add age rating (4+)

### 7. Final Review
- [ ] Test on clean macOS install
- [ ] Verify all features work
- [ ] Check for crashes
- [ ] Review App Store Review Guidelines
- [ ] Submit for review

## Common Rejection Reasons (Avoid These)

1. **Crashes or bugs** — Test thoroughly
2. **Placeholder content** — Remove any test data
3. **Broken links** — Verify all URLs work
4. **Missing functionality** — All advertised features must work
5. **Privacy violations** — Be honest about data collection
6. **Poor performance** — App should be responsive
7. **Misleading description** — Description must match functionality

## Pricing Strategy

**Recommended: $4.99**
- Competitive with DaisyDisk ($9.99) and OmniDiskSweepy ($9.99)
- Low enough to impulse buy
- High enough to signal quality

**Alternative: Free with tip jar**
- Lower barrier to entry
- Tips can generate income
- Good for building user base first

## Marketing Plan

### Launch Week
1. Post on r/macapps
2. Post on MacRumors forums
3. Share on Twitter/X
4. Submit to Product Hunt

### Ongoing
1. Respond to all reviews
2. Fix bugs quickly
3. Add requested features
4. Update description with new features

## Links

- App Store Connect: https://appstoreconnect.apple.com
- Developer Program: https://developer.apple.com/programs/
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
