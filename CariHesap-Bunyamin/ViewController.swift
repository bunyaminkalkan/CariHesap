import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var accountsTableView: UITableView!
    var accounts: [Account] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Örnek hesaplar ekleyelim (gerçek uygulamada veritabanından veya başka bir kaynaktan alınır)
        accounts = [
            Account(name: "Ali Yılmaz", email: "ali@example.com", currentBalance: 1500.75, futureBalance: 1800.50),
            Account(name: "Ayşe Demir", email: "ayse@example.com", currentBalance: -250.20, futureBalance: 100.00)
        ]

        accountsTableView.dataSource = self
        accountsTableView.delegate = self
    }

    // MARK: - Table View Data Source Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)

        let account = accounts[indexPath.row]

        // Hücre içeriğini yapılandırın (etiketlere değerleri atayın)
        var accountNameLabel: UILabel? = cell.viewWithTag(1) as? UILabel
        if accountNameLabel == nil {
            accountNameLabel = UILabel()
            accountNameLabel?.tag = 1
            accountNameLabel?.frame = CGRect(x: 15, y: 10, width: 150, height: 20) // Örnek frame, Auto Layout ile daha iyi yönetilir
            cell.contentView.addSubview(accountNameLabel!)
        }
        accountNameLabel?.text = account.name

        var currentBalanceLabel: UILabel? = cell.viewWithTag(2) as? UILabel
        if currentBalanceLabel == nil {
            currentBalanceLabel = UILabel()
            currentBalanceLabel?.tag = 2
            currentBalanceLabel?.frame = CGRect(x: cell.contentView.frame.width - 165, y: 10, width: 150, height: 20) // Örnek frame
            currentBalanceLabel?.textAlignment = .right
            cell.contentView.addSubview(currentBalanceLabel!)
        }
        currentBalanceLabel?.text = "Güncel: \(String(format: "%.2f", account.currentBalance)) TL"

        var futureBalanceLabel: UILabel? = cell.viewWithTag(3) as? UILabel
        if futureBalanceLabel == nil {
            futureBalanceLabel = UILabel()
            futureBalanceLabel?.tag = 3
            futureBalanceLabel?.frame = CGRect(x: cell.contentView.frame.width - 165, y: 30, width: 150, height: 20) // Örnek frame
            futureBalanceLabel?.textAlignment = .right
            cell.contentView.addSubview(futureBalanceLabel!)
        }
        futureBalanceLabel?.text = "Gelecek: \(String(format: "%.2f", account.futureBalance)) TL"

        return cell
    }

    // MARK: - Table View Delegate Methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // İkinci ekrana geçiş burada yapılacak
        let selectedAccount = accounts[indexPath.row]
        performSegue(withIdentifier: "goToDetailScreen", sender: selectedAccount)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Adding New Account

    @IBAction func newAccountButtonTapped(_ sender: UIButton) {
        // Yeni hesap ekleme pop-up'ı burada gösterilecek
        let alertController = UIAlertController(title: "Add New Account", message: "Please enter account details.", preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Account Name"
        }

        alertController.addTextField { (textField) in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            guard let nameTextField = alertController.textFields?[0], let emailTextField = alertController.textFields?[1],
                  let name = nameTextField.text, let email = emailTextField.text, !name.isEmpty else { return }

            let newAccount = Account(name: name, email: email, currentBalance: 0.0, futureBalance: 0.0)
            self?.accounts.append(newAccount)
            self?.accountsTableView.reloadData()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Segue Preparation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreen", let detailVC = segue.destination as? AccountDetailViewController, let account = sender as? Account {
            detailVC.selectedAccount = account
        }
    }
}
