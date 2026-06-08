import SwiftUI
import OneTimePassword
import Base32

class JoinManuallyTOTPViewModel: ObservableObject {
    @Published var urlString: String = "" {
        didSet {
            parseURLString()
        }
    }
    @Published var account: String = "" {
        didSet {
            let filtered = account.filter { !$0.isInvalidNameOrIssuerCharacter }
            if filtered != account {
                account = filtered
            }
        }
    }
    @Published var issuer: String = "" {
        didSet {
            let filtered = issuer.filter { !$0.isInvalidNameOrIssuerCharacter }
            if filtered != issuer {
                issuer = filtered
            }
        }
    }
    @Published var secret: String = ""
    @Published var isTimeBased: Bool = true
    
    @Published var errorMessage: String? = nil
    @Published var isSuccess: Bool = false
    @Published var alertItem: AlertItem? = nil
    
    private let tokenService: TokenService
    private var token: Token?
    
    init(tokenService: TokenService = .shared, pastedString: String? = nil) {
        self.tokenService = tokenService
        if let pastedString = pastedString {
            self.urlString = pastedString
            parseURLString()
        }
    }
    
    private func parseURLString() {
        guard !urlString.isEmpty else { return }
        
        let cleaned = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: cleaned) ?? URL(string: cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""),
           let parsedToken = Token(customURL: url) {
            self.token = parsedToken
            self.account = parsedToken.name
            self.issuer = parsedToken.issuer
            
            if case .timer = parsedToken.generator.factor {
                self.isTimeBased = true
            } else {
                self.isTimeBased = false
            }
            
            if let parsedURLInfo = try? url.mustAuth.parsingSetURL() {
                self.secret = parsedURLInfo.secretString
            }
        } else if let parsedURLInfo = try? cleaned.mustAuth.parsingSetURL() {
            self.account = parsedURLInfo.name
            self.issuer = parsedURLInfo.issuer
            self.secret = parsedURLInfo.secretString
            if case .timer = parsedURLInfo.factor {
                self.isTimeBased = true
            } else {
                self.isTimeBased = false
            }
        }
    }
    
    var isSaveEnabled: Bool {
        return !account.trimmingCharacters(in: .whitespaces).isEmpty &&
               !secret.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func saveToken() {
        let trimmedSecret = secret.trimmingCharacters(in: .whitespaces)
        
        guard trimmedSecret.count > 1, trimmedSecret.count < 201, trimmedSecret.mustAuth.regularExpression.validSecret() else {
            self.errorMessage = "金鑰無效"
            return
        }
        
        guard let secretData = MF_Base32Codec.data(fromBase32String: trimmedSecret) else {
            self.errorMessage = "金鑰解碼失敗"
            return
        }
        
        let algorithm: Generator.Algorithm
        let digits: Int
        let factor: Generator.Factor
        
        if let token = self.token {
            let tokenFactor = token.generator.factor
            algorithm = token.generator.algorithm
            digits = token.generator.digits
            
            if isTimeBased {
                if case .counter = tokenFactor {
                    factor = .timer(period: 30)
                } else {
                    factor = tokenFactor
                }
            } else {
                if case .counter = tokenFactor {
                    factor = tokenFactor
                } else {
                    factor = .counter(0)
                }
            }
        } else {
            factor = isTimeBased ? .timer(period: 30) : .counter(0)
            algorithm = .sha1
            digits = 6
        }
        
        guard let generator = Generator(factor: factor, secret: secretData, algorithm: algorithm, digits: digits) else {
            self.errorMessage = "無法生成驗證器"
            return
        }
        
        let addToken = Token(name: account, issuer: issuer, generator: generator)
        
        tokenService.addToken(addToken, groupNames: []) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isSuccess = true
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.domain == "TokenService" && nsError.code == 409,
                       let retryAction = nsError.userInfo["retryAction"] as? () -> Void {
                        self?.alertItem = AlertItem(
                            title: nsError.localizedDescription,
                            message: "[\(addToken.issuer)] \(addToken.name)",
                            primaryButtonText: "確認",
                            secondaryButtonText: "取消",
                            primaryAction: {
                                retryAction()
                                self?.isSuccess = true
                            }
                        )
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct JoinManuallyTOTPView: View {
    @StateObject private var viewModel = JoinManuallyTOTPViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.manuallyTOTPBackgroundColor)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 8) {
                    CustomTextField(title: "驗證碼 (URL)", placeholder: "otpauth://", text: $viewModel.urlString)
                    CustomTextField(title: "帳號", placeholder: "hello@example.com", text: $viewModel.account)
                    CustomTextField(title: "發行者 (Issuer)", placeholder: "small-chat-test", text: $viewModel.issuer)
                    CustomTextField(title: "密鑰", placeholder: "fwjf btrf", text: $viewModel.secret)
                    CustomSwitchField(title: "基於時間", isOn: $viewModel.isTimeBased)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarTitle("手動輸入", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: {
                viewModel.saveToken()
            }) {
                Text("完成")
                    .bold()
                    .foregroundColor(viewModel.isSaveEnabled ? .white : .gray)
            }
            .disabled(!viewModel.isSaveEnabled)
        )
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                primaryButton: .default(Text(alertItem.primaryButtonText), action: alertItem.primaryAction),
                secondaryButton: .cancel(Text(alertItem.secondaryButtonText ?? "取消"))
            )
        }
        .toast(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        ), message: viewModel.errorMessage ?? "")
        .onReceive(viewModel.$isSuccess) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.manuallyTOTPTitleColor))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(Color(UIColor.manuallyTOTPTextFieldColor))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.manuallyTOTPTextFieldUnderLineColor))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

struct CustomSwitchField: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.manuallyTOTPTitleColor))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.manuallyTOTPSwitchColor)))
                .labelsHidden()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

extension Character {
    var isInvalidNameOrIssuerCharacter: Bool {
        return self == "&" || self == " " || self == "/" || self == "=" || self == "#" || self == "?" || self == "%"
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButtonText: String
    let secondaryButtonText: String?
    let primaryAction: () -> Void
}
