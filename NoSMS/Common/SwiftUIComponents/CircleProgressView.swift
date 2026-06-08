import SwiftUI

struct CircleProgressView: View {
    let remainingSeconds: Double
    let totalSeconds: Double
    var lineWidth: CGFloat = 3.0
    
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return remainingSeconds / totalSeconds
    }
    
    var body: some View {
        ZStack {
            // Background ring track
            Circle()
                .stroke(Color(UIColor.tokenListTableViewBackgroundColor), lineWidth: lineWidth)
            
            // Foreground active progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    Color(UIColor.tokenListTimerColor),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90)) // Aligns 0% progress at 12 o'clock
                .animation(.linear(duration: 1.0), value: remainingSeconds) // Smooth second-by-second updates
        }
    }
}

struct CircleProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgressView(remainingSeconds: 15, totalSeconds: 30)
            .frame(width: 44, height: 44)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
