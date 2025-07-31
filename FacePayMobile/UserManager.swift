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
    
    init() {
        self.currentUser = User(name: "John", faceData: nil)
    }
    
    func signIn() {
        isSignedIn = true
    }
    
    func signOut() {
        isSignedIn = false
    }
}

struct User {
    let name: String
    var faceData: Data?
}
