import SwiftUI

struct CustomSegmentControl: View {
    let titles: [String]
    @Binding var selectedIndex: Int
    @Namespace private var animationNamespace
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(titles.indices, id: \.self) { index in
                    VStack(spacing: 6) {
                        Text(titles[index])
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedIndex == index ? Color(UIColor.customSegmentControlEnableTextColor) : Color(UIColor.customSegmentControlDisnableTextColor))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedIndex = index
                                }
                            }
                        
                        // Underline indicator that slides smoothly
                        if selectedIndex == index {
                            Color(UIColor.customSegmentControlUnderLineColor)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                                .matchedGeometryEffect(id: "underline", in: animationNamespace)
                        } else {
                            Color.clear
                                .frame(height: 3)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct CustomSegmentControl_Previews: PreviewProvider {
    static var previews: some View {
        CustomSegmentControl(titles: ["全部", "工作", "社交", "金融"], selectedIndex: .constant(0))
            .padding(.vertical)
            .background(Color.black.opacity(0.05))
            .previewLayout(.sizeThatFits)
    }
}
