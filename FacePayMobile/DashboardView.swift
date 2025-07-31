//
//  DashboardView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var userManager: UserManager
    @State private var cards: [CardData] = []
    @State private var showingAddCard = false
    @State private var selectedCard: CardData?
    @State private var showingTransactions = false
    @State private var showingManageCards = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome,")
                                .font(.custom("Graphik-Bold", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text(userManager.currentUser.name)
                                .font(.custom("Graphik-Black", size: 32))
                                .fontWeight(.black)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            userManager.signOut()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .black))
                                Text("Log out")
                                    .font(.custom("Graphik-Black", size: 16))
                                    .fontWeight(.black)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if cards.isEmpty {
                        // Empty state - show add card prompt
                        VStack(spacing: 30) {
                            Spacer()
                            
                            // Add card visual
                            VStack(spacing: 20) {
                                Button(action: {
                                    showingAddCard = true
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: 3)
                                            .frame(width: 300, height: 200)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 40, weight: .black))
                                            .foregroundColor(.primaryYellow)
                                    }
                                }
                                
                                Text("Add Your First Card")
                                    .font(.custom("Graphik-Black", size: 24))
                                    .fontWeight(.black)
                                    .foregroundColor(.black)
                                
                                Text("Add a credit or debit card to start using FacePay")
                                    .font(.custom("Graphik-Bold", size: 16))
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            
                            Spacer()
                        }
                    } else {
                        // Cards stack view
                        ScrollView {
                            VStack(spacing: 20) {
                                WalletCardStackView(
                                    cards: $cards,
                                    onCardTapped: { card in
                                        selectedCard = card
                                        showingTransactions = true
                                    }
                                )
                                
                                // Add more cards button
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingAddCard = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .black))
                                            Text("Add Card")
                                                .font(.custom("Graphik-Black", size: 16))
                                                .fontWeight(.black)
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color.primaryYellow)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black, lineWidth: 3)
                                        )
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        showingManageCards = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "creditcard.viewfinder")
                                                .font(.system(size: 16, weight: .black))
                                            Text("Manage")
                                                .font(.custom("Graphik-Black", size: 16))
                                                .fontWeight(.black)
                                        }
                                        .foregroundColor(.primaryYellow)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color.black)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.primaryYellow, lineWidth: 3)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 20)
                                
                                // Recent Transactions Section
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Recent Transactions")
                                            .font(.custom("Graphik-Black", size: 22))
                                            .fontWeight(.black)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Button("See All") {
                                            if let firstCard = cards.first {
                                                selectedCard = firstCard
                                                showingTransactions = true
                                            }
                                        }
                                        .font(.custom("Graphik-Bold", size: 16))
                                        .foregroundColor(.primaryYellow)
                                    }
                                    
                                    if cards.isEmpty {
                                        Text("Add a card to see transactions")
                                            .font(.custom("Graphik-Bold", size: 16))
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 20)
                                    } else {
                                        VStack(spacing: 12) {
                                            // Show transactions from first card or selected card
                                            let displayCard = selectedCard ?? cards.first!
                                            ForEach(Array(displayCard.transactions.prefix(3).enumerated()), id: \.element.id) { index, transaction in
                                                Button {
                                                    selectedCard = displayCard
                                                    showingTransactions = true
                                                } label: {
                                                    HStack(spacing: 16) {
                                                        // Transaction icon
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.primaryYellow)
                                                                .frame(width: 50, height: 50)
                                                            Image(systemName: transaction.icon)
                                                                .font(.system(size: 20, weight: .black))
                                                                .foregroundColor(.black)
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(transaction.merchant)
                                                                .font(.custom("Graphik-Black", size: 16))
                                                                .fontWeight(.black)
                                                                .foregroundColor(.black)
                                                            Text(formatTransactionDate(transaction.date))
                                                                .font(.custom("Graphik-Bold", size: 14))
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(String(format: "$%.2f", abs(transaction.amount)))
                                                            .font(.custom("Graphik-Black", size: 16))
                                                            .fontWeight(.black)
                                                            .foregroundColor(.black)
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
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 30)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddCard) {
            AddCardView(userManager: userManager) { cardData in
                cards.append(cardData)
                showingAddCard = false
            }
        }
        .sheet(isPresented: $showingTransactions) {
            if let card = selectedCard {
                TransactionView(card: card)
            }
        }
        .sheet(isPresented: $showingManageCards) {
            ManageCardsView(cards: $cards)
        }
    }
    
    private func formatTransactionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CardData: Identifiable {
    let id = UUID()
    let holderName: String
    let cardNumber: String
    let expiryDate: String
    let cvv: String
    let gradientColors: [Color]
    let cardType: String
    var transactions: [TransactionData]
    
    init(holderName: String, cardNumber: String, expiryDate: String, cvv: String, gradientColors: [Color], cardType: String, transactions: [TransactionData] = []) {
        self.holderName = holderName
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.gradientColors = gradientColors
        self.cardType = cardType
        self.transactions = transactions.isEmpty ? TransactionData.sampleTransactions : transactions
    }
}

struct TransactionData: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let date: Date
    let icon: String
    
    static let sampleTransactions: [TransactionData] = [
        TransactionData(merchant: "Coffee Bean", amount: -4.50, date: Date().addingTimeInterval(-3600), icon: "cup.and.saucer.fill"),
        TransactionData(merchant: "Online Store", amount: -24.99, date: Date().addingTimeInterval(-86400), icon: "cart.fill"),
        TransactionData(merchant: "Gas Station", amount: -45.20, date: Date().addingTimeInterval(-172800), icon: "fuelpump.fill"),
        TransactionData(merchant: "Restaurant", amount: -35.75, date: Date().addingTimeInterval(-259200), icon: "fork.knife"),
        TransactionData(merchant: "Grocery Store", amount: -67.30, date: Date().addingTimeInterval(-345600), icon: "bag.fill")
    ]
}

#Preview {
    DashboardView(userManager: UserManager())
}
