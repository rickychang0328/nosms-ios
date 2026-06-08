# NoSMS (MustAuth) SwiftUI 重構與架構設計方案

本文件規劃將原有 UIKit + RxSwift 專案重構為 SwiftUI 框架，並遵循標準的 **MVVM（Model-View-ViewModel）** 架構。本方案重點在於「響應式框架轉換（RxSwift -> Combine / @Observable）」與「UI 庫去依賴化（用 SwiftUI 原生機制替代）」。

---

## 1. 核心架構設計與改寫思路

### 1.1 數據響應架構的轉型
*   **原有機制 (UIKit + RxSwift)**：藉由 `BehaviorSubject`、`PublishSubject` 與 `.subscribe(onNext:)` 來驅動 UI，並使用 `DisposeBag` 管理生命週期。
*   **SwiftUI 方案 (SwiftUI + Combine / @Observable)**：
    *   **iOS 17+ 建議**：使用 Swift 5.9 的 `@Observable` 巨集。ViewModel 的屬性變更會直接、自動且高效地觸發與其綁定的 SwiftUI View 局部重新渲染，大幅減少手動訂閱與 `cancellables` 的維護。
    *   **相容舊版 / 底層異步流**：使用 Apple 原生的 **Combine** 框架作為底層資料流。`CurrentValueSubject` 替代 `BehaviorSubject`，`PassthroughSubject` 替代 `PublishSubject`。

### 1.2 互動事件與生命週期收納
*   原先散落在 ViewController 的各種代理人（`UITableViewDelegate`、`UITextFieldDelegate`）和監聽器（例如鍵盤通知、生命週期通知），一律收納至 **ViewModel** 或 **SwiftUI 宣告式修飾符** 中：
    *   **搜尋輸入監聽**：原先的 `searchTextField.rx.text` 改為 ViewModel 中的 `@Published var searchText: String = ""`（或 `@Observable` 屬性），並利用 Combine 的 `.debounce` 與 `.removeDuplicates` 在 ViewModel 中實現防抖搜尋邏輯。
    *   **TableView 拖拽排序與編輯**：透過 SwiftUI List 的 `.onMove` 和 `.onDelete` 閉包，直接呼叫 ViewModel 的 `swapToken(from:to:)` 與 `deleteToken(at:)` 方法，不需代理人。
    *   **生命週期通知**：改用 SwiftUI 的 `.onAppear` / `.onDisappear` 修飾符以及 `.onChange(of: scenePhase)` 監聽背景/前景狀態切換，避免直接在 AppDelegate 中呼叫視圖元件。

---

## 2. 第三方元件與功能庫原生替代方案

### 2.1 UI 元件去依賴化 (Native SwiftUI Replacements)
*   **`DynamicBlurView` 替代**：
    SwiftUI 提供強大的原生渲染修飾符。我們可以使用 `.blur(radius: isLocked ? 15 : 0)`。
    App 的背景遮罩可以用 `ZStack` 搭配條件式 Overlay 或覆蓋整個畫面的 `.fullScreenCover` 來實作。
*   **`SnapKit` 替代**：
    SwiftUI 的宣告式佈局（`VStack`、`HStack`、`ZStack`、`LazyVStack`、`List`、`Spacer`）完全取代 SnapKit 約束設定，介面程式碼量可減少 50% 以上。
*   **`JXPatternLock` 替代**：
    利用 SwiftUI 的 `LazyVGrid` 繪製 3x3 圓點，配合 `.gesture(DragGesture(minimumDistance: 0))` 捕捉使用者手指滑動坐標，動態比對與圓點的位置範圍，並在 `Path` 中用 `.addLine` 渲染連線軌跡。整個手勢解鎖的狀態完全受控於 `GestureLockViewModel`。
*   **`NoSMSHUD` (Toast / Loading) 替代**：
    使用自訂 ViewModifier 封裝一個疊加視圖：
    ```swift
    struct ToastModifier: ViewModifier {
        @Binding var isPresented: Bool
        let message: String
        // ... 用 ZStack 在最上層渲染並在幾秒後自動設定 isPresented = false
    }
    ```

