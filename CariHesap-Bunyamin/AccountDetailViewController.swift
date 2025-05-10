import UIKit

class AccountDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var futureBalanceLabel: UILabel!
    
    // MARK: - Properties
    var selectedAccount: Account?
    var transactions: [Transaction] = []
    var selectedTransactionType: TransactionType = .paid
    var selectedDate: Date = Date()
    
    var filteredTransactions: [Transaction] = []
    var isFiltering = false
    
    // Add ID property to Transaction struct to track transactions
    private var transactionID = 0
    
    // Filter properties
    var selectedStartDate: Date?
    var selectedEndDate: Date?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transactionsTableView.dataSource = self
        transactionsTableView.delegate = self
        
        // Register for keyboard notifications to avoid UI issues
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        loadTransactions()
        
        if let account = selectedAccount {
            updateBalanceLabels(account: account)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            transactionsTableView.contentInset = contentInsets
            transactionsTableView.scrollIndicatorInsets = contentInsets
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        transactionsTableView.contentInset = .zero
        transactionsTableView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - UITableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredTransactions.count : transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        
        // Get the right transaction based on filtering state
        let transaction = isFiltering ? filteredTransactions[indexPath.row] : transactions[indexPath.row]
        
        configureCell(cell, with: transaction)
        
        return cell
    }
    
    // Extract cell configuration to a separate method for better readability
    private func configureCell(_ cell: UITableViewCell, with transaction: Transaction) {
        if let descriptionLabel = cell.viewWithTag(1) as? UILabel {
            descriptionLabel.text = transaction.description
        }
        
        if let amountLabel = cell.viewWithTag(2) as? UILabel {
            amountLabel.text = "\(String(format: "%.2f", transaction.amount)) TL"
            
            // Set color based on transaction type for better visual feedback
            switch transaction.type {
            case .paid, .payable:
                amountLabel.textColor = .systemRed
            case .received, .receivable:
                amountLabel.textColor = .systemGreen
            }
        }
        
        if let typeLabel = cell.viewWithTag(3) as? UILabel {
            typeLabel.text = transaction.type.rawValue
        }
        
        if let dateLabel = cell.viewWithTag(4) as? UILabel {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateLabel.text = formatter.string(from: transaction.date)
        }
    }
    
    // MARK: - Swipe to Delete Transaction (FIXED)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            // Get the transaction to delete based on whether we're showing filtered results
            let displayedTransactions = self.isFiltering ? self.filteredTransactions : self.transactions
            guard indexPath.row < displayedTransactions.count else {
                completionHandler(false)
                return
            }
            
            let transactionToDelete = displayedTransactions[indexPath.row]
            
            // Remove from main transactions array
            if self.isFiltering {
                // Find the index of this transaction in the main array
                if let mainIndex = self.transactions.firstIndex(where: {
                    $0.description == transactionToDelete.description &&
                    $0.amount == transactionToDelete.amount &&
                    $0.date == transactionToDelete.date
                }) {
                    self.transactions.remove(at: mainIndex)
                }
                // Also remove from filtered array
                self.filteredTransactions.remove(at: indexPath.row)
            } else {
                // When not filtering, simply remove from main array
                self.transactions.remove(at: indexPath.row)
            }
            
            // Update account balance
            guard var updatedAccount = self.selectedAccount else {
                completionHandler(false)
                return
            }
            
            // Update balances based on transaction type
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
            
            // Update account with new transactions list
            updatedAccount.transactions = self.transactions
            self.selectedAccount = updatedAccount
            
            // Update UI
            self.updateBalanceLabels(account: updatedAccount)
            self.saveTransactions(account: updatedAccount)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func updateBalanceLabels(account: Account) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "TL"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        if let formattedCurrent = formatter.string(from: NSNumber(value: account.currentBalance)) {
            currentBalanceLabel.text = "Current: \(formattedCurrent)"
        } else {
            currentBalanceLabel.text = "Current: \(String(format: "%.2f", account.currentBalance)) TL"
        }
        
        if let formattedFuture = formatter.string(from: NSNumber(value: account.futureBalance)) {
            futureBalanceLabel.text = "Future: \(formattedFuture)"
        } else {
            futureBalanceLabel.text = "Future: \(String(format: "%.2f", account.futureBalance)) TL"
        }
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
    }
    
    // MARK: - Filter (IMPROVED)
    // MARK: - Filter (IMPROVED WITH OPTIONAL FILTERS)
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Filter Transactions", message: nil, preferredStyle: .alert)
        
        // Create local variables to track selections
        var shouldFilterByType = false
        var selectedType: TransactionType = self.selectedTransactionType
        
        // Use class properties for date ranges
        // Default dates are now only set when actually applying the filter
        
        // Transaction Type Picker
        alertController.addTextField { textField in
            textField.placeholder = "Select Transaction Type (Optional)"
            textField.tintColor = .clear
            textField.text = "All Types" // Default text when no type filter is selected
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            pickerView.tag = 1000 // Tag to identify in delegate methods
            
            // Add "All Types" option as first row
            // The picker view will show actual types from index 1 onwards
            
            textField.inputView = pickerView
        }
        
        // Start Date TextField
        alertController.addTextField { textField in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            textField.placeholder = "Select Start Date (Optional)"
            textField.tintColor = .clear
            textField.inputView = self.createDatePicker(for: textField, isStartDate: true)
            
            if let startDate = self.selectedStartDate {
                textField.text = formatter.string(from: startDate)
            }
        }
        
        // End Date TextField
        alertController.addTextField { textField in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            textField.placeholder = "Select End Date (Optional)"
            textField.tintColor = .clear
            textField.inputView = self.createDatePicker(for: textField, isStartDate: false)
            
            if let endDate = self.selectedEndDate {
                textField.text = formatter.string(from: endDate)
            }
        }
        
        // Inside filterButtonTapped function:
        let filterAction = UIAlertAction(title: "Apply Filter", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            var filters: [(Transaction) -> Bool] = []
            var isAnyFilterApplied = false
            
            // Get selected type from picker if available
            if let typeField = alertController.textFields?[0],
               typeField.text != "All Types" && !typeField.text!.isEmpty {
                isAnyFilterApplied = true
                filters.append { $0.type == self.selectedTransactionType }
            }
            
            // Add date range filters if selected
            if let startDateField = alertController.textFields?[1], !startDateField.text!.isEmpty,
               let startDate = self.selectedStartDate {
                isAnyFilterApplied = true
                filters.append { $0.date >= startDate }
            }
            
            if let endDateField = alertController.textFields?[2], !endDateField.text!.isEmpty,
               let endDate = self.selectedEndDate {
                isAnyFilterApplied = true
                // Include transactions on the end date (end of day)
                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                filters.append { $0.date <= endOfDay }
            }
            
            // Apply filters only if at least one filter is applied
            if isAnyFilterApplied {
                self.filteredTransactions = self.transactions.filter { transaction in
                    return filters.allSatisfy { filter in filter(transaction) }
                }
                self.isFiltering = true
            } else {
                // No filters selected, show all
                self.isFiltering = false
            }
            
            self.transactionsTableView.reloadData()
        }
        
        let clearAction = UIAlertAction(title: "Clear Filters", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.filteredTransactions = []
            self.isFiltering = false
            self.selectedStartDate = nil
            self.selectedEndDate = nil
            self.transactionsTableView.reloadData()
        }
        
        alertController.addAction(filterAction)
        alertController.addAction(clearAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    // Helper function to create a date picker for the given text field
    func createDatePicker(for textField: UITextField, isStartDate: Bool) -> UIView {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        
        // Set default date
        if isStartDate {
            datePicker.date = selectedStartDate ?? Date().addingTimeInterval(-30*24*60*60) // Default to last 30 days
        } else {
            datePicker.date = selectedEndDate ?? Date() // Default to today
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // Add action to capture the date selection
        datePicker.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            
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
        alertController.addTextField { textField in
            textField.placeholder = "Select Transaction Type"
            textField.tintColor = .clear
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
        alertController.addTextField { textField in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            textField.placeholder = "Select Date"
            textField.text = formatter.string(from: self.selectedDate)
            textField.tintColor = .clear
            
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            datePicker.date = self.selectedDate
            
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            }
            
            datePicker.addAction(UIAction(handler: { [weak self] _ in
                guard let self = self else { return }
                
                self.selectedDate = datePicker.date
                textField.text = formatter.string(from: datePicker.date)
            }), for: .valueChanged)
            
            textField.inputView = datePicker
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let description = alertController.textFields?[0].text, !description.isEmpty,
                  let amountText = alertController.textFields?[1].text,
                  let amount = Double(amountText) else {
                
                // Show error alert if validation fails
                let errorAlert = UIAlertController(
                    title: "Invalid Input",
                    message: "Please enter a valid description and amount.",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }
            
            let newTransaction = Transaction(
                description: description,
                amount: amount,
                type: self.selectedTransactionType,
                date: self.selectedDate
            )
            
            self.addTransaction(newTransaction)
        }
        
        alertController.addAction(addAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    // Extracted method to add transaction - makes testing easier
    // Extracted method to add transaction - makes testing easier
    func addTransaction(_ newTransaction: Transaction) {
        // Insert at the beginning for most recent first
        transactions.insert(newTransaction, at: 0)
        
        if var account = selectedAccount {
            // Update balances based on transaction type
            switch newTransaction.type {
            case .paid:
                account.currentBalance -= newTransaction.amount
            case .received:
                account.currentBalance += newTransaction.amount
            case .payable:
                account.futureBalance -= newTransaction.amount
            case .receivable:
                account.futureBalance += newTransaction.amount
            }
            
            account.transactions = transactions
            selectedAccount = account
            
            // Update UI
            updateBalanceLabels(account: account)
            saveTransactions(account: account)
            
            // If we're filtering and this transaction would be included, add it to filtered results
            if isFiltering {
                // Check if transaction matches current filter criteria
                var shouldInclude = true
                
                // If we're filtering by type and types don't match, exclude
                if let typeField = (self.presentedViewController as? UIAlertController)?.textFields?[0],
                   typeField.text != "All Types" && !typeField.text!.isEmpty &&
                    selectedTransactionType != newTransaction.type {
                    shouldInclude = false
                }
                
                // Date range filters
                if let startDate = selectedStartDate, newTransaction.date < startDate {
                    shouldInclude = false
                }
                
                if let endDate = selectedEndDate {
                    let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                    if newTransaction.date > endOfDay {
                        shouldInclude = false
                    }
                }
                
                if shouldInclude {
                    filteredTransactions.insert(newTransaction, at: 0)
                }
            }
            
            // Reload data
            transactionsTableView.reloadData()
        }
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
        // Save individual account
        let individualAccountKey = "account_\(account.email)"
        if let individualAccountData = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(individualAccountData, forKey: individualAccountKey)
        } else {
            print("Error: Could not save individual account.")
        }
        
        // Update account in saved accounts array
        let allAccountsKey = "savedAccounts"
        var currentAccountsArray: [Account] = []
        
        if let savedAccountsData = UserDefaults.standard.data(forKey: allAccountsKey),
           let decodedAccounts = try? JSONDecoder().decode([Account].self, from: savedAccountsData) {
            currentAccountsArray = decodedAccounts
        }
        
        // Find and update the account in the array
        if let index = currentAccountsArray.firstIndex(where: { $0.email == account.email }) {
            currentAccountsArray[index] = account
        } else {
            // If not found, add it (shouldn't happen in typical usage)
            currentAccountsArray.append(account)
        }
        
        // Save the updated accounts array
        if let updatedAccountsData = try? JSONEncoder().encode(currentAccountsArray) {
            UserDefaults.standard.set(updatedAccountsData, forKey: allAccountsKey)
        }
        
        // Save changes immediately
        UserDefaults.standard.synchronize()
    }
}

// MARK: - UIPickerView Extensions
extension AccountDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Modified picker view method to support "All Types" option
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1000 {
            // This is the filter picker, add +1 for "All Types" option
            return TransactionType.allCases.count + 1
        } else {
            // Regular transaction type picker for adding transactions
            return TransactionType.allCases.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1000 && row == 0 {
            // First row in filter picker is "All Types"
            return "All Types"
        } else if pickerView.tag == 1000 {
            // Subsequent rows in filter picker (subtract 1 to get correct index)
            return TransactionType.allCases[row - 1].rawValue
        } else {
            // Regular transaction type picker
            return TransactionType.allCases[row].rawValue
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1000 {
            // This is the filter picker
            if row == 0 {
                // "All Types" selected
                if let alert = self.presentedViewController as? UIAlertController,
                   let typeField = alert.textFields?.first {
                    typeField.text = "All Types"
                }
            } else {
                // Actual transaction type selected
                selectedTransactionType = TransactionType.allCases[row - 1]
                
                if let alert = self.presentedViewController as? UIAlertController,
                   let typeField = alert.textFields?.first {
                    typeField.text = selectedTransactionType.rawValue
                }
            }
        } else {
            // Regular transaction type picker for adding transactions
            selectedTransactionType = TransactionType.allCases[row]
            
            if let alert = self.presentedViewController as? UIAlertController,
               let typeField = alert.textFields?.first(where: { $0.placeholder == "Select Transaction Type" }) {
                typeField.text = selectedTransactionType.rawValue
            }
        }
    }
}

// MARK: - Helper Extension for KeyPath-based Filtering
extension Array {
    func filtered<T: Equatable>(by keyPath: KeyPath<Element, T>, equals value: T) -> [Element] {
        return self.filter { $0[keyPath: keyPath] == value }
    }
}
