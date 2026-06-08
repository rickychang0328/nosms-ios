# NoSMS (MustAuth) - iOS 2FA 金鑰生成工具

NoSMS（又稱 MustAuth）是一款專注於安全性與使用者體驗的雙重驗證 (2FA) 金鑰生成工具。功能與 Google Authenticator 類似，並提供更強大的安全防護（生物辨識與圖形手勢密碼鎖）、App 背景隱私遮罩，以及群組管理、置頂釘選、二維碼批量導入/匯出分享等功能。

本專案目前已完成 **SwiftUI + Combine** 的架構重構（原為 UIKit + RxSwift），最低支援部署目標已升級至 **iOS 15.0+**。

---

## 📖 技術與重構文件

專案的詳細設計說明與重構進度文件已整理至 `docs/` 資料夾下，供開發者參閱：

*   **[SDD 技術規格文件](docs/sdd_technical_specification.md)**：包含專案的功能概述、核心業務邏輯流（金鑰生命週期、啟動解鎖流）、畫面狀態管理（RxSwift 時代的狀態定義）與第三方庫依賴分析。
*   **[SwiftUI 重構與架構設計方案](docs/swiftui_refactoring_plan.md)**：詳細規劃並說明如何將原有 UIKit + RxSwift 架構轉型為 SwiftUI + Combine / MVVM 架構，包含資料響應、事件與生命週期收納、第三方庫原生替代方案以及重構前後的關鍵技術對照表。
*   **[SwiftUI 重構階段任務清單](docs/task.md)**：記錄階段 5（全面 SwiftUI 功能補全、系統介接與依賴/舊代碼清理）的具體實作與完成進度。

---

## 🛠️ 開發與建置指引

### 環境要求
*   **macOS**
*   **Xcode 13.0+** (推薦 Xcode 14/15+)
*   **CocoaPods** (用於管理第三方套件)
*   **iOS SDK**: 15.0+ (最低部署目標已升級為 iOS 15.0)

### 快速開始

1.  **複製專案並進入專案目錄**
    ```bash
    cd /Users/ricky.chang/Documents/ios_prog/nosms-ios
    ```

2.  **安裝 CocoaPods 依賴**
    由於專案依賴於 `OneTimePassword`、`RealmSwift` 等套件，在首次建置前請務必執行：
    ```bash
    pod install
    ```

3.  **開啟 Xcode 工作空間**
    請務必使用 `.xcworkspace` 檔案開啟專案，而非 `.xcodeproj`：
    ```bash
    open NoSMS.xcworkspace
    ```

4.  **編譯與執行**
    選擇目標模擬器（例如 iPhone 15 或更新機型），點擊 Xcode 的 **Run** 按鈕（或使用快速鍵 `Cmd + R`）進行編譯與執行。

---

## 🏗️ 核心架構說明

重構後，專案採用標準的 **MVVM (Model-View-ViewModel)** 架構：

*   **Model 層**：
    *   `Token` & `PersistentToken`：由原生的 `OneTimePassword` 庫提供，透過 Keychain 進行安全的私鑰儲存。
    *   `OTPAccount`：使用 `RealmSwift` 儲存，記錄金鑰的匯入與分享歷史記錄。
*   **ViewModel 層**：
    *   負責封裝業務邏輯與數據加工，使用原生的 Combine 框架（`@Published` 與 `Publisher`）提供資料流給視圖。
*   **View / SwiftUI 層**：
    *   採用原生 SwiftUI 宣告式佈局（`VStack`, `HStack`, `List`, `ZStack`），替代了原先的 `SnapKit` 與 UIKit 視圖。
    *   原生毛玻璃效果 `.blur` 與自訂 `ZStack` 隱私覆蓋層取代了 `DynamicBlurView`。
    *   自訂 `PatternLockView`（基於 `LazyVGrid` 與拖曳手勢）取代了 `JXPatternLock`。
    *   原生的 `LocalAuthentication` 取代了 `BiometricAuthentication` 套件。
