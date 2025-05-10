import UIKit

class AccountDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var futureBalanceLabel: UILabel!
    
    var selectedAccount: Account?
    var transactions: [Transaction] = []
    var selectedTransactionType: TransactionType = .paid
    var selectedDate: Date = Date()
    
    var filteredTransactions: [Transaction] = []
    var isFiltering = false
    
    // Add these two properties to store the start and end dates for filtering
    var selectedStartDate: Date?  // For the start date filter
    var selectedEndDate: Date?    // For the end date filter
    
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
        return isFiltering ? filteredTransactions.count : transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        
        let transaction = isFiltering ? filteredTransactions[indexPath.row] : transactions[indexPath.row]
        
        if let descriptionLabel = cell.viewWithTag(1) as? UILabel {
            descriptionLabel.text = transaction.description
        }
        
        if let amountLabel = cell.viewWithTag(2) as? UILabel {
            amountLabel.text = "\(String(format: "%.2f", transaction.amount)) TL"
        }
        
        if let typeLabel = cell.viewWithTag(3) as? UILabel {
            typeLabel.text = transaction.type.rawValue
        }
        
        if let dateLabel = cell.viewWithTag(4) as? UILabel {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateLabel.text = formatter.string(from: transaction.date)
        }
        
        return cell
    }
    
    // MARK: - Swipe to Delete Transaction
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let transactionToDelete = self.transactions[indexPath.row]
            self.transactions.remove(at: indexPath.row)
            
            guard var updatedAccount = self.selectedAccount else { return }
            
            switch transactionToDelete.type {
            case .paid:
                updatedAccount.currentBalance += transactionToDelete.amount
            case .received:
                updatedAccount.currentBalance -= transactionToDelete.amount
            case .payable:
                updatedAccount.futureBalance += transactionToDelete.amount
            case .receivable:
                updatedAccount.futureBalance -= transactionToDelete.amount
            }
            
            updatedAccount.transactions = self.transactions
            self.selectedAccount = updatedAccount
            
            self.updateBalanceLabels(account: updatedAccount)
            self.saveTransactions(account: updatedAccount)
            self.transactionsTableView.deleteRows(at: [indexPath], with: .automatic)
            
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func updateBalanceLabels(account: Account) {
        currentBalanceLabel.text = "Current: \(String(format: "%.2f", account.currentBalance)) TL"
        futureBalanceLabel.text = "Future: \(String(format: "%.2f", account.futureBalance)) TL"
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
    }
    
    // MARK: - Filter
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Filter", message: nil, preferredStyle: .alert)
        
        var selectedType: TransactionType?
        var selectedStartDate: Date?
        var selectedEndDate: Date?
        
        // Transaction Type Picker
        alertController.addTextField { textField in
            textField.placeholder = "Select Transaction Type (Optional)"
            textField.tintColor = .clear
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            pickerView.tag = 1000 // We set a tag to distinguish between the pickers
            
            textField.inputView = pickerView
            
            if let defaultIndex = TransactionType.allCases.firstIndex(of: self.selectedTransactionType) {
                pickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
            }
        }
        
        // Start Date TextField
        alertController.addTextField { textField in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            textField.placeholder = "Select Start Date (Optional)"
            textField.tintColor = .clear
            textField.inputView = self.createDatePicker(for: textField, isStartDate: true)
        }
        
        // End Date TextField
        alertController.addTextField { textField in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            textField.placeholder = "Select End Date (Optional)"
            textField.tintColor = .clear
            textField.inputView = self.createDatePicker(for: textField, isStartDate: false)
        }
        
        let filterAction = UIAlertAction(title: "Filter", style: .default) { _ in
            var filteredList = self.transactions
            
            // Apply filters
            if let type = selectedType {
                filteredList = filteredList.filter { $0.type == type }
            }
            
            if let startDate = selectedStartDate {
                filteredList = filteredList.filter { $0.date >= startDate }
            }
            
            if let endDate = selectedEndDate {
                filteredList = filteredList.filter { $0.date <= endDate }
            }
            
            self.filteredTransactions = filteredList
            self.isFiltering = true
            self.transactionsTableView.reloadData()
        }
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.filteredTransactions.removeAll()
            self.isFiltering = false
            self.transactionsTableView.reloadData()
        }
        
        alertController.addAction(filterAction)
        alertController.addAction(clearAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alertController, animated: true)
    }
    
    // Helper function to create a date picker for the given text field
    func createDatePicker(for textField: UITextField, isStartDate: Bool) -> UIView {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        
        // Set default date only if the date is not nil
        if isStartDate {
            datePicker.date = selectedStartDate ?? Date()  // If no start date is selected, use today's date
        } else {
            datePicker.date = selectedEndDate ?? Date()  // If no end date is selected, use today's date
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // Add action to capture the date selection
        datePicker.addAction(UIAction(handler: { _ in
            let selectedDate = datePicker.date
            textField.text = formatter.string(from: selectedDate)
            
            // Update the selected date based on which field is being updated
            if isStartDate {
                self.selectedStartDate = selectedDate
            } else {
                self.selectedEndDate = selectedDate
            }
        }), for: .valueChanged)
        
        return datePicker
    }
    
    
    
    
    
    // MARK: - Add New Transaction
    @IBAction func newTransactionButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "New Transaction", message: nil, preferredStyle: .alert)
        
        // Description
        alertController.addTextField { textField in
            textField.placeholder = "Description"
        }
        
        // Amount
        alertController.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        // Transaction Type - Picker
        var typeTextField: UITextField?
        alertController.addTextField { textField in
            textField.placeholder = "Select Transaction Type"
            textField.tintColor = .clear
            typeTextField = textField
            
            textField.text = self.selectedTransactionType.rawValue
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            
            if let defaultIndex = TransactionType.allCases.firstIndex(of: self.selectedTransactionType) {
                pickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
            }
            
            textField.inputView = pickerView
        }
        
        
        // Date Picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.date = selectedDate
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        alertController.addTextField { textField in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            textField.placeholder = "Select Date"
            textField.text = formatter.string(from: self.selectedDate)
            textField.inputView = datePicker
            textField.tintColor = .clear
            
            datePicker.addAction(UIAction(handler: { _ in
                self.selectedDate = datePicker.date
                textField.text = formatter.string(from: datePicker.date)
            }), for: .valueChanged)
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let description = alertController.textFields?[0].text, !description.isEmpty,
                  let amountText = alertController.textFields?[1].text, let amount = Double(amountText) else {
                return
            }
            
            let newTransaction = Transaction(description: description, amount: amount, type: self.selectedTransactionType, date: self.selectedDate)
            self.transactions.insert(newTransaction, at: 0)
            
            if var account = self.selectedAccount {
                switch newTransaction.type {
                case .paid:
                    account.currentBalance -= amount
                case .received:
                    account.currentBalance += amount
                case .payable:
                    account.futureBalance -= amount
                case .receivable:
                    account.futureBalance += amount
                }
                
                account.transactions = self.transactions
                self.selectedAccount = account
                self.updateBalanceLabels(account: account)
                self.saveTransactions(account: account)
                self.transactionsTableView.reloadData()
            }
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
            transactions = savedAccount.transactions
        } else {
            if let initialAccount = selectedAccount {
                transactions = initialAccount.transactions
            }
        }
    }
    
    func saveTransactions(account: Account) {
        let individualAccountKey = "account_\(account.email)"
        if let individualAccountData = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(individualAccountData, forKey: individualAccountKey)
        } else {
            print("Error: Could not save individual account.")
        }
        
        let allAccountsKey = "savedAccounts"
        var currentAccountsArray: [Account] = []
        if let savedAccountsData = UserDefaults.standard.data(forKey: allAccountsKey),
           let decodedAccounts = try? JSONDecoder().decode([Account].self, from: savedAccountsData) {
            currentAccountsArray = decodedAccounts
        } else {
            print("Warning: Could not load existing 'savedAccounts' array.")
        }
        
        if let index = currentAccountsArray.firstIndex(where: { $0.email == account.email }) {
            currentAccountsArray[index] = account
        } else {
            print("Error: Account not found in 'savedAccounts' array.")
        }
        
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
        
        // Determine which alert controller is currently presented and update the corresponding text field
        if let alert = self.presentedViewController as? UIAlertController {
            if pickerView.tag == 1000 { // This is the filter picker
                if let typeField = alert.textFields?.first(where: { $0.placeholder == "Select Transaction Type (Optional)" }) {
                    typeField.text = selectedTransactionType.rawValue
                }
            } else { // This is the 'Add New Transaction' picker
                if let typeField = alert.textFields?.first(where: { $0.placeholder == "Select Transaction Type" }) {
                    typeField.text = selectedTransactionType.rawValue
                }
            }
        }
    }
    
}
