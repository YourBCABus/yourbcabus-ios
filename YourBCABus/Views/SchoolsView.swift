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
    @Binding var schoolID: String?
    @State var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var body: some View {
        SchoolsInternalView(result: result, onSelect: { id in
            schoolID = id
        }, selectedID: schoolID).onAppear {
            Network.shared.apollo.fetch(query: GetSchoolsQuery()) { result in
                self.result = result
            }
        }.edgesIgnoringSafeArea(.all).navigationBarTitle("Select Your School", displayMode: .inline)
    }
}

private struct SchoolsInternalView: UIViewControllerRepresentable {
    static let storyboard = UIStoryboard(name: "SchoolsView", bundle: nil)
    var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    var onSelect: (String) -> Void
    var selectedID: String?
    
    func makeUIViewController(context: Context) -> SchoolsViewController {
        let controller = Self.storyboard.instantiateInitialViewController() as! SchoolsViewController
        updateUIViewController(controller, context: context)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SchoolsViewController, context: Context) {
        uiViewController.result = result
        uiViewController.onSelect = onSelect
        uiViewController.selectedID = selectedID
        uiViewController.tableView.reloadData()
    }
}

class SchoolsViewController: UITableViewController, UISearchResultsUpdating {
    var selectedID: String? {
        didSet {
            if let resultsController = searchController?.searchResultsController as? SchoolsSearchResultsViewController {
                resultsController.selectedID = selectedID
                resultsController.tableView.reloadData()
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let resultsController = searchController.searchResultsController as! SchoolsSearchResultsViewController
        if let text = searchController.searchBar.text {
            switch result {
            case .none, .some(.failure(_)):
                resultsController.schools = []
            case .some(.success(let result)):
                if let data = result.data {
                    var predicates = [NSPredicate]()
                    let stringExpression = NSExpression(forConstantValue: text)
                    
                    let nameExpression = NSExpression(block: { (school, _, _) in
                        return (school as! GetSchoolsQuery.Data.School).name ?? "(unnamed school)"
                    }, arguments: nil)
                    let namePredicate = NSComparisonPredicate(leftExpression: nameExpression, rightExpression: stringExpression, modifier: .direct, type: .contains, options: [.caseInsensitive, .diacriticInsensitive])
                    predicates.append(namePredicate)
                    
                    let idExpression = NSExpression(block: { (school, _, _) in
                        return (school as! GetSchoolsQuery.Data.School).id
                    }, arguments: nil)
                    let idPredicate = NSComparisonPredicate(leftExpression: idExpression, rightExpression: stringExpression, modifier: .direct, type: .equalTo, options: [.caseInsensitive, .diacriticInsensitive])
                    predicates.append(idPredicate)
                    
                    let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                    resultsController.schools = data.schools.filter { predicate.evaluate(with: $0) }
                } else {
                    resultsController.schools = []
                }
            }
        } else {
            resultsController.schools = []
        }
        resultsController.selectedID = selectedID
        resultsController.tableView.reloadData()
    }
    
    var searchController: UISearchController?
    var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    var onSelect: ((String) -> Void)?
    
    override func viewDidLoad() {
        let resultsController = SchoolsInternalView.storyboard.instantiateViewController(withIdentifier: "searchResultsController") as! SchoolsSearchResultsViewController
        resultsController.onSelect = { [weak self] id in
            self?.onSelect?(id)
        }
        searchController = UISearchController(searchResultsController: resultsController)
        searchController!.searchResultsUpdater = self
    }
    
    override func didMove(toParent parent: UIViewController?) {
        // Painfully hacky, but hey, it's SwiftUI!
        if let parent = parent {
            parent.navigationItem.largeTitleDisplayMode = .never
            parent.navigationItem.searchController = searchController
            parent.navigationItem.hidesSearchBarWhenScrolling = false
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
        cell.accessoryType = .none
        switch result {
        case .none:
            cell.textLabel!.text = "Loading..."
        case .some(.success(let result)):
            if let data = result.data {
                cell.textLabel!.text = data.schools[indexPath.row].name ?? "(unnamed school)"
                if data.schools[indexPath.row].id == selectedID {
                    cell.accessoryType = .checkmark
                }
            } else {
                cell.textLabel!.text = "An error occurred. Please try again."
            }
        case .some(.failure(_)):
            cell.textLabel!.text = "An error occurred. Please try again."
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch result {
        case .none, .some(.failure(_)):
            return nil
        case .some(.success(let result)):
            if result.data != nil {
                return indexPath
            } else {
                return nil
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .some(.success(let result)) = result, let data = result.data {
            onSelect?(data.schools[indexPath.row].id)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

class SchoolsSearchResultsViewController: UITableViewController {
    var schools = [GetSchoolsQuery.Data.School]()
    var selectedID: String?
    var onSelect: ((String) -> Void)?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SchoolCell")!
        cell.textLabel!.text = schools[indexPath.row].name ?? "(unnamed school)"
        cell.accessoryType = schools[indexPath.row].id == selectedID ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect?(schools[indexPath.row].id)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
