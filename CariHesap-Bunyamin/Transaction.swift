//
//  Transaction.swift
//  CariHesap-Bunyamin
//
//  Created by Trakya6 on 5.05.2025.
//

import Foundation

struct Transaction: Codable {
    var description: String
    var amount: Double
    var type: TransactionType
}

enum TransactionType: String, CaseIterable, Codable {
    case paid = "Ödendi"
    case received = "Alındı"
    case payable = "Ödenecek"
    case receivable = "Alınacak"
}

