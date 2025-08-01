//
//  CardView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct CardView: View {
    let holderName: String
    let cardNumber: String
    let expiryDate: String
    let gradientColors: [Color]
    let cardType: String
    
    private func getCardLogo() -> String {
        switch cardType.lowercased() {
        case "visa":
            return "visa_logo"
        case "mastercard":
            return "mastercard_logo"
        case "american express", "amex":
            return "amex_logo"
        default:
            return "creditcard"
        }
    }
    
    private func isImageAsset() -> Bool {
        switch cardType.lowercased() {
        case "visa", "mastercard", "american express", "amex":
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(cardType.uppercased())
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Color.white)
                Spacer()
                if isImageAsset() {
                    Image(getCardLogo())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 24)
                } else {
                    Image(systemName: getCardLogo())
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // card chip
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 40, height: 32)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 10)
            
            Text(cardNumber)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .padding([.top, .bottom], 10)
            
            // Expiry Date
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VALID THROUGH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text(expiryDate)
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Color.white)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // Card Holder Name
            HStack {
                Text(holderName)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 10)
            
        }
        .frame(width: 300, height: 200)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    CardView(holderName: "John", cardNumber: "1234 5678 9123 4567", expiryDate: "12/25", gradientColors: [Color.blue, Color.purple], cardType: "Visa")
}
