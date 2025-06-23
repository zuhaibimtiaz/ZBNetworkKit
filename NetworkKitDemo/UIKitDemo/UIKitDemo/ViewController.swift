//
//  ViewController.swift
//  UIKitDemo
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//
import UIKit
import Combine
import ZBNetworkKit

class ViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let tableView = UITableView()
    private let uploadButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    
    private var users: [User] = []
    private let apiRequest = ApiRequest<[User]>(endpoint: UserEndpoint()) // Hold reference to request
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ZBNetworkKit
            .configure(
                .init(
                    baseURL: .init(url: "jsonplaceholder.typicode.com"),
                    isLogging: true
                )
            )
        setupUI()
        setupBindings()
        fetchUsers()
    }
    
    private func setupUI() {
        title = "NetworkKit Demo"
        view.backgroundColor = .white
        
        // TableView
        tableView.frame = CGRect(x: 0, y: 100, width: view.bounds.width, height: 500)
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        view.addSubview(tableView)
        
        
        // Activity Indicator
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        
        // Status Label
        statusLabel.frame = CGRect(x: 20, y: 370, width: view.bounds.width - 40, height: 40)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
    }
    
    private func setupBindings() {
        // Users Binding
        apiRequest.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let userList):
                    self?.users = userList
                    self?.tableView.reloadData()
                case .failure(let error):
                    Log.error("Failed to fetch users: \(error)")
                    break
                }
            }
            .store(in: &cancellables)
        
    }
    
    private func fetchUsers() {
        activityIndicator.startAnimating()
        Task { await apiRequest.fetch() }
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = users[indexPath.row]
            cell.textLabel?.text = user.name
            cell.detailTextLabel?.text = user.email
        return cell
    }
}
