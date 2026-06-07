import SwiftUI

struct PatternLockView: View {
    let diameter: CGFloat = 64
    let spacing: CGFloat = 40
    
    @State private var connectedIndices: [Int] = []
    @State private var currentDragLocation: CGPoint? = nil
    
    // Callback invoked when a gesture lock pattern is completed
    var onDrawingCompleted: (String) -> Void
    
    private var gridSpacing: CGFloat {
        return diameter + spacing
    }
    
    private var boardSize: CGFloat {
        return diameter * 3 + spacing * 2
    }
    
    var body: some View {
        GeometryReader { geometry in
            let centers = calculateCenters(in: geometry.size)
            
            ZStack {
                // Line connection overlay
                Path { path in
                    guard !connectedIndices.isEmpty else { return }
                    path.move(to: centers[connectedIndices[0]])
                    for i in 1..<connectedIndices.count {
                        path.addLine(to: centers[connectedIndices[i]])
                    }
                    if let dragLoc = currentDragLocation {
                        path.addLine(to: dragLoc)
                    }
                }
                .stroke(
                    Color(UIColor.manuallyTOTPSwitchColor),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                
                // 3x3 Grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(diameter), spacing: spacing), count: 3),
                    spacing: spacing
                ) {
                    ForEach(0..<9, id: \.self) { index in
                        Circle()
                            .fill(connectedIndices.contains(index) ? Color(UIColor.manuallyTOTPSwitchColor).opacity(0.3) : Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(connectedIndices.contains(index) ? Color(UIColor.manuallyTOTPSwitchColor) : Color.white.opacity(0.6), lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .fill(connectedIndices.contains(index) ? Color(UIColor.manuallyTOTPSwitchColor) : Color.white.opacity(0.3))
                                    .frame(width: diameter / 3, height: diameter / 3)
                            )
                            .frame(width: diameter, height: diameter)
                    }
                }
                .frame(width: boardSize, height: boardSize)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        self.currentDragLocation = value.location
                        checkTouchPoint(value.location, centers: centers)
                    }
                    .onEnded { _ in
                        self.currentDragLocation = nil
                        let patternString = connectedIndices.map { String($0) }.joined()
                        if !patternString.isEmpty {
                            onDrawingCompleted(patternString)
                        }
                        // Clear visual pattern after a short delay so the user can verify their stroke
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                connectedIndices.removeAll()
                            }
                        }
                    }
            )
        }
        .frame(width: boardSize, height: boardSize)
    }
    
    private func calculateCenters(in size: CGSize) -> [CGPoint] {
        var centers: [CGPoint] = []
        let offset = diameter / 2
        let startX = (size.width - boardSize) / 2 + offset
        let startY = (size.height - boardSize) / 2 + offset
        
        for row in 0..<3 {
            for col in 0..<3 {
                let x = startX + CGFloat(col) * gridSpacing
                let y = startY + CGFloat(row) * gridSpacing
                centers.append(CGPoint(x: x, y: y))
            }
        }
        return centers
    }
    
    private func checkTouchPoint(_ point: CGPoint, centers: [CGPoint]) {
        let maxDistance = diameter / 2
        
        for (index, center) in centers.enumerated() {
            let distance = hypot(point.x - center.x, point.y - center.y)
            if distance <= maxDistance {
                if !connectedIndices.contains(index) {
                    // Trigger light haptic bump
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    withAnimation(.easeIn(duration: 0.1)) {
                        connectedIndices.append(index)
                    }
                }
                break
            }
        }
    }
}

struct PatternLockView_Previews: PreviewProvider {
    static var previews: some View {
        PatternLockView { pattern in
            print("Drawn Pattern: \(pattern)")
        }
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.blue.opacity(0.8))
        .previewLayout(.sizeThatFits)
    }
}
