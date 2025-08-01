//
//  CardProviderNotification.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct CardProviderNotification: View {
    let cardType: String
    let cardNumber: String
    let userName: String
    let onConfirm: () -> Void
    let onDeny: () -> Void
    @State private var slideOffset: CGFloat = 500
    @State private var opacity: Double = 0
    
    private var providerInfo: (name: String, color: Color, logo: String) {
        switch cardType {
        case "Visa":
            return ("Visa", .blue, "creditcard.fill")
        case "Mastercard":
            return ("Mastercard", .red, "creditcard.fill")
        case "American Express":
            return ("American Express", .green, "creditcard.fill")
        default:
            return ("Bank", .gray, "creditcard.fill")
        }
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(opacity)
            
            VStack {
                Spacer()
                
                // Notification card
                VStack(spacing: 20) {
                    // Provider header
                    HStack {
                        Image(systemName: providerInfo.logo)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(providerInfo.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(providerInfo.name)
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundColor(.black)
                            
                            Text("Card Binding Request")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    // Message content
                    VStack(spacing: 12) {
                        Text("FacePay Binding Request")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.black)
                        
                        Text("Are you sure you want to bind your \(providerInfo.name) card ending in \(String(cardNumber.suffix(4))) to FacePay for \(userName)?")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        // Security notice
                        HStack {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("This is a secure transaction")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onDeny) {
                            Text("Deny")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                                .cornerRadius(8)
                        }
                        
                        Button(action: onConfirm) {
                            Text("Confirm")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(providerInfo.color)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .offset(y: slideOffset)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                slideOffset = 0
                opacity = 1
            }
        }
    }
}

struct CardProviderNotificationManager {
    static func simulateNotification(for cardType: String, cardNumber: String, userName: String, onConfirm: @escaping () -> Void, onDeny: @escaping () -> Void) -> CardProviderNotification {
        // Simulate a delay as if the notification came from the provider
        return CardProviderNotification(
            cardType: cardType,
            cardNumber: cardNumber,
            userName: userName,
            onConfirm: onConfirm,
            onDeny: onDeny
        )
    }
}

#Preview {
    CardProviderNotification(
        cardType: "Visa",
        cardNumber: "1234567890123456",
        userName: "John Doe",
        onConfirm: {},
        onDeny: {}
    )
}
