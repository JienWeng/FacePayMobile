//
//  TransactionView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct TransactionView: View {
    let card: CardData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                        
                        Text("Transactions")
                            .font(.custom("Graphik-Black", size: 24))
                            .fontWeight(.black)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Invisible placeholder for alignment
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // Card preview (smaller)
                    CardView(
                        holderName: card.holderName,
                        cardNumber: card.cardNumber,
                        expiryDate: card.expiryDate,
                        gradientColors: card.gradientColors,
                        cardType: card.cardType
                    )
                    .scaleEffect(0.8)
                    .padding(.bottom, 20)
                    
                    // Transactions list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if card.transactions.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 50, weight: .black))
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("No Transactions Yet")
                                        .font(.custom("Graphik-Black", size: 20))
                                        .fontWeight(.black)
                                        .foregroundColor(.gray)
                                    
                                    Text("Your transaction history will appear here")
                                        .font(.custom("Graphik-Bold", size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(card.transactions) { transaction in
                                    TransactionRowView(transaction: transaction)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct TransactionRowView: View {
    let transaction: TransactionData
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.primaryYellow)
                    .frame(width: 50, height: 50)
                Image(systemName: transaction.icon)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
            }
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.custom("Graphik-Black", size: 16))
                    .fontWeight(.black)
                    .foregroundColor(.black)
                
                Text(formatDate(transaction.date))
                    .font(.custom("Graphik-Bold", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Amount
            Text(formatAmount(transaction.amount))
                .font(.custom("Graphik-Black", size: 16))
                .fontWeight(.black)
                .foregroundColor(transaction.amount >= 0 ? .green : .black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleCard = CardData(
        holderName: "John",
        cardNumber: "1234 5678 9123 4567",
        expiryDate: "12/25",
        cvv: "123",
        gradientColors: [Color.blue, Color.purple],
        cardType: "Visa"
    )
    
    TransactionView(card: sampleCard)
}
