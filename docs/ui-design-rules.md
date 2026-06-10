# NoSMS (MustAuth) UI 設計規則 — AI 輔助開發指南

> **暫存位置**：本文件目前放在 `docs/`，待確認後可移至 `.cursor/rules/ui-design.mdc` 作為 Cursor 持久規則，以減少每次對話重複描述 UI 慣例的 token 消耗。

---

## 1. 目的與使用方式

### 1.1 給 AI 的指令

修改或新增 UI 時，**先讀本文件**，再只開啟相關的 1～3 個檔案。不要從零描述整頁樣式，**對齊下方「參考畫面」**即可。

### 1.2 給開發者的 Prompt 模板（省 token）

```
任務：[一句話描述]
參考：[檔名，如 SecuritySettingsView]
只改：[檔名列表]
不做：[例如不重寫 ViewModel、不新增 Pod、不改 pbxproj]
狀態：需支援 loading / empty / error（刪除不需要的）
```

### 1.3 分階段交付

1. **結構**：layout、navigation、資料綁定  
2. **樣式**：對齊 design tokens 與參考 View  
3. **互動**：alert、toast、手勢、動畫  

每階段只改指定檔案，避免一次生成整個功能模組。

---

## 2. 技術約束

| 項目 | 規則 |
|------|------|
| UI 框架 | **新功能一律 SwiftUI**；勿新增 UIKit ViewController（除非 bridging 無法避免） |
| 架構 | **MVVM**：View 只負責呈現；業務邏輯在 ViewModel |
| 狀態管理 | ViewModel 用 `@StateObject`（擁有者）或 `@ObservedObject`（子 View）；全域鎖定用既有 `AppLockViewModel`、`GestureLockViewModel` |
| 顏色 | **必須**用 `Color(UIColor.xxx)`，定義於 `NoSMS/Common/Extension/UIColor+Extension.swift`；禁止硬編 `#RGB` 或 `Color(red:green:blue:)`（既有 `getColor(red:98,green:112,blue:255)` 除外） |
| 依賴 | 不新增 SnapKit、第三方 UI 庫；Toast、Segment、PatternLock、CircleProgress 用專案內建元件 |
| 語言 | 使用者可見文案使用**繁體中文** |
| App 名稱 | 導航列標題顯示 **MustAuth**（首頁）；子頁用功能名稱（如「安全設置」） |

---

## 3. Design Tokens

### 3.1 語意色（SwiftUI 用法：`Color(UIColor.xxx)`）

| Token | UIColor 名稱 | 用途 |
|-------|-------------|------|
| 主列表背景 | `tokenListTableViewBackgroundColor` | 首頁、列表、底部 sheet |
| 頁面背景（深） | `tokenListBackgroundColor` | 設定類全屏背景 |
| 首頁空狀態背景 | `homePageBackgroundColor` | Empty state 全屏 |
| 搜尋框背景 | `tokenListSearchTextFieldBackgroundColor` | Search bar |
| 側邊選單背景 | `menuBackgroundColor` | SideMenu 寬 290 |
| 手動輸入 / 鎖屏背景 | `manuallyTOTPBackgroundColor` | RootContainer 鎖屏、JoinManuallyTOTP |
| 分享列表背景 | `optShareBackgroundColor` | ShareOTPListView |
| 關於頁背景 | `versionUpdateBackgroundColor` | AboutView |
| WebView 背景 | `webViewBackgroundColor` | WebContentView |
| 主文字（issuer） | `tokenListIssuerColor` | 帳號 issuer、標題級文字 |
| 次文字（name） | `tokenListNameColor` / `tokenListAccountColor` | 帳號名稱 |
| OTP 數字 | `manuallyTOTPTextSelectedColor` | 驗證碼 monospaced 數字 |
| 倒數環 / 強調 | `tokenListTimerColor` | CircleProgressView、刷新按鈕 |
| 開關 / 連線 accent | `manuallyTOTPSwitchColor` | Toggle tint、PatternLock、置頂 swipe |
| Segment 選中 | `customSegmentControlEnableTextColor` | CustomSegmentControl |
| Segment 未選 | `customSegmentControlDisnableTextColor` | CustomSegmentControl |
| Segment 底線 | `customSegmentControlUnderLineColor` | CustomSegmentControl |
| 主按鈕（實心） | `homePageButtonBackgroundColor` + `homePageButtonBroderColor` | CTA 描邊按鈕 |
| 匯出啟用 | `exportOTPEnableTextColor` | ShareOTPList 底部按鈕 |
| 匯出禁用 | `exportOTPDisableTextColor` | ShareOTPList 底部按鈕 disabled |
| Web 重試按鈕 | `webViewReloadButtonColor` | WebContentView 錯誤態 |

