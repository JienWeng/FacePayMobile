//
//  WalletCardStackView.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

struct WalletCardStackView: View {
    @Binding var cards: [CardData]
    let onCardTapped: (CardData) -> Void
    
    @State private var cardOffsets: [CGSize] = []
    @State private var cardRotation: Double = 0.0
    @State private var cardScale: CGFloat = 1.0
    @GestureState private var dragOffset = CGSize.zero
    
    init(cards: Binding<[CardData]>, onCardTapped: @escaping (CardData) -> Void) {
        self._cards = cards
        self.onCardTapped = onCardTapped
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                CardView(
                    holderName: card.holderName,
                    cardNumber: card.cardNumber,
                    expiryDate: card.expiryDate,
                    gradientColors: card.gradientColors,
                    cardType: card.cardType
                )
                .offset(cardOffsets.count > index ? cardOffsets[index] : .zero)
                .rotationEffect(.degrees(index == 0 ? cardRotation : 0))
                .scaleEffect(index == 0 ? cardScale : 0.95)
                .opacity(index == 0 ? 1.0 : 0.8)
                .zIndex(Double(cards.count - index))
                .onTapGesture {
                    if index == 0 {
                        onCardTapped(card)
                    }
                }
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, offset, _ in
                            offset = value.translation
                        }
                        .onChanged { value in
                            if index == 0 && cardOffsets.count > index {
                                cardOffsets[index] = value.translation
                                cardRotation = Double(value.translation.width / 10)
                                cardScale = 1.0 - abs(value.translation.width) / 1000
                            }
                        }
                        .onEnded { value in
                            let swipeThreshold: CGFloat = 100
                            if abs(value.translation.width) > swipeThreshold && index == 0 {
                                // Move the first card to the back
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if cardOffsets.count > index {
                                        cardOffsets[index] = CGSize(
                                            width: value.translation.width > 0 ? 1000 : -1000,
                                            height: 0
                                        )
                                    }
                                    
                                    // After animation delay, move card to back
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        let movedCard = cards.removeFirst()
                                        cards.append(movedCard)
                                        cardOffsets = Array(repeating: CGSize.zero, count: cards.count)
                                        cardScale = 1.0
                                        cardRotation = 0
                                    }
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    if cardOffsets.count > index {
                                        cardOffsets[index] = .zero
                                    }
                                    cardScale = 1.0
                                    cardRotation = 0
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cardOffsets.count > index ? cardOffsets[index] : .zero)
            }
        }
        .frame(width: 350, height: 250)
        .onAppear {
            cardOffsets = Array(repeating: CGSize.zero, count: cards.count)
        }
        .onChange(of: cards.count) { newCount in
            cardOffsets = Array(repeating: CGSize.zero, count: newCount)
        }
    }
}

#Preview {
    @State var sampleCards = [
        CardData(holderName: "John", cardNumber: "1234 5678 9123 4567", expiryDate: "12/25", cvv: "123", gradientColors: [Color.blue, Color.purple], cardType: "Visa"),
        CardData(holderName: "John", cardNumber: "9876 5432 1098 7654", expiryDate: "11/26", cvv: "456", gradientColors: [Color.red, Color.orange], cardType: "Mastercard")
    ]
    
    WalletCardStackView(cards: $sampleCards) { card in
        print("Tapped card: \(card.holderName)")
    }
}
