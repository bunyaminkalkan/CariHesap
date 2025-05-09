import UIKit


class AccountDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var futureBalanceLabel: UILabel!
    
    var selectedAccount: Account?
    var transactions: [Transaction] = []
    var selectedTransactionType: TransactionType = .received
    
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
        
        // Description Label'ı ayarla
        if let descriptionLabel = cell.viewWithTag(1) as? UILabel {
            descriptionLabel.text = transaction.description
        }
        
        // Amount Label'ı ayarla
        if let amountLabel = cell.viewWithTag(2) as? UILabel {
            amountLabel.text = "\(String(format: "%.2f", transaction.amount)) TL"
        }
        
        // Transaction Type Label'ı ayarla
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
        let alertController = UIAlertController(title: "Yeni İşlem", message: nil, preferredStyle: .alert)
        
        // Açıklama TextField
        alertController.addTextField { textField in
            textField.placeholder = "Açıklama"
        }
        
        // Tutar TextField
        alertController.addTextField { textField in
            textField.placeholder = "Tutar"
            textField.keyboardType = .decimalPad
        }
        
        // Transaction Type TextField (picker için)
        var typeTextField: UITextField?
        alertController.addTextField { textField in
            textField.placeholder = "İşlem Türü Seçin"
            textField.tintColor = .clear // cursor'u gizle
            typeTextField = textField
            
            // Picker ayarları
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            textField.inputView = pickerView
        }
        
        // Ekle Butonu
        let addAction = UIAlertAction(title: "Ekle", style: .default) { [weak self] _ in
            guard let self = self,
                  let desc = alertController.textFields?[0].text, !desc.isEmpty,
                  let amtStr = alertController.textFields?[1].text, let amount = Double(amtStr),
                  let selectedType = self.selectedTransactionType as TransactionType? else {
                return
            }
            
            let newTransaction = Transaction(description: desc, amount: amount, type: selectedType)
            self.transactions.append(newTransaction)
            
            // Hesabı güncelle
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
            self.saveTransactions()
            self.transactionsTableView.reloadData()
        }
        
        alertController.addAction(addAction)
        alertController.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    
    
    // MARK: - Persistence
    func loadTransactions() {
        guard let account = selectedAccount else { return }
        
        let accountKey = "account_\(account.email)"
        if let accData = UserDefaults.standard.data(forKey: accountKey),
           let savedAccount = try? JSONDecoder().decode(Account.self, from: accData) {
            selectedAccount = savedAccount
            transactions = savedAccount.transactions // Hesapla ilişkili işlemleri yükle
        }
    }
    
    func saveTransactions() {
        guard let account = selectedAccount else { return }
        
        let accountKey = "account_\(account.email)"
        if let accData = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(accData, forKey: accountKey)
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
        
        // Alert üzerindeki işlem türü textField'ını güncelle
        if let alert = self.presentedViewController as? UIAlertController,
           let typeField = alert.textFields?.first(where: { $0.placeholder == "İşlem Türü Seçin" }) {
            typeField.text = selectedTransactionType.rawValue
        }
    }
}