### 3.2 字級

| 用途 | 樣式 |
|------|------|
| 導航標題 | `.font(.system(size: 18, weight: .bold))`，`.foregroundColor(.white)` |
| Section header | `.font(.system(size: 12))` |
| Row 主標 | `.font(.system(size: 16, weight: .bold))` + `tokenListIssuerColor` |
| Row 副標 | `.font(.system(size: 13))` + `tokenListNameColor` |
| OTP 數字 | `.font(.system(size: 26, weight: .semibold, design: .monospaced))`，`tracking(2)` |
| 一般正文 | `.font(.system(size: 15))` 或 `.font(.system(size: 16))` |
| 說明 / 次要 | `.font(.system(size: 14))`，`.foregroundColor(.gray)` |
| Toast | `.font(.system(size: 14, weight: .medium))`，白字 |
| 側欄項目 | `.font(.system(size: 16, weight: .medium))`，白字 |

### 3.3 間距與圓角

| Token | 值 | 用途 |
|-------|-----|------|
| 水平邊距 | `16`（少數用 `15`、`20`） | 列表、卡片、按鈕 |
| Row 垂直 padding | `12` | TokenRowView |
| 設定 row 高度 | `56`～`63` | SecuritySettings、SideMenu |
| 小圓角 | `6`～`8` | 按鈕、搜尋框 |
| 卡片圓角 | `10` | 設定區塊、匯出按鈕 |
| Sheet 圓角 | `16` | 底部選單 overlay |
| 主按鈕高度 | `42`～`48` | CTA、刪除列 |

### 3.4 遮罩與動畫

- 半透明遮罩：`Color.black.opacity(0.4)`  
- 側欄 / Toast 動畫：`.easeOut(duration: 0.25)`  
- Segment 切換：`.spring(response: 0.3, dampingFraction: 0.75)`  
- 側欄滑入：`.transition(.move(edge: .leading))`

---

## 4. 可重用元件目錄

修改 UI 時**優先 reuse**，禁止 duplicate 相同行為的元件。

| 元件 | 路徑 | 用途 |
|------|------|------|
| `TokenRowView` | `NoSMS/TokenList/TokenRowView.swift` | OTP 列表 row（複製、置頂 swipe、刪除） |
| `CustomSegmentControl` | `NoSMS/Common/SwiftUIComponents/CustomSegmentControl.swift` | 分組 Tab（「全部」+ groups） |
| `ToastModifier` / `.toast()` | `NoSMS/Common/SwiftUIComponents/ToastView.swift` | 複製成功等短提示 |
| `CircleProgressView` | `NoSMS/Common/SwiftUIComponents/CircleProgressView.swift` | OTP 倒數環 |
| `PatternLockView` | `NoSMS/Common/SwiftUIComponents/PatternLockView.swift` | 手勢解鎖 3×3 |
| `SideMenuView` | `NoSMS/Navigation/SideMenuView.swift` | 側邊選單（290pt） |
| `WebContentView` | `NoSMS/Web/WebViewContainer.swift` | 隱私權、幫助中心 Web 頁 |
| `QRCodeGenerator` | `NoSMS/Common/SwiftUIComponents/QRCodeGenerator.swift` | QR 產生 |

---

## 5. 頁面模板與參考畫面

新增畫面時，**選最接近的模板**，只描述與模板的差異。

### 5.1 主列表頁（搜尋 + Segment + List）

