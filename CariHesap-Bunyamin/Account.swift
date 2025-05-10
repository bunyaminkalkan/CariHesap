//
//  Account.swift
//  CariHesap-Bunyamin
//
//  Created by Trakya6 on 5.05.2025.
//

import Foundation

struct Account: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var currentBalance: Double
    var futureBalance: Double
    var transactions: [Transaction]
    
    // Convenience computed properties
    var formattedCurrentBalance: String {
        return String(format: "%.2f TL", currentBalance)
    }
    
    var formattedFutureBalance: String {
        return String(format: "%.2f TL", futureBalance)
    }
}
