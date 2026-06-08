import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    var duration: TimeInterval = 2.0
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.85))
                                .shadow(color: Color.black.withAlphaComponent(0.2), radius: 8, x: 0, y: 4)
                        )
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isPresented: @Binding var isPresented: Bool, message: String) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}
