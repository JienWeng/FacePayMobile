//
//  FaceSignInView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct FaceSignInView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var signInSuccess = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Sign In")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Invisible placeholder for alignment
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                if !signInSuccess {
                    // Face sign in prompt
                    VStack(spacing: 20) {
                        Image(systemName: "faceid")
                            .font(.system(size: 80, weight: .black))
                            .foregroundColor(.primaryYellow)
                        
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.black)
                        
                        Text("Use Face ID to sign in securely")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Sign in button
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .font(.system(size: 20, weight: .black))
                            Text("Sign In with Face ID")
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
                } else {
                    // Success state
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .black))
                            .foregroundColor(.green)
                        
                        Text("Welcome, \(userManager.currentUser.name)!")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.black)
                        
                        Text("You have been signed in successfully")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            FaceSignInCameraView(
                onSignInSuccess: {
                    showingCamera = false
                    signInSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        userManager.signIn()
                        dismiss()
                    }
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
    }
}

#Preview {
    FaceSignInView(userManager: UserManager())
}
