//
//  DashboardView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var userManager: UserManager
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
                                .font(.system(size: 18, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                            
                            Text(userManager.currentUser.name)
                                .font(.system(size: 32, weight: .bold, design: .default))
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
                                    .font(.system(size: 16, weight: .bold, design: .default))
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
                    
                    if userManager.userCards.isEmpty {
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
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .foregroundColor(.black)
                                
                                Text("Add a credit or debit card to start using FacePay")
                                    .font(.system(size: 16, weight: .medium, design: .default))
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
                                    cards: $userManager.userCards,
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
                                                .font(.system(size: 16, weight: .bold, design: .default))
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
                                                .font(.system(size: 16, weight: .bold, design: .default))
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
                                            .font(.system(size: 22, weight: .bold, design: .default))
                                            .foregroundColor(.black)
                                        Spacer()
                                        Button("See All") {
                                            if let firstCard = userManager.userCards.first {
                                                selectedCard = firstCard
                                                showingTransactions = true
                                            }
                                        }
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(.primaryYellow)
                                    }
                                    
                                    if userManager.userCards.isEmpty {
                                        Text("Add a card to see transactions")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 20)
                                    } else {
                                        VStack(spacing: 12) {
                                            // Show transactions from first card or selected card
                                            let displayCard = selectedCard ?? userManager.userCards.first!
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
                                                                .font(.system(size: 16, weight: .bold, design: .default))
                                                                .foregroundColor(.black)
                                                            Text(formatTransactionDate(transaction.date))
                                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(String(format: "$%.2f", abs(transaction.amount)))
                                                            .font(.system(size: 16, weight: .bold, design: .default))
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
                // Card will be added via system notification confirmation
                // No need to add card here anymore since it's handled by notification response
                showingAddCard = false
            }
        }
        .sheet(isPresented: $showingTransactions) {
            if let card = selectedCard {
                TransactionView(card: card)
            }
        }
        .sheet(isPresented: $showingManageCards) {
            ManageCardsView(userManager: userManager)
        }
    }
    
    private func formatTransactionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CardData: Identifiable, Codable {
    var id = UUID()
    var holderName: String
    let cardNumber: String
    let expiryDate: String
    let cvv: String
    let gradientColors: [Color]
    let cardType: String
    var transactions: [TransactionData]
    var userICNumber: String?
    
    init(holderName: String, cardNumber: String, expiryDate: String, cvv: String, gradientColors: [Color], cardType: String, transactions: [TransactionData] = [], userICNumber: String? = nil) {
        self.holderName = holderName
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.gradientColors = gradientColors
        self.cardType = cardType
        self.transactions = transactions.isEmpty ? TransactionData.sampleTransactions : transactions
        self.userICNumber = userICNumber
    }
    
    // Custom coding keys for proper encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, holderName, cardNumber, expiryDate, cvv, cardType, transactions, userICNumber
        case gradientColorsData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        holderName = try container.decode(String.self, forKey: .holderName)
        cardNumber = try container.decode(String.self, forKey: .cardNumber)
        expiryDate = try container.decode(String.self, forKey: .expiryDate)
        cvv = try container.decode(String.self, forKey: .cvv)
        cardType = try container.decode(String.self, forKey: .cardType)
        transactions = try container.decode([TransactionData].self, forKey: .transactions)
        userICNumber = try container.decodeIfPresent(String.self, forKey: .userICNumber)
        
        // Decode gradient colors from array of color components
        if let gradientData = try? container.decode([[Double]].self, forKey: .gradientColorsData) {
            gradientColors = gradientData.map { components in
                Color(red: components[0], green: components[1], blue: components[2])
            }
        } else {
            gradientColors = [Color.blue, Color.purple] // Default
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(holderName, forKey: .holderName)
        try container.encode(cardNumber, forKey: .cardNumber)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardType, forKey: .cardType)
        try container.encode(transactions, forKey: .transactions)
        try container.encodeIfPresent(userICNumber, forKey: .userICNumber)
        
        // Encode gradient colors as array of color components
        let gradientData = gradientColors.map { color in
            let uiColor = UIColor(color)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [Double(red), Double(green), Double(blue)]
        }
        try container.encode(gradientData, forKey: .gradientColorsData)
    }
}

struct TransactionData: Identifiable, Codable {
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
