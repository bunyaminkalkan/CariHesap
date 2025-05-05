import UIKit

class AccountDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var futureBalanceLabel: UILabel!
    
    var selectedAccount: Account?
    var transactions: [Transaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transactionsTableView.dataSource = self
        transactionsTableView.delegate = self
        
        if let account = selectedAccount {
            updateBalanceLabels(account: account)
            
            // Örnek hareketler (gerçek uygulamada veritabanından alınır)
            transactions = [
                Transaction(description: "March Rent", amount: -500.0, type: .paid),
                Transaction(description: "April Sales", amount: 800.0, type: .received)
            ]
            transactionsTableView.reloadData()
        }
    }
    
    func updateBalanceLabels(account: Account) {
        currentBalanceLabel.text = "Current: \(String(format: "%.2f", account.currentBalance)) TL"
        futureBalanceLabel.text = "Future: \(String(format: "%.2f", account.futureBalance)) TL"
    }
    
    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        
        let transaction = transactions[indexPath.row]
        
        var descriptionLabel: UILabel? = cell.viewWithTag(1) as? UILabel
        if descriptionLabel == nil {
            descriptionLabel = UILabel()
            descriptionLabel?.tag = 1
            descriptionLabel?.frame = CGRect(x: 15, y: 15, width: 200, height: 20)
            cell.contentView.addSubview(descriptionLabel!)
        }
        descriptionLabel?.text = transaction.description
        
        var amountLabel: UILabel? = cell.viewWithTag(2) as? UILabel
        if amountLabel == nil {
            amountLabel = UILabel()
            amountLabel?.tag = 2
            amountLabel?.frame = CGRect(x: cell.contentView.frame.width - 115, y: 15, width: 100, height: 20)
            amountLabel?.textAlignment = .right
            cell.contentView.addSubview(amountLabel!)
        }
        amountLabel?.text = "\(String(format: "%.2f", transaction.amount)) TL"
        
        return cell
    }
    
    // MARK: - Adding New Transaction
    
    @IBAction func newTransactionButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add New Transaction", message: "Please enter transaction details.", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Description"
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        let typeActionSheet = UIAlertController(title: "Select Transaction Type", message: nil, preferredStyle: .actionSheet)
        
        for type in TransactionType.allCases {
            let action = UIAlertAction(title: type.rawValue, style: .default) { [weak self, weak alertController] (_) in
                guard let textFields = alertController?.textFields, textFields.count == 2,
                      let description = textFields[0].text, !description.isEmpty,
                      let amountText = textFields[1].text, !amountText.isEmpty,
                      let amount = Double(amountText) else {
                    // Kullanıcı geçerli bir açıklama ve miktar girmediyse bir hata mesajı gösterebilirsiniz.
                    return
                }
                
                let newTransaction = Transaction(description: description, amount: amount, type: type)
                self?.transactions.append(newTransaction)
                
                if var currentAccount = self?.selectedAccount {
                    let updatedCurrentBalance = currentAccount.currentBalance + (newTransaction.type == .received ? newTransaction.amount : -newTransaction.amount)
                    let updatedFutureBalance = currentAccount.futureBalance + (newTransaction.type == .received ? newTransaction.amount : -newTransaction.amount)
                    
                    let updatedAccount = Account(name: currentAccount.name,
                                                 email: currentAccount.email,
                                                 currentBalance: updatedCurrentBalance,
                                                 futureBalance: updatedFutureBalance)
                    self?.selectedAccount = updatedAccount
                    self?.updateBalanceLabels(account: updatedAccount)
                    self?.transactionsTableView.reloadData()
                }
            }
            typeActionSheet.addAction(action)
        }
        
        typeActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Next", style: .default) { [weak self, weak alertController] _ in
            guard let textFields = alertController?.textFields, textFields.count == 2,
                  let description = textFields[0].text, !description.isEmpty,
                  let amountText = textFields[1].text, !amountText.isEmpty,
                  let amount = Double(amountText) else {
                // Kullanıcı geçerli bir açıklama ve miktar girmediyse bir hata mesajı gösterebilirsiniz.
                return
            }
            self?.present(typeActionSheet, animated: true, completion: nil)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true, completion: nil)
    }}
