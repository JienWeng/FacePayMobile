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
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo - Face ID
                VStack(spacing: 20) {
                    Image(systemName: "faceid")
                        .font(.system(size: 80, weight: .black))
                        .foregroundColor(.primaryYellow)
                    
                    Text("FacePay")
                        .font(.custom("Graphik-Black", size: 36))
                        .foregroundColor(.black)
                        .fontWeight(.black)
                        .bold()
                }
                
                Spacer()
                
                // Description
                VStack(spacing: 16) {
                    Text("Easiest way to pay")
                        .font(.custom("Graphik-Black", size: 18))
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .bold()
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Text("Get Started")
                            .font(.custom("Graphik-Black", size: 18))
                            .fontWeight(.black)
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
                        Text("Sign In")
                            .font(.custom("Graphik-Black", size: 18))
                            .fontWeight(.black)
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
