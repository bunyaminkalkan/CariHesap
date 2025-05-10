import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var accountsTableView: UITableView!
    var accounts: [Account] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountsTableView.dataSource = self
        accountsTableView.delegate = self
        loadAccountsFromUserDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAccountsFromUserDefaults()
        accountsTableView.reloadData()
    }
    
    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        let account = accounts[indexPath.row]
        
        var accountNameLabel = cell.viewWithTag(1) as? UILabel
        accountNameLabel?.text = account.name
        
        var currentBalanceLabel = cell.viewWithTag(2) as? UILabel
        currentBalanceLabel?.text = "Current: \(String(format: "%.2f", account.currentBalance)) TL"
        
        var futureBalanceLabel = cell.viewWithTag(3) as? UILabel
        futureBalanceLabel?.text = "Future: \(String(format: "%.2f", account.futureBalance)) TL"
        
        return cell
    }
    
    // MARK: - Swipe to Delete
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // 1. Diziden sil
            self.accounts.remove(at: indexPath.row)
            
            // 2. UserDefaults’a güncellenmiş halini kaydet
            self.saveAccountsToUserDefaults()
            
            // 3. TableView’dan sil
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // MARK: - Add New Account
    
    @IBAction func newAccountButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Yeni Hesap", message: "Hesap bilgilerini giriniz.", preferredStyle: .alert)
        
        alertController.addTextField { $0.placeholder = "İsim" }
        alertController.addTextField {
            $0.placeholder = "Email"
            $0.keyboardType = .emailAddress
        }
        alertController.addTextField {
            $0.placeholder = "Bakiye"
            $0.keyboardType = .decimalPad
        }
        
        let saveAction = UIAlertAction(title: "Kaydet", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            guard
                let name = alertController.textFields?[0].text, !name.isEmpty,
                let email = alertController.textFields?[1].text,
                let balanceText = alertController.textFields?[2].text,
                let currentBalance = Double(balanceText)
            else { return }
            
            let newAccount = Account(
                name: name,
                email: email,
                currentBalance: currentBalance,
                futureBalance: currentBalance,
                transactions: []
            )
            
            self.accounts.append(newAccount)
            self.saveAccountsToUserDefaults()
            self.accountsTableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    // MARK: - Navigation
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAccount = accounts[indexPath.row]
        performSegue(withIdentifier: "goToDetailScreen", sender: selectedAccount)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreen",
           let destinationVC = segue.destination as? AccountDetailViewController,
           let selectedAccount = sender as? Account {
            destinationVC.selectedAccount = selectedAccount
        }
    }
    
    // MARK: - UserDefaults
    
    func loadAccountsFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "savedAccounts"),
           let decoded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decoded
        } else {
            accounts = []
        }
    }
    
    func saveAccountsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: "savedAccounts")
        }
    }
}
