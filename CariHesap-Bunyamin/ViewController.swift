import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var accountsTableView: UITableView!
    var accounts: [Account] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Örnek hesaplar ekleyelim (gerçek uygulamada veritabanından veya başka bir kaynaktan alınır)
        loadAccountsFromUserDefaults()
        
        accountsTableView.dataSource = self
        accountsTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAccountsFromUserDefaults() // UserDefaults'tan verileri yükle
        accountsTableView.reloadData() // Tabloyu yeniden yükle
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
        let alertController = UIAlertController(title: "Yeni Hesap Ekle", message: "Hesap bilgilerini girin.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "İsim"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "E-posta"
            textField.keyboardType = .emailAddress
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Güncel Bakiye"
            textField.keyboardType = .decimalPad
        }
        
        let saveAction = UIAlertAction(title: "Kaydet", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alertController.textFields?[0].text, !name.isEmpty,
                  let email = alertController.textFields?[1].text,
                  let balanceText = alertController.textFields?[2].text,
                  let currentBalance = Double(balanceText) else {
                return
            }
            
            let newAccount = Account(name: name, email: email, currentBalance: currentBalance, futureBalance: currentBalance, transactions: [])
            self.accounts.append(newAccount)
            self.saveAccountsToUserDefaults()
            self.accountsTableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    
    func saveAccountsToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encodedData, forKey: "savedAccounts")
        }
    }
    
    func loadAccountsFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "savedAccounts"),
           let decodedAccounts = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decodedAccounts
        }
    }
    
    
    // MARK: - Segue Preparation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreen",
           let destinationVC = segue.destination as? AccountDetailViewController,
           let selectedIndexPath = accountsTableView.indexPathForSelectedRow {
            
            let selectedAccount = accounts[selectedIndexPath.row]
            destinationVC.selectedAccount = selectedAccount
        }
    }
}
