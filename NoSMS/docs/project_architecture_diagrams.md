# NoSMS (MustAuth) SwiftUI 專案架構圖、類別圖與循序圖

本文件展示了 NoSMS (MustAuth) 專案在重構至 **SwiftUI + Combine (MVVM)** 架構後的系統結構與主要互動行為。

---

## 1. 系統架構圖 (System Architecture Diagram)

專案遵循標準的 **MVVM (Model-View-ViewModel)** 架構，同時將數據持久化（Keychain & Realm）與安全管控解耦。

```mermaid
graph TD
    subgraph View_Layer [SwiftUI 視圖層 - UI]
        RCV[RootContainerView <br> 負責: 安全遮罩與解鎖]
        TLV[TokenListView <br> 負責: 金鑰列表 / 釘選 / 搜尋]
        PLV[PatternLockView <br> 負責: 圖形解鎖 UI]
        SMV[SideMenuView <br> 負責: 側邊欄導航]
        QSV[QRcodeOTPShareView <br> 負責: 二維碼匯出]
    end

    subgraph ViewModel_Layer [ViewModel 業務邏輯層]
        TLVM[TokenListViewModel <br> 負責: 列表狀態、倒數計時與過濾]
        GLVM[GestureLockViewModel <br> 負責: 手勢狀態比對與驗證]
    end

    subgraph Service_Layer [核心服務與管理者]
        TS[TokenService <br> 負責: 金鑰/分組狀態變更與廣播]
        BM[BiometricManager <br> 負責: Native FaceID / TouchID]
        DLM[DeepLinkManager <br> 負責: mustauth:// 深層連結處理]
    end

    subgraph Data_Layer [數據儲存層]
        KTS[KeychainTokenStore <br> 負責: OTP 金鑰 Keychain 存取]
        RDM[RealmDataManager <br> 負責: 匯出匯入分享歷史紀錄]
        OTP[OneTimePassword SDK <br> 負責: TOTP/HOTP 密碼算法]
    end

    %% UI 綁定 ViewModel
    RCV --> TLVM
    RCV --> GLVM
    TLV --> TLVM
    PLV --> GLVM
    
    %% ViewModel 呼叫服務
    TLVM --> TS
    TLVM --> BM
    GLVM --> BM
    
    %% 服務介接數據層
    TS --> KTS
    TS --> RDM
    DLM --> TS
    KTS --> OTP
```

---

## 2. 專案類別圖 (Class Diagram)

以下是主要類別、結構與協議（Protocol）的依賴與繼承關係。

```mermaid
classDiagram
    class RootContainerView {
        +AppLockViewModel viewModel
        +Body body
        -showBiometricAuth()
        -showPatternLock()
    }

    class TokenListView {
        +TokenListViewModel viewModel
        +Body body
        -showSideMenu()
        -showShareMenu()
    }

    class TokenListViewModel {
        +List~AdapterTokenProtocol~ tokens
        +List~AdapterTokenProtocol~ pinnedTokens
        +String searchText
        +TokenService tokenService
        +BiometricManager biometricManager
        +reloadTokens()
        +togglePin(token)
        +deleteToken(token)
    }

    class TokenService {
        <<ObservableObject>>
        +List~PersistentToken~ persistentTokens
        +List~Data~ pinList
        +List~GroupObject~ groupList
        +AnyPublisher~Date, Never~ timerPublisher
        +reloadTokens()
        +addToken()
        +deleteToken()
    }

    class KeychainTokenStore {
        <<Singleton>>
        +List~AdapterTokenProtocol~ tokenList
        +saveToken(token)
        +deleteToken(token)
    }

    class BiometricManager {
        +LAContext context
        +canEvaluatePolicy() Promise
        +evaluatePolicy() Promise
    }

    class RealmDataManager {
        +addOTPShareAccount(token, time)
        +readOTPShareAccount() List~OTPAccountData~
    }

    class AdapterTokenProtocol {
        <<Protocol>>
        +Generator.Factor tokenType
        +BehaviorSubject~String~ password
        +BehaviorSubject~String~ name
        +BehaviorSubject~String~ issuer
        +Data uuid
        +getMustAuthTokenURL() URL
    }

    class AdapterToken {
        +PersistentToken persistentToken
        +Token token
        +getMustAuthTokenURL() URL
    }

    RootContainerView ..> TokenListView : embeds
    TokenListView --> TokenListViewModel : uses
    TokenListViewModel --> TokenService : observes
    TokenService --> KeychainTokenStore : delegates
    KeychainTokenStore ..> AdapterTokenProtocol : holds
    AdapterToken ..|> AdapterTokenProtocol : implements
    TokenListViewModel --> BiometricManager : auths
    TokenListViewModel ..> RealmDataManager : histories
```

---

## 3. 主要循序圖 (Sequence Diagrams)

### 3.1 App 啟動與安全驗證流

展示使用者開啟 App 時，系統如何處理前背景切換、加載模糊遮罩與執行 Face ID/圖形密碼驗證。

```mermaid
sequenceDiagram
    autonumber
    actor User as 使用者
    participant App as App 生命週期 / RootContainerView
    participant BM as BiometricManager (FaceID)
    participant VM as GestureLockViewModel
    participant TS as TokenService

    User ->> App: 開啟或返回前景 (Active)
    App ->> App: 檢查是否閒置 > 5 分鐘
    alt 需要強制驗證 (Locked)
        App ->> App: 啟用毛玻璃模糊保護遮罩 (.blur)
        App ->> BM: 請求 Face ID/Touch ID 驗證
        BM -->> User: 彈出系統 Face ID 授權視窗
        User ->> BM: 提供臉部或指紋資訊
        alt 驗證成功
            BM -->> App: 返回 Success
            App ->> App: 解除模糊遮罩 (Unlock)
            App ->> TS: 重新載入金鑰
        else 驗證失敗 (Fallback)
            BM -->> App: 返回 Failure / 點擊密碼解鎖
            App ->> App: 顯示 PatternLockView (圖形手勢鎖)
            User ->> App: 繪製九宮格連線手勢
            App ->> VM: 驗證手勢軌跡
            VM -->> App: 驗證成功
            App ->> App: 解除手勢鎖與模糊遮罩 (Unlock)
        end
    else 不需要驗證
        App ->> TS: 直接加載並刷新金鑰
    end
```

### 3.2 2FA 驗證碼每秒倒數與刷新流

展示全域 Combine 計時器如何每秒驅動視圖進行 2FA 代碼的刷新。

```mermaid
sequenceDiagram
    autonumber
    participant TS as TokenService (Combine Timer)
    participant VM as TokenListViewModel
    participant View as TokenListView (SwiftUI)
    participant cell as TokenRowView (Cell)
    participant OTP as OneTimePassword (Core)

    TS ->> TS: 每 1.0 秒觸發 timerPublisher
    TS -->> VM: 發送當前時間戳 (Date)
    VM ->> VM: 遍歷所有金鑰並計算剩餘秒數 (timeRemaining)
    alt 週期的剩餘秒數為 0 (例如每 30 秒)
        VM ->> OTP: 請求生成新驗證碼 (TOTP/HOTP)
        OTP -->> VM: 回傳 6/8 位數密碼字串
    end
    VM -->> View: 觸發 SwiftUI `@Observable` 屬性更新
    View ->> cell: 重繪對應的密碼標籤與 CircleView (進度環)
```
