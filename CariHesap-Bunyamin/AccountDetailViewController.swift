import UIKit

class AccountDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var futureBalanceLabel: UILabel!
    
    var selectedAccount: Account?
    var transactions: [Transaction] = []
    var selectedTransactionType: TransactionType = .received // Default value
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transactionsTableView.dataSource = self
        transactionsTableView.delegate = self
        
        loadTransactions()
        
        if let account = selectedAccount {
            updateBalanceLabels(account: account)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        
        let transaction = transactions[indexPath.row]
        
        // Configure Description Label
        if let descriptionLabel = cell.viewWithTag(1) as? UILabel {
            descriptionLabel.text = transaction.description
        }
        
        // Configure Amount Label
        if let amountLabel = cell.viewWithTag(2) as? UILabel {
            amountLabel.text = "\(String(format: "%.2f", transaction.amount)) TL"
        }
        
        // Configure Transaction Type Label
        if let typeLabel = cell.viewWithTag(3) as? UILabel {
            typeLabel.text = transaction.type.rawValue
        }
        
        return cell
    }
    
    func updateBalanceLabels(account: Account) {
        currentBalanceLabel.text = "Current: \(String(format: "%.2f", account.currentBalance)) TL"
        futureBalanceLabel.text = "Future: \(String(format: "%.2f", account.futureBalance)) TL"
    }
    
    // MARK: - Add New Transaction
    @IBAction func newTransactionButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "New Transaction", message: nil, preferredStyle: .alert)
        
        // Description TextField
        alertController.addTextField { textField in
            textField.placeholder = "Description"
        }
        
        // Amount TextField
        alertController.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        // Transaction Type TextField (for picker)
        var typeTextField: UITextField?
        alertController.addTextField { textField in
            textField.placeholder = "Select Transaction Type"
            textField.tintColor = .clear // Hide cursor
            typeTextField = textField
            
            // Picker settings
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            textField.inputView = pickerView
        }
        
        // Add Button
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let desc = alertController.textFields?[0].text, !desc.isEmpty,
                  let amtStr = alertController.textFields?[1].text, let amount = Double(amtStr),
                  let selectedType = self.selectedTransactionType as TransactionType? else { // Use the stored selectedTransactionType
                return
            }
            
            let newTransaction = Transaction(description: desc, amount: amount, type: selectedType)
            self.transactions.append(newTransaction)
            
            // Update account
            guard var updatedAccount = self.selectedAccount else { return }
            
            switch selectedType {
            case .paid:
                updatedAccount.currentBalance -= amount
            case .received:
                updatedAccount.currentBalance += amount
            case .payable:
                updatedAccount.futureBalance -= amount
            case .receivable:
                updatedAccount.futureBalance += amount
            }
            
            updatedAccount.transactions.append(newTransaction)
            self.selectedAccount = updatedAccount
            
            self.updateBalanceLabels(account: updatedAccount)
            self.saveTransactions(account: updatedAccount)  // Save operation here
            self.transactionsTableView.reloadData()
        }
        
        alertController.addAction(addAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    // MARK: - Persistence
    func loadTransactions() {
        guard let account = selectedAccount else { return }
        
        let accountKey = "account_\(account.email)"
        if let accData = UserDefaults.standard.data(forKey: accountKey),
           let savedAccount = try? JSONDecoder().decode(Account.self, from: accData) {
            selectedAccount = savedAccount
            transactions = savedAccount.transactions // Load transactions associated with the account
        } else {
             // If no specific persisted version, use transactions from the passed selectedAccount
            if let initialAccount = selectedAccount {
                 transactions = initialAccount.transactions
            }
        }
    }

    // Function to save the account and the main accounts list
    func saveTransactions(account: Account) {
        // 1. Update the individual account record (your current behavior)
        let individualAccountKey = "account_\(account.email)"
        if let individualAccountData = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(individualAccountData, forKey: individualAccountKey)
        } else {
            print("Error: Could not save individual account.")
        }

        // 2. Load the main array of accounts from UserDefaults
        let allAccountsKey = "savedAccounts"
        var currentAccountsArray: [Account] = []
        if let savedAccountsData = UserDefaults.standard.data(forKey: allAccountsKey),
           let decodedAccounts = try? JSONDecoder().decode([Account].self, from: savedAccountsData) {
            currentAccountsArray = decodedAccounts
        } else {
            // If "savedAccounts" cannot be found or decoded, this could be an issue.
            // For now, we assume it should exist if we are updating an account from the list.
            print("Warning: Could not load existing 'savedAccounts' array.")
        }

        // 3. Find the updated account in the array and replace it
        if let index = currentAccountsArray.firstIndex(where: { $0.email == account.email }) {
            currentAccountsArray[index] = account // Replace the old account struct with the new one
        } else {
            // This means the account being modified in the detail view was not found in the main "savedAccounts" list.
            // This could be due to a data inconsistency or a different flow.
            // Ideally, you might add the account here, but based on your current flow, this might be an error state.
            print("Error: Account with email \(account.email) not found in 'savedAccounts' array. The main list will not reflect this update.")
            // If your application logic ensures accounts are always in "savedAccounts" before the detail view, this is an error state.
            // Depending on the situation, you might do: currentAccountsArray.append(account)
        }

        // 4. Save the updated main array of accounts back to UserDefaults
        if let updatedAccountsData = try? JSONEncoder().encode(currentAccountsArray) {
            UserDefaults.standard.set(updatedAccountsData, forKey: allAccountsKey)
        } else {
            print("Error: Could not save 'savedAccounts' array.")
        }
    }
}

extension AccountDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TransactionType.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return TransactionType.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTransactionType = TransactionType.allCases[row]
        
        // Update the transaction type textField on the alert
        if let alert = self.presentedViewController as? UIAlertController,
           let typeField = alert.textFields?.first(where: { $0.placeholder == "Select Transaction Type" }) {
            typeField.text = selectedTransactionType.rawValue
        }
    }
}
