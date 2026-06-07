import SwiftUI
import OneTimePassword

struct TokenRowView: View {
    @ObservedObject var viewModel: TokenItemViewModel
    
    // Callback to display copy-to-clipboard feedback via toast
    var onCopied: (String) -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Account info (Issuer & Name)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.issuer)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(UIColor.tokenListIssuerColor))
                Text(viewModel.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.tokenListNameColor))
            }
            
            Spacer()
            
            // Password digits
            Text(formattedPassword)
                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(UIColor.manuallyTOTPTextSelectedColor))
                .tracking(2)
            
            // Interactive status indicator (Countdown Ring or Refresh Button)
            if viewModel.isOnTime {
                CircleProgressView(
                    remainingSeconds: viewModel.remainingSeconds,
                    totalSeconds: viewModel.refreshTimes,
                    lineWidth: 3
                )
                .frame(width: 28, height: 28)
            } else {
                Button(action: {
                    viewModel.generateOnTapPassword()
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(UIColor.tokenListTimerColor))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.tokenListTableViewBackgroundColor))
        .contentShape(Rectangle()) // Makes the entire row tap-target
        .onTapGesture {
            UIPasteboard.general.string = viewModel.currentPassword
            onCopied("[\(viewModel.issuer)] \(viewModel.name)\n驗證碼已複製")
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: {
                withAnimation {
                    viewModel.togglePin()
                }
            }) {
                Label(viewModel.isPin ? "取消置頂" : "置頂", systemImage: viewModel.isPin ? "pin.slash.fill" : "pin.fill")
            }
            .tint(Color(UIColor.manuallyTOTPSwitchColor))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("刪除", systemImage: "trash.fill")
            }
        }
    }
    
    // Formats password (e.g., "123 456" for 6-digit passwords)
    private var formattedPassword: String {
        let raw = viewModel.currentPassword
        guard raw.count == 6 else { return raw }
        let index3 = raw.index(raw.startIndex, offsetBy: 3)
        return "\(raw[..<index3]) \(raw[index3...])"
    }
}
