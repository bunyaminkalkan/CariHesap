import UIKit

class ViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet private weak var accountsTableView: UITableView!
    @IBOutlet private weak var gradientView: UIView!
    
    // MARK: - Private Properties
    private var accounts: [Account] = []
    
    // MARK: - Constants
    private enum Constants {
        static let accountCellIdentifier = "AccountCell"
        static let detailSegueIdentifier = "goToDetailScreen"
        static let userDefaultsKey = "savedAccounts"
    }
    
    // MARK: - Lazy Properties
    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "TL"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshAccountsList()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        addGradientBackground()
        setupTableView()
        loadAccounts()
    }
    
    private func addGradientBackground() {
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
    
    private func setupTableView() {
        accountsTableView.dataSource = self
        accountsTableView.delegate = self
        accountsTableView.tableFooterView = UIView() // Removes empty cell separators
    }
    
    // MARK: - Data Management
    private func refreshAccountsList() {
        loadAccounts()
        accountsTableView.reloadData()
    }
    
    private func loadAccounts() {
        accounts = UserDefaults.standard.decodeData(
            forKey: Constants.userDefaultsKey,
            type: [Account].self
        ) ?? []
    }
    
    private func saveAccounts() {
        UserDefaults.standard.encodeAndSave(
            accounts,
            forKey: Constants.userDefaultsKey
        )
    }
    
    // MARK: - Actions
    @IBAction func newAccountButtonTapped(_ sender: UIButton) {
        presentNewAccountAlert()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == Constants.detailSegueIdentifier,
            let destinationVC = segue.destination as? AccountDetailViewController,
            let selectedAccount = sender as? Account
        else { return }
        
        destinationVC.selectedAccount = selectedAccount
    }
    
    // MARK: - Account Creation
    private func presentNewAccountAlert() {
        let alertController = UIAlertController(
            title: "New Account",
            message: "Please enter account details.",
            preferredStyle: .alert
        )
        
        // Configure text fields
        alertController.addTextField { textField in
            textField.placeholder = "Name"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Balance"
            textField.keyboardType = .decimalPad
        }
        
        // Create actions
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.createNewAccount(from: alertController)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Add actions
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func createNewAccount(from alert: UIAlertController) {
        guard
            let textFields = alert.textFields,
            textFields.count == 3,
            let name = textFields[0].text, !name.isEmpty,
            let email = textFields[1].text, !email.isEmpty,
            let balanceText = textFields[2].text,
            let currentBalance = Double(balanceText)
        else {
            showValidationErrorAlert()
            return
        }
        
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
    
    private func showValidationErrorAlert() {
        let errorAlert = UIAlertController(
            title: "Invalid Input",
            message: "Please fill in all fields correctly.",
            preferredStyle: .alert
        )
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(errorAlert, animated: true)
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
        
        configureCell(cell, with: accounts[indexPath.row])
        return cell
    }
    
    private func configureCell(_ cell: UITableViewCell, with account: Account) {
        guard
            let accountNameLabel = cell.viewWithTag(1) as? UILabel,
            let currentBalanceLabel = cell.viewWithTag(2) as? UILabel,
            let futureBalanceLabel = cell.viewWithTag(3) as? UILabel
        else { return }
        
        accountNameLabel.text = account.name
        currentBalanceLabel.text = formatCurrency(account.currentBalance)
        futureBalanceLabel.text = formatCurrency(account.futureBalance)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ??
               "\(String(format: "%.2f", amount)) TL"
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

// MARK: - UserDefaults Extension
extension UserDefaults {
    func decodeData<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func encodeAndSave<T: Encodable>(_ value: T, forKey key: String) {
        guard let encoded = try? JSONEncoder().encode(value) else {
            print("Error: Could not encode data")
            return
        }
        set(encoded, forKey: key)
        synchronize()
    }
}
