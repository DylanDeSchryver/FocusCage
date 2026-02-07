import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isActive = true
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
    var body: some View {
        if isActive {
            ZStack {
                themeManager.accentColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(themeManager.splashIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .scaleEffect(scale)
                    
                    Text("FocusCage")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        opacity = 0
                        scale = 0.9
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isActive = false
                    }
                }
            }
        }
    }
}
