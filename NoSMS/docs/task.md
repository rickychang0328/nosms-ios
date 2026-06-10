# NoSMS (MustAuth) SwiftUI 重構項目清單 - 階段 5

本清單用於追蹤階段 5（系統介接、測試與舊代碼清理）的具體實作進度，確保所有 UIKit 功能均已以原生 SwiftUI 完整重構。

---

## 階段 5：全面 SwiftUI 功能補全與系統介接

- `[x]` **5.1 實作側邊欄選單與導頁 (`SideMenuView.swift`)**
  - `[x]` 建立自左側滑出的選單，寬度為 290，包含「安全設置」、「隱私權政策」、「幫助中心」、「關於」選項。
- `[x]` **5.2 實作網頁載入元件與關於頁面**
  - `[x]` 實作 `WebViewContainer.swift` 封裝 `WKWebView`，包含加載 HUD 提示。
  - `[x]` 實作 `AboutView.swift` 呈現 Logo、版本號與更新升級按鈕。
- `[x]` **5.3 實作安全設置與手勢密碼設定流程**
  - `[x]` 實作 `SecuritySettingsView.swift` 綁定生物解鎖開關及手勢解鎖狀態。
  - `[x]` 實作手勢選單（修改/關閉手勢）與驗證畫面 `GestureLockVerificationView.swift`。
- `[x]` **5.4 實作相簿二維碼導入流程**
  - `[x]` 實作 `PhotoQRCodeImporter.swift` 封裝 `PHPickerViewController`，用 `CIDetector` 掃描並儲存 OTP。
- `[x]` **5.5 實作分享接收入口與匯出列表**
  - `[x]` 實作 `OTPShareAndReceiveView.swift` 入口頁。
  - `[x]` 實作 `ShareOTPListView.swift` 支援搜尋與「全選/取消全選」，列出欲匯出的帳號。
- `[x]` **5.6 實作二維碼分享顯示頁**
  - `[x]` 實作 `QRcodeOTPShareView.swift` 支援每 8 個帳號分頁、60秒計時器、防截圖提示及包含帳號列表覆蓋層。
- `[x]` **5.7 實作分享記錄與記錄明細**
  - `[x]` 實作 `OTPShareRecordView.swift` 與 `OTPShareRecordDetailView.swift` 讀取並顯示 Realm 內的匯出/匯入歷史。
- `[x]` **5.8 整合主頁面與安全驗證**
  - `[x]` 修改 `TokenListView.swift` 加入側邊欄手勢、修改編輯模式底部欄為「刪除與分享」、點擊分享前進行安全性驗證。
- `[x]` **5.9 更新 App 啟動入口與深層連結**
  - `[x]` 修改 `AppDelegate.swift` 使用 `UIHostingController` 啟動 `RootContainerView`，並銜接深層連結 `DeepLinkManager`。
- `[x]` **5.10 檔案註冊與依賴清理**
  - `[x]` 註冊所有新 SwiftUI 檔案至 `project.pbxproj`。
  - `[x]` 移除 Podfile 中的 SnapKit, DynamicBlurView, BiometricAuthentication, JXPatternLock並執行 `pod install`。
  - `[x]` 移除原先的舊 UIKit ViewControllers 檔案，確認項目正常編譯與測試通過。
