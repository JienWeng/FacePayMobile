//
//  PhoneNumberStep.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct PhoneNumberStep: View {
    let onNext: () -> Void
    @State private var phoneNumber: String = ""
    @FocusState private var isPhoneNumberFocused: Bool
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: "phone.fill")
                .font(.system(size: 60, weight: .black))
                .foregroundColor(.primaryYellow)
            
            // Title and description  
            VStack(spacing: 16) {
                Text("Phone Number")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.black)
                
                if !userManager.currentUser.name.isEmpty {
                    Text("Hi \(userManager.currentUser.name)! Please enter your phone number")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Text("Please enter your phone number")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            // Phone number input only
            VStack(spacing: 8) {
                TextField("", text: $phoneNumber)
                    .placeholder(when: phoneNumber.isEmpty) {
                        Text("Phone number")
                            .font(.system(size: 18, weight: .medium, design: .default))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.black)
                    .keyboardType(.phonePad)
                    .focused($isPhoneNumberFocused)
                    .textContentType(.telephoneNumber)
                
                Rectangle()
                    .fill(isPhoneNumberFocused ? Color.primaryYellow : Color.gray.opacity(0.3))
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: isPhoneNumberFocused)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Continue button
            Button(action: {
                // Save the phone number and proceed
                userManager.updatePhoneNumber(phoneNumber)
                onNext()
            }) {
                HStack {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.black)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(phoneNumber.isValidPhoneNumber ? Color.primaryYellow : Color.gray.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 3)
                )
            }
            .disabled(!phoneNumber.isValidPhoneNumber)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onTapGesture {
            isPhoneNumberFocused = false
        }
        .onAppear {
            // Load existing user data when view appears
            userManager.loadUserData()
        }
    }
}

extension String {
    var isValidPhoneNumber: Bool {
        let phoneRegex = #"^[\+]?[0-9\-\(\)\s]{8,15}$"#
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: self)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    PhoneNumberStep(onNext: {})
}
