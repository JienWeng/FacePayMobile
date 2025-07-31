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
                    .font(.custom("Graphik-Black", size: 28))
                    .fontWeight(.black)
                    .foregroundColor(.black)
                
                Text("Enter your phone number for verification")
                    .font(.custom("Graphik-Bold", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Phone number input with underline
            VStack(spacing: 8) {
                TextField("", text: $phoneNumber)
                    .placeholder(when: phoneNumber.isEmpty) {
                        Text("Enter phone number")
                            .font(.custom("Graphik-Bold", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .font(.custom("Graphik-Black", size: 18))
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .keyboardType(.phonePad)
                    .focused($isPhoneNumberFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 32)
                
                // Thick black underline
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 3)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                if !phoneNumber.isEmpty {
                    onNext()
                }
            }) {
                Text("Continue")
                    .font(.custom("Graphik-Black", size: 18))
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(phoneNumber.isEmpty ? Color.gray.opacity(0.3) : Color.primaryYellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .cornerRadius(12)
            }
            .disabled(phoneNumber.isEmpty)
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            isPhoneNumberFocused = true
        }
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
