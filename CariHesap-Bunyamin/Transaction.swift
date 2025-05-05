//
//  Transaction.swift
//  CariHesap-Bunyamin
//
//  Created by Trakya6 on 5.05.2025.
//

import Foundation

struct Transaction {
    var description: String
    var amount: Double
    var type: TransactionType // Alınacak, Verilecek, Alındı, Ödendi gibi
}

enum TransactionType: String, CaseIterable {
    case receivable = "Receivable"
    case payable = "Payable"
    case received = "Received"
    case paid = "Paid"
}