**參考**：`TokenListView.swift`、`ShareOTPListView.swift`

```
ZStack {
  Color(UIColor.tokenListTableViewBackgroundColor).edgesIgnoringSafeArea(.all)
  VStack(spacing: 0) {
    // searchBar: HStack + magnifyingglass + TextField + cornerRadius(8)
    // CustomSegmentControl（若有 groups）
    // List 或 emptyStateView
    // 可選：底部固定 CTA Button
  }
}
NavigationView + .toolbar（白 icon）
.toast(isPresented:message:)  // 若需複製反馈
```

### 5.2 設定 / 選項頁（卡片式 rows）

**參考**：`SecuritySettingsView.swift`

```
ZStack {
  Color(UIColor.tokenListBackgroundColor).edgesIgnoringSafeArea(.all)
  VStack {
    headerSection（icon + 說明文字）
    VStack(spacing: 0) { rows... Divider().background(Color.white.opacity(0.1)) }
      .background(Color(UIColor.tokenListTableViewBackgroundColor))
      .cornerRadius(10)
      .padding(.horizontal, 16)
    Spacer()
  }
}
.navigationBarTitle(..., displayMode: .inline)
.navigationBarBackButtonHidden(true)
.toolbar { 自訂 chevron.left 返回，.foregroundColor(.white) }
```

Row 模式：左 label（白字 16pt）+ 右 Toggle / 狀態文字 + chevron。

### 5.3 子頁（Logo + 資訊）

**參考**：`AboutView.swift`

- 全屏背景 `versionUpdateBackgroundColor`  
- Logo `100×100`，版本文字 15pt medium  
- 升級按鈕：高度 42、圓角 6、stroke 邊框  

### 5.4 Web 內容頁

**參考**：`WebContentView` in `WebViewContainer.swift`

- 直接使用 `WebContentView(title:urlString:)` 或包一層 `PrivacyPolicyView` / `HelpCenterView`  
- 必須處理 loading（ProgressView +「內容加載中…」）與 error（wifi.exclamationmark + 重新加載）  

### 5.5 底部 Sheet / 選單 Overlay

**參考**：`TokenListView.addMenuOverlay`、`SideMenuView`

```
ZStack {
  Color.black.opacity(0.4).onTapGesture { dismiss }
  VStack { Spacer(); content.frame(height: ~250).cornerRadius(16) }
}
```

### 5.6 Empty State

**參考**：`TokenListView.emptyStateView`

- Logo 置中（180×180 或 100×100）  
- 灰色說明文字 `.multilineTextAlignment(.center)`  
- 底部 CTA「開始設置」類按鈕  

### 5.7 鎖屏 / 全屏 Overlay

**參考**：`RootContainerView.swift`

- 背景 `manuallyTOTPBackgroundColor`  
- Logo + PatternLockView 300×300 或生物解鎖按鈕  

---

## 6. 導航模式

### 6.1 隱式 NavigationLink（專案慣例）

使用 `@State private var navigateToX = false` + 隱藏 link：

```swift
NavigationLink(destination: SomeView(), isActive: $navigateToX) { EmptyView() }
```

放在 `ZStack` 內或 `.background(Group { ... })`，勿用已 deprecated 的 API 替代既有模式。

### 6.2 側邊選單路由

- `SideMenuDestination` enum 定義於 `SideMenuView.swift`  
- 項目：security → `SecuritySettingsView`、privacy/help → `WebContentView`、about → `AboutView`  

### 6.3 返回按鈕

子頁統一：

```swift
@Environment(\.presentationMode) private var presentationMode
// toolbar leading: chevron.left, .foregroundColor(.white)
.navigationBarBackButtonHidden(true)
```

### 6.4 深層連結

由 `DeepLinkManager.swift` 處理，UI 層不自行 parse URL。

---

## 7. 互動與反馈

