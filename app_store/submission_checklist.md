# DocLens — Legacy Submission Checklist

> Superseded by `release_plan_2026.md`. Do not create the lifetime product, use the old Bundle ID, or configure an external AI key from this document.

## App Store Connect Setup

### 1. Create the App Record
- [ ] Log in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Click + → New App
- [ ] Platform: iOS
- [ ] Name: **DocLens - AI Document Scanner**
- [ ] Primary Language: English
- [ ] Bundle ID: **com.doclens.app** (register in Certificates, IDs & Profiles first)
- [ ] SKU: **DOCLENS001**

### 2. App Information Tab
- [ ] Subtitle: **Scan. Extract. Understand.**
- [ ] Category: **Utilities** (primary) / **Productivity** (secondary)
- [ ] Content Rights: No third-party content
- [ ] Age Rating: **4+** (complete questionnaire — all NONE)

### 3. Pricing and Availability
- [ ] Price: **Free**
- [ ] Availability: All territories (or Japan + US at minimum)

### 4. In-App Purchases
Go to App Store Connect → Your App → In-App Purchases → (+)

**Product 1 — Monthly Subscription**
- [ ] Type: Auto-Renewable Subscription
- [ ] Reference Name: DocLens Pro Monthly
- [ ] Product ID: `com.doclens.app.pro.monthly`
- [ ] Subscription Group: Create new → "DocLens Pro"
- [ ] Duration: 1 Month
- [ ] Price: Tier 4 ($3.99 / ¥600)
- [ ] Free Trial: 3 days
- [ ] Localization EN: Display Name "DocLens Pro Monthly"
- [ ] Localization JA: 「DocLens Pro 月額プラン」

**Product 2 — Annual Subscription**
- [ ] Type: Auto-Renewable Subscription
- [ ] Reference Name: DocLens Pro Annual
- [ ] Product ID: `com.doclens.app.pro.annual`
- [ ] Subscription Group: DocLens Pro (same group)
- [ ] Duration: 1 Year
- [ ] Price: Tier 14 ($27.99 / ¥4,200)
- [ ] Free Trial: 7 days
- [ ] Mark as: Featured plan

**Product 3 — Lifetime**
- [ ] Type: Non-Consumable
- [ ] Reference Name: DocLens Lifetime
- [ ] Product ID: `com.doclens.app.lifetime`
- [ ] Price: Tier 23 ($34.99 / ¥5,400)

### 5. Version Information (1.0.0)
- [ ] What's New: paste `whats_new_en.txt` (EN) and `whats_new_ja.txt` (JA)
- [ ] Description EN: paste `description_en.txt`
- [ ] Description JA: paste `description_ja.txt`
- [ ] Keywords EN: `document scanner,ocr,pdf scanner,text recognition,ai scanner,receipt scan,contract scan,scan to text`
- [ ] Keywords JA: `スキャナー,OCR,文書スキャン,文字認識,AIスキャン,レシート読み取り,PDF作成,書類整理`
- [ ] Promotional Text EN: paste from metadata.json
- [ ] Support URL: https://github.com/Koki-coder-crypto/LynQ_backend/issues
- [ ] Privacy Policy URL: https://github.com/Koki-coder-crypto/LynQ_backend/blob/master/app_store/privacy_policy.html

### 6. App Privacy
- [ ] Data Collection: No
- [ ] Privacy Nutrition Label: all unchecked
  - Camera is used on-device only, never transmitted
  - Photos are used on-device only, never transmitted

### 7. Review Information
- [ ] First Name: Koki
- [ ] Last Name: Developer
- [ ] Email: kouki_1203@icloud.com
- [ ] Demo Account: Not required
- [ ] Notes: paste `review_notes.txt`

## Xcode Setup

### 8. Xcode Project
- [ ] Create new Xcode project: App / SwiftUI / Swift
- [ ] Bundle Identifier: `com.doclens.app`
- [ ] Deployment Target: iOS 17.0
- [ ] Add all Swift files from `ios_app/` to the project
- [ ] Add `Info.plist` entries:
  - NSCameraUsageDescription
  - NSPhotoLibraryUsageDescription
  - ANTHROPIC_API_KEY (add to build settings / xcconfig)

### 9. Capabilities (Signing & Capabilities tab)
- [ ] In-App Purchase — ON

### 10. App Icon
- [ ] Create 1024×1024 PNG app icon (teal document/lens icon on white/dark background)
- [ ] Add to Assets.xcassets → AppIcon

### 11. Screenshots (required)
- [ ] 6.7" iPhone (iPhone 15 Pro Max): minimum 3 screenshots
  1. Scan screen (camera active / importing)
  2. Document detail (AI summary + key points)
  3. Document library (multiple documents)
- [ ] Optional: 12.9" iPad

### 12. Build & Upload
- [ ] Product → Archive
- [ ] Distribute App → App Store Connect
- [ ] Upload and wait for processing (~10 min)
- [ ] Select build in App Store Connect

### 13. Submit for Review
- [ ] All sections show green checkmarks
- [ ] Click "Submit for Review"
- [ ] Review time: typically 24–72 hours

## Post-Approval
- [ ] Set release: Automatic or Manual
- [ ] Monitor reviewer follow-up emails
