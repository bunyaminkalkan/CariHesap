import UIKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet private weak var accountsTableView: UITableView!
    @IBOutlet weak var gradientView: UIView!
    
    private var accounts: [Account] = []
    
    // MARK: - Cell Identifiers
    
    private enum Constants {
        static let accountCellIdentifier = "AccountCell"
        static let detailSegueIdentifier = "goToDetailScreen"
        static let userDefaultsKey = "savedAccounts"
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGradientBackground()
        setupTableView()
        loadAccounts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAccounts()
        accountsTableView.reloadData()
    }
    
    //MAARK: - Gradient
    func addGradientBackground() {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = gradientView.bounds
            gradientLayer.colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemGreen.cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)

            gradientView.layer.insertSublayer(gradientLayer, at: 0)
        }
    
    // MARK: - Setup
    
    private func setupTableView() {
        accountsTableView.dataSource = self
        accountsTableView.delegate = self
        accountsTableView.tableFooterView = UIView() // Removes empty cell separators
    }
    
    // MARK: - Actions
    
    @IBAction func newAccountButtonTapped(_ sender: UIButton) {
        presentNewAccountAlert()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.detailSegueIdentifier,
           let destinationVC = segue.destination as? AccountDetailViewController,
           let selectedAccount = sender as? Account {
            destinationVC.selectedAccount = selectedAccount
        }
    }
    
    // MARK: - Private Methods
    
    private func presentNewAccountAlert() {
        let alertController = UIAlertController(
            title: "New Account",
            message: "Please enter account details.",
            preferredStyle: .alert
        )
        
        alertController.addTextField { $0.placeholder = "Name" }
        alertController.addTextField {
            $0.placeholder = "Email"
            $0.keyboardType = .emailAddress
        }
        alertController.addTextField {
            $0.placeholder = "Balance"
            $0.keyboardType = .decimalPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.handleNewAccountCreation(from: alertController)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func handleNewAccountCreation(from alert: UIAlertController) {
        guard
            let name = alert.textFields?[0].text, !name.isEmpty,
            let email = alert.textFields?[1].text,
            let balanceText = alert.textFields?[2].text,
            let currentBalance = Double(balanceText)
        else { return }
        
        let newAccount = Account(
            name: name,
            email: email,
            currentBalance: currentBalance,
            futureBalance: currentBalance,
            transactions: []
        )
        
        accounts.append(newAccount)
        saveAccounts()
        accountsTableView.reloadData()
    }
    
    // MARK: - UserDefaults
    
    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: Constants.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decoded
        } else {
            accounts = []
        }
    }
    
    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: Constants.userDefaultsKey)
        }
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.accountCellIdentifier,
            for: indexPath
        )
        
        let account = accounts[indexPath.row]
        
        if let accountNameLabel = cell.viewWithTag(1) as? UILabel {
            accountNameLabel.text = account.name
        }
        
        if let currentBalanceLabel = cell.viewWithTag(2) as? UILabel {
            currentBalanceLabel.text = "\(String(format: "%.2f", account.currentBalance)) TL"
        }
        
        if let futureBalanceLabel = cell.viewWithTag(3) as? UILabel {
            futureBalanceLabel.text = "\(String(format: "%.2f", account.futureBalance)) TL"
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAccount = accounts[indexPath.row]
        performSegue(withIdentifier: Constants.detailSegueIdentifier, sender: selectedAccount)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            self?.deleteAccount(at: indexPath)
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteAccount(at indexPath: IndexPath) {
        accounts.remove(at: indexPath.row)
        saveAccounts()
        accountsTableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
