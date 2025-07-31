//
//  ManageCardsView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct ManageCardsView: View {
    @Binding var cards: [CardData]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCard: CardData?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.primaryYellow)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3)
                                )
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Manage Cards")
                            .font(.custom("Graphik-Black", size: 24))
                            .fontWeight(.black)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if cards.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "creditcard")
                                .font(.system(size: 80, weight: .black))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No Cards Added")
                                .font(.custom("Graphik-Black", size: 24))
                                .fontWeight(.black)
                                .foregroundColor(.black)
                            
                            Text("Add a card to start managing your payment methods")
                                .font(.custom("Graphik-Bold", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                    } else {
                        // Cards list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(cards) { card in
                                    ManageCardRow(
                                        card: card,
                                        onDelete: {
                                            selectedCard = card
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Card", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let cardToDelete = selectedCard,
                   let index = cards.firstIndex(where: { $0.id == cardToDelete.id }) {
                    cards.remove(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete this card? This action cannot be undone.")
        }
    }
}

struct ManageCardRow: View {
    let card: CardData
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Mini card preview
            VStack(spacing: 0) {
                HStack {
                    Text(card.cardType.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Image(systemName: getCardLogo())
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Spacer()
                
                HStack {
                    Text("•••• •••• •••• \(String(card.cardNumber.suffix(4)))")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(width: 80, height: 50)
            .background(
                LinearGradient(
                    colors: card.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
            .cornerRadius(8)
            
            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(card.cardType) •••• \(String(card.cardNumber.suffix(4)))")
                    .font(.custom("Graphik-Black", size: 16))
                    .fontWeight(.black)
                    .foregroundColor(.black)
                
                Text(card.holderName.uppercased())
                    .font(.custom("Graphik-Bold", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text("Expires \(card.expiryDate)")
                    .font(.custom("Graphik-Bold", size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.red)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .clipShape(Circle())
            }
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
    
    private func getCardLogo() -> String {
        switch card.cardType.lowercased() {
        case "visa":
            return "creditcard.and.123"
        case "mastercard":
            return "creditcard.circle"
        case "american express":
            return "creditcard.trianglebadge.exclamationmark"
        default:
            return "creditcard"
        }
    }
}

#Preview {
    @State var sampleCards = [
        CardData(holderName: "John Doe", cardNumber: "1234 5678 9123 4567", expiryDate: "12/25", cvv: "123", gradientColors: [Color.blue, Color.purple], cardType: "Visa"),
        CardData(holderName: "John Doe", cardNumber: "5432 1098 7654 3210", expiryDate: "11/26", cvv: "456", gradientColors: [Color.red, Color.orange], cardType: "Mastercard")
    ]
    
    ManageCardsView(cards: $sampleCards)
}
