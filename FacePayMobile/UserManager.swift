//
//  UserManager.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI

class UserManager: ObservableObject {
    @Published var currentUser: User
    @Published var isSignedIn: Bool = false
    @Published var userCards: [CardData] = []
    
    private let userDefaults = UserDefaults.standard
    private let userNameKey = "SavedUserName"
    private let icNumberKey = "SavedICNumber"
    private let phoneNumberKey = "SavedPhoneNumber"
    private let userCardsKey = "SavedUserCards"
    
    init() {
        let savedName = userDefaults.string(forKey: userNameKey) ?? "User"
        let savedICNumber = userDefaults.string(forKey: icNumberKey) ?? ""
        let savedPhoneNumber = userDefaults.string(forKey: phoneNumberKey) ?? ""
        self.currentUser = User(name: savedName, faceData: nil, icNumber: savedICNumber, phoneNumber: savedPhoneNumber)
        self.loadUserCards()
    }
    
    func loadUserData() {
        let savedName = userDefaults.string(forKey: userNameKey) ?? "User"
        let savedICNumber = userDefaults.string(forKey: icNumberKey) ?? ""
        let savedPhoneNumber = userDefaults.string(forKey: phoneNumberKey) ?? ""
        currentUser = User(name: savedName, faceData: currentUser.faceData, icNumber: savedICNumber, phoneNumber: savedPhoneNumber)
        loadUserCards()
    }
    
    func updateUserName(_ name: String) {
        currentUser = User(name: name, faceData: currentUser.faceData, icNumber: currentUser.icNumber, phoneNumber: currentUser.phoneNumber)
        userDefaults.set(name, forKey: userNameKey)
    }
    
    func updateUserFromIC(name: String, icNumber: String) {
        currentUser = User(name: name, faceData: currentUser.faceData, icNumber: icNumber, phoneNumber: currentUser.phoneNumber)
        userDefaults.set(name, forKey: userNameKey)
        userDefaults.set(icNumber, forKey: icNumberKey)
    }
    
    func updatePhoneNumber(_ phoneNumber: String) {
        currentUser = User(name: currentUser.name, faceData: currentUser.faceData, icNumber: currentUser.icNumber, phoneNumber: phoneNumber)
        userDefaults.set(phoneNumber, forKey: phoneNumberKey)
    }
    
    // Card management functions
    func addCard(_ card: CardData) {
        // Associate card with current user by IC number
        var cardWithUserInfo = card
        cardWithUserInfo.holderName = currentUser.name
        userCards.append(cardWithUserInfo)
        saveUserCards()
    }
    
    func removeCard(at index: Int) {
        guard index < userCards.count else { return }
        userCards.remove(at: index)
        saveUserCards()
    }
    
    private func loadUserCards() {
        if let data = userDefaults.data(forKey: userCardsKey),
           let cards = try? JSONDecoder().decode([CardData].self, from: data) {
            // Filter cards for current user (by IC number or name)
            userCards = cards.filter { card in
                return card.holderName == currentUser.name || 
                       (currentUser.icNumber.isEmpty == false && card.userICNumber == currentUser.icNumber)
            }
        }
    }
    
    private func saveUserCards() {
        // Add user identification to cards before saving
        let cardsWithUserInfo = userCards.map { card in
            var updatedCard = card
            updatedCard.userICNumber = currentUser.icNumber
            updatedCard.holderName = currentUser.name
            return updatedCard
        }
        
        if let data = try? JSONEncoder().encode(cardsWithUserInfo) {
            userDefaults.set(data, forKey: userCardsKey)
        }
    }
    
    func signIn() {
        isSignedIn = true
    }
    
    func signOut() {
        isSignedIn = false
        userCards = []
    }
}

struct User {
    let name: String
    var faceData: Data?
    let icNumber: String
    let phoneNumber: String
}
