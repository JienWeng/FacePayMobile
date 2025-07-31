//
//  AddCardView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct AddCardView: View {
    @ObservedObject var userManager: UserManager
    let onAddCard: (CardData) -> Void
    
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var selectedGradient: [Color] = [Color.blue, Color.purple]
    @Environment(\.dismiss) private var dismiss
    
    let gradientOptions: [[Color]] = [
        [Color.blue, Color.purple],
        [Color.red, Color.orange],
        [Color.green, Color.teal],
        [Color.pink, Color.yellow],
        [Color.indigo, Color.cyan]
    ]
    
    private var cardType: String {
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        guard let firstDigit = cleanNumber.first else { return "Unknown" }
        
        switch firstDigit {
        case "4":
            return "Visa"
        case "5", "2":
            return "Mastercard"
        case "3":
            return "American Express"
        default:
            return "Unknown"
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !expiryDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !cvv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("Add Card")
                            .font(.custom("Graphik-Black", size: 24))
                            .fontWeight(.black)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Invisible placeholder for alignment
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Card preview
                            CardView(
                                holderName: userManager.currentUser.name.uppercased(),
                                cardNumber: cardNumber.isEmpty ? "•••• •••• •••• ••••" : formatCardNumber(cardNumber),
                                expiryDate: expiryDate.isEmpty ? "MM/YY" : expiryDate,
                                gradientColors: selectedGradient,
                                cardType: cardType
                            )
                            .padding(.top, 20)
                            
                            // Form fields
                            VStack(spacing: 15) {
                                InputField(title: "Card Number", text: $cardNumber, placeholder: "1234 5678 9012 3456")
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { newValue in
                                        cardNumber = formatCardNumberInput(newValue)
                                    }
                                
                                HStack(spacing: 15) {
                                    InputField(title: "Expiry Date", text: $expiryDate, placeholder: "MM/YY")
                                        .keyboardType(.numberPad)
                                        .onChange(of: expiryDate) { newValue in
                                            expiryDate = formatExpiryDate(newValue)
                                        }
                                    
                                    InputField(title: "CVV", text: $cvv, placeholder: "123")
                                        .keyboardType(.numberPad)
                                        .onChange(of: cvv) { newValue in
                                            if newValue.count <= 4 {
                                                cvv = newValue
                                            }
                                        }
                                }
                                
                                // Detected card type display
                                if !cardNumber.isEmpty {
                                    HStack {
                                        Text("Detected Card Type:")
                                            .font(.custom("Graphik-Bold", size: 14))
                                            .foregroundColor(.gray)
                                        Text(cardType)
                                            .font(.custom("Graphik-Black", size: 14))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                }
                                
                                // Card gradient picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Card Style")
                                        .font(.custom("Graphik-Black", size: 16))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(0..<gradientOptions.count, id: \.self) { index in
                                            Button(action: {
                                                selectedGradient = gradientOptions[index]
                                            }) {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: gradientOptions[index],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.black, lineWidth: selectedGradient == gradientOptions[index] ? 3 : 1)
                                                    )
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Add card button
                            Button(action: {
                                let newCard = CardData(
                                    holderName: userManager.currentUser.name,
                                    cardNumber: cardNumber,
                                    expiryDate: expiryDate,
                                    cvv: cvv,
                                    gradientColors: selectedGradient,
                                    cardType: cardType
                                )
                                onAddCard(newCard)
                            }) {
                                Text("Add Card")
                                    .font(.custom("Graphik-Black", size: 18))
                                    .fontWeight(.black)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(isFormValid ? Color.primaryYellow : Color.gray.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 3)
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(!isFormValid)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let digits = number.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        
        for (index, character) in digits.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        return formatted
    }
    
    private func formatCardNumberInput(_ input: String) -> String {
        let digits = input.replacingOccurrences(of: " ", with: "")
        if digits.count <= 16 {
            return formatCardNumber(digits)
        }
        return cardNumber
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let digits = input.replacingOccurrences(of: "/", with: "")
        if digits.count <= 4 {
            if digits.count > 2 {
                let month = String(digits.prefix(2))
                let year = String(digits.suffix(digits.count - 2))
                return "\(month)/\(year)"
            }
            return digits
        }
        return expiryDate
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Graphik-Black", size: 16))
                .fontWeight(.black)
                .foregroundColor(.black)
            
            TextField(placeholder, text: $text)
                .font(.custom("Graphik-Bold", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.bottom, 8)
                .keyboardType(keyboardType)
                .overlay(
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 3),
                    alignment: .bottom
                )
        }
    }
}

#Preview {
    AddCardView(userManager: UserManager()) { _ in }
}
