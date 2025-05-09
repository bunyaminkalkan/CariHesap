//
//  Account.swift
//  CariHesap-Bunyamin
//
//  Created by Trakya6 on 5.05.2025.
//

import Foundation

struct Account: Codable {
    var name: String
    var email: String // Örnek olarak e-posta da ekledik
    var currentBalance: Double
    var futureBalance: Double
    var transactions: [Transaction]
}
