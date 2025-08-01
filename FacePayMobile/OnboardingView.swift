//
//  OnboardingView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingDashboard = false
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    HStack {
                        Button(action: {
                            if currentStep > 0 {
                                currentStep -= 1
                            } else {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("Setup")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Invisible placeholder for alignment
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.primaryYellow : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    // Content based on current step
                    switch currentStep {
                    case 0:
                        ICWelcomeStep(onNext: { currentStep = 1 })
                    case 1:
                        ICScanStep(onNext: { currentStep = 2 })
                    case 2:
                        FaceRegistrationStep(onNext: { currentStep = 3 })
                    case 3:
                        PhoneNumberStep(onNext: { currentStep = 4 })
                    default:
                        CompletionStep(onComplete: {
                            showingDashboard = true
                        })
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingDashboard) {
            DashboardView(userManager: userManager)
        }
    }
}

struct CompletionStep: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80, weight: .black))
                .foregroundColor(.green)
            
            // Title and description
            VStack(spacing: 16) {
                Text("Setup Complete!")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.black)
                
                Text("Your FacePay account is ready to use")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Get started button
            Button(action: onComplete) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryYellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .navigationBarHidden(true)
    }
}

struct ICWelcomeStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 80, weight: .black))
                .foregroundColor(.primaryYellow)
            
            // Title and description
            VStack(spacing: 16) {
                Text("Scan Your IC")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.black)
                
                Text("We'll scan your identification card to verify your identity")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Continue button
            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryYellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Face Registration Step
struct FaceRegistrationStep: View {
    let onNext: () -> Void
    @State private var showingFaceRegistration = false
    @State private var isRegistrationComplete = false
    
    var body: some View {
        VStack(spacing: 30) {
            if !showingFaceRegistration && !isRegistrationComplete {
                // Initial face registration prompt
                VStack(spacing: 20) {
                    Image(systemName: "faceid")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.primaryYellow)
                    
                    Text("Face Registration")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.black)
                    
                    Text("Set up secure face authentication for quick payments")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Start Registration button
                Button(action: {
                    showingFaceRegistration = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid")
                            .font(.system(size: 20, weight: .black))
                        Text("Start Face Scan")
                            .font(.system(size: 18, weight: .bold, design: .default))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryYellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
            } else if isRegistrationComplete {
                // Registration complete
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Face Registered!")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.black)
                    
                    Text("Your face has been successfully registered for secure authentication")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryYellow)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
        }
        .fullScreenCover(isPresented: $showingFaceRegistration) {
            FaceRegistrationView()
                .onDisappear {
                    // Assume registration was completed when view dismisses
                    isRegistrationComplete = true
                }
        }
    }
}

#Preview {
    OnboardingView()
}