### 2.2 功能性套件與 ViewModel 接軌 (Functional Libraries Integration)
*   **`OneTimePassword` (OTP 核心)**：
    *   保留其密碼產生及 Keychain 讀寫邏輯，但將其封裝在一個 `TokenService` 中。
    *   ViewModel 持有該 Service，將獲取的 `Token` 轉換為 SwiftUI 可以直接綁定的結構體（Struct），並藉由計時器定時調用密碼更新方法。
*   **`BiometricAuthentication` 替代**：
    *   移除該庫，改用 iOS 原生 `LocalAuthentication` 框架。
    *   在 ViewModel 中撰寫一個 `BiometricManager` 類別，透過 `LAContext` 發起 Face ID/Touch ID 驗證，並藉由 `async/await` 異步返回成功與否，ViewModel 再依據回傳值修改 `@Published var isLocked: Bool`。
*   **`RealmSwift` 接軌**：
    *   維持 `RealmDataManager` 作為資料存取層。
    *   當 ViewModel 需要存取分享歷史記錄時，透過 Manager 進行異步讀寫。若有即時更新需求，可使用 Combine 的 `Realm` 發行者（Publisher）或在寫入完成後主動更新 ViewModel 裡的 Observable 陣列。

---

## 3. 前後重構技術對照表 (Comparison Mapping Table)

下表列出專案關鍵功能點在重構前後的程式碼架構與邏輯對照：

| 功能點 / 職責 | UIKit + RxSwift (重構前) | SwiftUI + MVVM (重構後建議) | 承載邏輯之容器 (Class/Struct) |
| :--- | :--- | :--- | :--- |
| **金鑰列表資料源** | `persistentTokensBehavior` <br>(RxSwift `BehaviorSubject`) | `@Published var tokens: [TokenItem] = []` <br>或 `@Observable` 中的陣列 | `TokenListViewModel` |
| **金鑰列表 UI 呈現** | `UITableView` + `TokenListTableViewCell` | `List` + `TokenRowView` | `TokenListView` |
| **計時器驅動** | `timerObserver: Observable<TimeInterval>` <br>使用 `RxSwift.interval` | Combine `Timer.publish` 或 <br>SwiftUI `.onReceive(Timer)` | `TokenListViewModel` / `TokenListView` |
| **置頂釘選狀態** | `TokenListSupportPin` 類別處理 Pin/NoPin 分群 | ViewModel 依 `isPinned` 分組 <br>在 SwiftUI 內渲染多個 `Section` | `TokenListViewModel` |
| **文字搜尋過濾** | 監聽 `searchTextField.rx.text` <br>呼叫 `viewModel.searchText(input:)` | `@Published var searchText = ""` <br>配合 Combine `debounce` 執行過濾 | `TokenListViewModel` |
| **TableView 拖曳排序** | `tableView.rx.itemMoved` <br>觸發 `swapToken(beforeIndex:afterIndex:)` | List 中的 `.onMove(perform:)` | `TokenListView` -> `ViewModel` |
| **App 退到背景遮罩** | `BlurViewController.shared` <br>(依附於 `DynamicBlurView`) | `.blur(radius: isAppBlurred ? 20 : 0)` <br>配合 Overlay 覆蓋保護 | `RootContainerView` |
| **生物識別/解鎖邏輯** | `AuthIDStatusManager` 類別 <br>呼叫 `BiometricAuthentication` 庫 | `BiometricManager`（調用 native `LAContext`）<br>以 `async/await` 驅動 `isLocked` 狀態 | `AppLockViewModel` + `LocalAuthentication` |
| **手勢密碼繪製與比對**| `GestVerificationViewController` <br>(使用 `JXPatternLock` UI 元件) | 自訂 `PatternLockView` 視圖（`LazyVGrid` <br>+ `DragGesture` + `Path` 連線） | `PatternLockView` + `GestureLockViewModel` |
| **歷史記錄存取** | `RealmDataManager` 靜態方法 + Realm | `RealmDataManager` <br>ViewModel 藉由 async 呼叫並映射為 UI Model | `HistoryViewModel` + `RealmDataManager` |
