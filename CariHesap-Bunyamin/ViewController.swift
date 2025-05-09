import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var accountsTableView: UITableView!
    var accounts: [Account] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAccountsFromUserDefaults()  // Load data from database or UserDefaults
        accountsTableView.dataSource = self
        accountsTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAccountsFromUserDefaults()  // Load updated data from UserDefaults
        accountsTableView.reloadData()  // Reload the table
    }
    
    // MARK: - Table View Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        
        let account = accounts[indexPath.row]
        
        var accountNameLabel: UILabel? = cell.viewWithTag(1) as? UILabel
        if accountNameLabel == nil {
            accountNameLabel = UILabel()
            accountNameLabel?.tag = 1
            cell.contentView.addSubview(accountNameLabel!)
        }
        accountNameLabel?.text = account.name
        
        var currentBalanceLabel: UILabel? = cell.viewWithTag(2) as? UILabel
        if currentBalanceLabel == nil {
            currentBalanceLabel = UILabel()
            currentBalanceLabel?.tag = 2
            cell.contentView.addSubview(currentBalanceLabel!)
        }
        currentBalanceLabel?.text = "Current: \(String(format: "%.2f", account.currentBalance)) TL"
        
        var futureBalanceLabel: UILabel? = cell.viewWithTag(3) as? UILabel
        if futureBalanceLabel == nil {
            futureBalanceLabel = UILabel()
            futureBalanceLabel?.tag = 3
            cell.contentView.addSubview(futureBalanceLabel!)
        }
        futureBalanceLabel?.text = "Future: \(String(format: "%.2f", account.futureBalance)) TL"
        
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAccount = accounts[indexPath.row]
        performSegue(withIdentifier: "goToDetailScreen", sender: selectedAccount)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Adding New Account
    
    func loadAccountsFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "savedAccounts"),
           let decodedAccounts = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decodedAccounts
        }
    }
    
    func saveAccountsToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encodedData, forKey: "savedAccounts")
        }
    }
    
    @IBAction func newAccountButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add New Account", message: "Enter account details.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Name"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Current Balance"
            textField.keyboardType = .decimalPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alertController.textFields?[0].text, !name.isEmpty,
                  let email = alertController.textFields?[1].text,
                  let balanceText = alertController.textFields?[2].text,
                  let currentBalance = Double(balanceText) else {
                return
            }
            
            let newAccount = Account(name: name, email: email, currentBalance: currentBalance, futureBalance: currentBalance, transactions: [])
            self.accounts.append(newAccount)
            self.saveAccountsToUserDefaults() // Save updated accounts
            self.accountsTableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    
    // MARK: - Segue Preparation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreen",
           let destinationVC = segue.destination as? AccountDetailViewController,
           let selectedAccount = sender as? Account { // Directly cast sender to Account
            
            destinationVC.selectedAccount = selectedAccount
        }
    }
}
