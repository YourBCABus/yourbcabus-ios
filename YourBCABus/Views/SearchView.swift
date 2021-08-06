//
//  SearchView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI

struct SearchView<Content: View, SearchResultsContent: View>: UIViewControllerRepresentable {
    var content: Content
    var searchResultsContent: (String) -> SearchResultsContent
    
    init(@ViewBuilder _ content: () -> Content, searchResultsContent: @escaping (String) -> SearchResultsContent) {
        self.content = content()
        self.searchResultsContent = searchResultsContent
    }
    
    func makeUIViewController(context: Context) -> SearchViewController<Content, SearchResultsContent> {
        SearchViewController(rootView: content, searchResultsContent: searchResultsContent)
    }
    
    func updateUIViewController(_ uiViewController: SearchViewController<Content, SearchResultsContent>, context: Context) {
        uiViewController.rootView = content
        uiViewController.searchResultsContent = searchResultsContent
        uiViewController.updateSearchResults()
    }
}

class SearchViewController<Content: View, SearchResultsContent: View>: UIHostingController<Content>, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        updateSearchResults()
    }
    
    var searchResultsContent: (String) -> SearchResultsContent
    let searchController: UISearchController
    
    init(rootView: Content, searchResultsContent: @escaping (String) -> SearchResultsContent) {
        self.searchResultsContent = searchResultsContent
        searchController = UISearchController(searchResultsController: UIHostingController(rootView: searchResultsContent("")))
        super.init(rootView: rootView)
        searchController.searchResultsUpdater = self
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if let parent = parent {
            parent.navigationItem.searchController = searchController
            
            // TODO: Find a better place to put these cosmetic changes
            parent.navigationItem.hidesSearchBarWhenScrolling = false
            parent.navigationItem.largeTitleDisplayMode = .never
            
        }
    }
    
    func updateSearchResults() {
        let hostingController = searchController.searchResultsController as! UIHostingController<SearchResultsContent>
        hostingController.rootView = searchResultsContent(searchController.searchBar.text ?? "")
    }
}
