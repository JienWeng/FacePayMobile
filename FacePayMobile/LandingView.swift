//
//  LandingView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct LandingView: View {
    @State private var showOnboarding = false
    @State private var showSignIn = false
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        ZStack {
            // Animated cloudy white and yellow background
            ZStack {
                // Base white background
                Color.white
                    .ignoresSafeArea()
                
                // Animated flowing yellow clouds
                GeometryReader { geometry in
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.primaryYellow.opacity(0.15),
                                        Color.primaryYellow.opacity(0.05),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(
                                width: CGFloat.random(in: 80...200),
                                height: CGFloat.random(in: 80...200)
                            )
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 3...6))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.5),
                                value: UUID()
                            )
                    }
                }
                
                // Additional subtle white clouds
                GeometryReader { geometry in
                    ForEach(0..<3, id: \.self) { index in
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: CGFloat.random(in: 150...300),
                                height: CGFloat.random(in: 60...120)
                            )
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .animation(
                                Animation.linear(duration: Double.random(in: 8...12))
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 1.0),
                                value: UUID()
                            )
                    }
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo - Face ID
                VStack(spacing: 20) {
                    Image(systemName: "faceid")
                        .font(.system(size: 80, weight: .black))
                        .foregroundColor(.primaryYellow)
                    
                    Text("FacePay")
                        .font(.system(size: 36, weight: .black, design: .default))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Description
                VStack(spacing: 16) {
                    Text("Easiest way to pay")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primaryYellow)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 5)
                            )
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showSignIn = true
                    }) {
                        Text("Sign In with Face ID")
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 5)
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $showSignIn) {
            FaceSignInView(userManager: userManager)
        }
        .fullScreenCover(isPresented: $userManager.isSignedIn) {
            DashboardView(userManager: userManager)
        }
    }
}

#Preview {
    LandingView()
}