| 場景 | 做法 |
|------|------|
| 複製 OTP | `UIPasteboard` + `.toast()`，文案格式：`[issuer] name\n驗證碼已複製` |
| 確認破壞性操作 | SwiftUI `.alert`（參考 SecuritySettingsView 關閉生物解鎖） |
| 生物驗證 | `BiometricManager.shared.authenticate` / `authenticateWithPasscodeFallback`，`Task { }` 包裹 |
| 多選 / 匯出 | checkmark.circle.fill vs circle，accent 色 `getColor(98,112,255)` 或 `.red`（刪除模式） |
| 列表編輯 | `@State isEditing` + `.environment(\.editMode, ...)` + 底部刪除列 |

---

## 8. AI 禁止事項（減少無效 diff）

- ❌ 不要重寫整個 `TokenListView` 或 `RootContainerView` 除非任務明確要求  
- ❌ 不要新建第二套 Toast、Segment、PatternLock  
- ❌ 不要用 SwiftUI 原生 `Form` 取代既有卡片式設定 UI（視覺不一致）  
- ❌ 不要引入 SwiftUI `Color` 硬編色值；查 `UIColor+Extension.swift` 是否有現成名稱  
- ❌ 不要在 View 內寫 Realm / 網路請求；交給 ViewModel 或既有 Service（`TokenService`、`ShareRecordStore`）  
- ❌ 不要一次修改 `project.pbxproj` 除非新增檔案且使用者要求  
- ❌ 不要將 UIKit ViewController 與 SwiftUI View 混在同一流程而不做 hosting  

---

## 9. 檔案放置慣例

| 類型 | 目錄 |
|------|------|
| 新 SwiftUI 頁面 | `NoSMS/<Feature>/`（如 `Security/`、`Share/`、`About/`） |
| 可重用 UI 元件 | `NoSMS/Common/SwiftUIComponents/` |
| 導航 / 深連結 | `NoSMS/Navigation/` |
| Web 相關 | `NoSMS/Web/` |
| ViewModel | 與對應 View 同目錄，命名 `XxxViewModel.swift` |

---

## 10. 狀態檢查清單

每個新畫面在 spec / task 中標明需要哪些狀態：

- [ ] **正常**：有資料時的預設 UI  
- [ ] **Empty**：無資料（參考 emptyStateView）  
- [ ] **Loading**：非同步載入（Web 用 ProgressView；列表可用空白或 skeleton）  
- [ ] **Error**：可重試（Web 參考 hasError UI）  
- [ ] **Disabled**：按鈕禁用色（如 exportOTPDisableTextColor）  

---

## 11. 移至 Cursor Rules 的步驟

確認內容無誤後：

1. 建立 `.cursor/rules/ui-design.mdc`  
2. 將本文件第 2～8 節（技術約束、Tokens、元件、模板、導航、禁止事項）貼入；可刪減範例程式以控制 rule 大小  
3. 在 rule frontmatter 設定 `globs: NoSMS/**/*.swift` 或 `alwaysApply: false` + 描述觸發條件  
4. 本文件可保留於 `docs/` 作為完整參考與設計 token 查表  

---

## 12. 快速參考：畫面 → 檔案對照

| 功能 | 主要檔案 |
|------|----------|
| App 根容器 / 鎖屏 | `RootContainerView.swift` |
| OTP 首頁 | `TokenListView.swift` + `TokenListViewModel.swift` |
| OTP Row | `TokenRowView.swift` + `TokenItemViewModel.swift` |
| 側邊選單 | `SideMenuView.swift` |
| 安全設置 | `SecuritySettingsView.swift` |
| 手勢設定 / 驗證 | `GestureLockSetupView.swift`, `GestureLockVerificationView.swift`, `GestureLockMenuView.swift` |
| 關於 | `AboutView.swift` |
| 隱私 / 幫助 | `WebViewContainer.swift` |
| 分享入口 | `OTPShareAndReceiveView.swift` |
| 分享選列表 | `ShareOTPListView.swift` |
| QR 分享 | `QRcodeOTPShareView.swift` |
| 分享記錄 | `OTPShareRecordView.swift`, `OTPShareRecordDetailView.swift` |
| 手動加入 OTP | `JoinManuallyTOTPView.swift` |
| 掃描 | `Scanner/TokenScannerView.swift` |
