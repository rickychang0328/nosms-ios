import SwiftUI
import Combine

struct RootContainerView: View {
    @StateObject private var appLockVM = AppLockViewModel()
    @StateObject private var gestureLockVM = GestureLockViewModel()
    
    @State private var isBackgroundBlurred = false
    @State private var isGestureLocked = true
    
    var body: some View {
        ZStack {
            // Main app view content
            TokenListView()
                .blur(radius: isBackgroundBlurred ? 15 : 0)
            
            // Global lock screen overlay
            if isAppLocked {
                ZStack {
                    Color(UIColor.manuallyTOTPBackgroundColor)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 30) {
                        Image("NoSMS_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        
                        if gestureLockVM.isGestureOpen {
                            Text("請繪製手勢密碼解鎖")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            PatternLockView(
                                isReset: .constant(false),
                                onPatternCompleted: { pattern in
                                    if gestureLockVM.validate(pattern: pattern) {
                                        unlockApp()
                                    }
                                }
                            )
                            .frame(width: 300, height: 300)
                            
                            if appLockVM.isBiometricEnabled {
                                Button(action: {
                                    triggerBiometricAuth()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "faceid")
                                        Text("使用生物識別解鎖")
                                    }
                                    .foregroundColor(.blue)
                                    .font(.system(size: 15, weight: .semibold))
                                }
                                .padding(.top, 16)
                            }
                        } else {
                            Text("應用程式已鎖定")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                triggerBiometricAuth()
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 50))
                                    Text("點擊生物解鎖")
                                        .font(.system(size: 15))
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            checkInitialLockState()
        }
        // Background blur and lock triggers
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isBackgroundBlurred = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            isBackgroundBlurred = true
            if gestureLockVM.isGestureOpen {
                isGestureLocked = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            withAnimation(.spring()) {
                isBackgroundBlurred = false
            }
            if appLockVM.isBiometricEnabled && appLockVM.isLocked {
                triggerBiometricAuth()
            }
        }
    }
    
    private var isAppLocked: Bool {
        return (gestureLockVM.isGestureOpen && isGestureLocked) || (appLockVM.isBiometricEnabled && appLockVM.isLocked)
    }
    
    private func unlockApp() {
        withAnimation {
            isGestureLocked = false
            appLockVM.isLocked = false
        }
    }
    
    private func triggerBiometricAuth() {
        Task {
            await appLockVM.authenticateUser()
            if !appLockVM.isLocked {
                withAnimation {
                    isGestureLocked = false
                }
            }
        }
    }
    
    private func checkInitialLockState() {
        if gestureLockVM.isGestureOpen {
            isGestureLocked = true
        }
        if appLockVM.isBiometricEnabled {
            triggerBiometricAuth()
        }
    }
}

struct RootContainerView_Previews: PreviewProvider {
    static var previews: some View {
        RootContainerView()
    }
}
