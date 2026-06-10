# NoSMS (MustAuth) 專案之非同步處理技術文件

本文件詳細說明了 NoSMS (MustAuth) 專案在重構至 **SwiftUI + Combine** 的現代化架構下，所使用的三種主要非同步處理技術（Swift Concurrency、Combine 反應式框架、GCD 執行緒調度），並提供具體實作程式碼分析。

---

## 1. Swift Concurrency (async/await)

專案在重構後，主要使用 Apple 現代的 Swift 協程（Swift Concurrency）處理生物識別驗證、圖形密碼認證及本地 Realm 資料庫的異步包裝，免去傳統 Completion Handler 帶來的巢狀 callback（Callback Hell）。

### 1.1 withCheckedContinuation 的橋接應用
在處理系統級 SDK（如 `LocalAuthentication` 的 Face ID/Touch ID）或 Realm 資料庫這類尚未完全支援協程的 Callback 機制時，專案使用 `withCheckedContinuation` 進行異步包裝，將其轉換為 `async/await` 形式。

*   **實作檔案**：[BiometricManager.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/Common/AuthorizationManager/BiometricManager.swift)
```swift
func authenticate(reason: String) async -> Bool {
    return await withCheckedContinuation { continuation in
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            continuation.resume(returning: success)
        }
    }
}
```

*   **實作檔案**：[RealmDataManager.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/RealmDataManager/RealmDataManager.swift)
將 Realm 的背景讀寫包裝為異步 Task，完成後回傳 Plain Object。
```swift
static func readOTPShareAccountAsync() async -> [OTPAccountData] {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .background).async {
            let accounts = self.readOTPShareAccount()
            continuation.resume(returning: accounts)
        }
    }
}
```

### 1.2 MainActor 與執行緒安全
為了確保 UI 元件的更新都在主執行緒（Main Thread）中執行，ViewModel 在處理完協程的異步工作後，會使用 `await MainActor.run` 切回主執行緒更新其被監聽的 `@Published` 狀態。

*   **實作檔案**：[AppLockViewModel.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/Common/AuthorizationManager/AppLockViewModel.swift)
```swift
func authenticateUser() async {
    let result = await biometricManager.authenticate(reason: reason)
    await MainActor.run {
        if result {
            self.isLocked = false
        } else {
            // 失敗時 fallback 啟用手勢解鎖
            self.isLocked = true
        }
    }
}
```

---

## 2. Combine 響應式數據流 (Reactive Data Streams)

專案使用 Combine 代替了原有 UIKit 架構下的 RxSwift。Combine 負責驅動 2FA 驗證碼的倒數計時更新以及 ViewModel 與 View 之間的狀態綁定。

### 2.1 全域 1 秒計時器廣播 (Timer Publisher)
為了讓所有的 TOTP 密碼項目能同步且穩定地更新環狀進度條與倒數秒數，`TokenService` 維護了一個全域的 `timerPublisher`。

*   **實作檔案**：[TokenService.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/Common/TokenStore/TokenService.swift)
```swift
// Setup a shared timer that fires every 1.0 second on the main runloop
self.timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()
    .eraseToAnyPublisher()
```

各個 `TokenItemViewModel` 通過訂閱該計時器，每秒觸發驗證碼剩餘時間的計算：
*   **實作檔案**：[TokenItemViewModel.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/TokenList/TokenItemViewModel.swift)
```swift
tokenService.timerPublisher
    .sink { [weak self] _ in
        self?.updateTimerRemaining()
    }
    .store(in: &cancellables)
```

### 2.2 UI 狀態防抖與過濾 (Debounce & RemoveDuplicates)
在搜尋列輸入關鍵字進行金鑰過濾時，使用 Combine 的操作子進行防抖（Debounce），避免使用者在連續快速輸入時頻繁觸發搜尋邏輯，浪費運算資源。

*   **實作檔案**：[TokenListViewModel.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/TokenList/TokenListViewModel.swift)
```swift
$searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .removeDuplicates()
    .sink { [weak self] text in
        self?.filterTokens(with: text)
    }
    .store(in: &cancellables)
```

---

## 3. Grand Central Dispatch (GCD)

雖然專案全面採用了現代化的 Concurrency 與 Combine，但在某些系統底層（如相簿讀取、相機掃描等）或簡單的延時回調中，依然保留並靈活使用了 **GCD (DispatchQueue)**。

### 3.1 背景解碼與主執行緒同步 (Background Decoding)
當使用者從相簿選取圖片以辨識二維碼（QR Code）時，系統會開啟一個 background queue 進行耗時的圖片解碼與掃描工作，完成後再切回 `DispatchQueue.main` 呈現 Toast 提示或儲存金鑰。

*   **實作檔案**：[UIImage+AppImageExtension.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/Common/Extension/UIImage+AppImageExtension.swift)
```swift
DispatchQueue.global(qos: .userInitiated).async {
    // 進行二維碼圖像特徵提取與偵測 (耗時工作)
    let features = detector.features(in: ciImage)
    
    DispatchQueue.main.async {
        // 返回主線程更新 UI
        self.showScanResult(features)
    }
}
```

### 3.2 輕量化 UI 延遲執行 (Delayed UI Actions)
針對 HUD（例如 Toast 提示）的顯示與自動淡出、手勢繪製錯誤後的短暫紅線停留等，專案使用 `DispatchQueue.main.asyncAfter` 來進行輕量且直觀的延遲回呼。

*   **實作檔案**：[ToastView.swift](file:///Users/ricky.chang/Documents/ios_prog/nosms-ios/NoSMS/Common/SwiftUIComponents/ToastView.swift)
```swift
func showToast(message: String, duration: Double = 1.5) {
    self.message = message
    self.isPresented = true
    
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        self.isPresented = false
    }
}
```
