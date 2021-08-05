//
//  MasterView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/2/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo

struct SchoolsView: View {
    @State var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    
    var body: some View {
        SchoolsInternalView(result: result).onAppear {
            Network.shared.apollo.fetch(query: GetSchoolsQuery()) { result in
                self.result = result
            }
        }.edgesIgnoringSafeArea(.all).navigationTitle("Schools")
    }
}

private struct SchoolsInternalView: UIViewControllerRepresentable {
    static let storyboard = UIStoryboard(name: "SchoolsView", bundle: nil)
    var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    
    func makeUIViewController(context: Context) -> SchoolsViewController {
        let controller = Self.storyboard.instantiateInitialViewController() as! SchoolsViewController
        updateUIViewController(controller, context: context)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SchoolsViewController, context: Context) {
        uiViewController.result = result
        uiViewController.tableView.reloadData()
    }
}

class SchoolsViewController: UITableViewController, UISearchControllerDelegate {
    var searchController: UISearchController?
    var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    
    override func viewDidLoad() {
        
    }
    
    override func didMove(toParent parent: UIViewController?) {
        // Painfully hacky, but hey, it's SwiftUI!
        if let parent = parent {
            parent.navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch result {
        case .none:
            return 1
        case .some(.success(let result)):
            if let data = result.data {
                return data.schools.count
            } else {
                return 1
            }
        case .some(.failure(_)):
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SchoolCell")!
        switch result {
        case .none:
            cell.textLabel!.text = "Loading..."
        case .some(.success(let result)):
            if let data = result.data {
                cell.textLabel!.text = data.schools[indexPath.row].name ?? "(unnamed school)"
            } else {
                cell.textLabel!.text = "An error occurred. Please try again."
            }
        case .some(.failure(_)):
            cell.textLabel!.text = "An error occurred. Please try again."
        }
        return cell
    }
}
