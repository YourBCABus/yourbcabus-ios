//
//  ReloadControl.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/6/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Combine

struct ReloadControl: UIViewRepresentable {
    var endRefreshSubject: PassthroughSubject<Void, Never>
    var refresh: () -> Void
    
    func makeUIView(context: Context) -> ReloadControlUIView {
        let view = ReloadControlUIView()
        updateUIView(view, context: context)
        return view
    }
    
    func updateUIView(_ uiView: ReloadControlUIView, context: Context) {
        context.coordinator.parent = self
        uiView.coordinator = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        var cancellables = Set<AnyCancellable>()
        var parent: ReloadControl {
            didSet {
                subscribe()
            }
        }
        let refreshControl = UIRefreshControl()
        init(_ parent: ReloadControl) {
            self.parent = parent
            refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
            subscribe()
        }
        
        func subscribe() {
            cancellables.removeAll()
            parent.endRefreshSubject.sink { [weak self] in
                self?.refreshControl.endRefreshing()
            }.store(in: &cancellables)
        }
        
        @objc func handleRefresh() {
            parent.refresh()
        }
        
        func viewMoved(view: UIView) {
            var current = view
            while current.superview != nil && !(current is UIScrollView) {
                current = current.superview!
            }
            if let scrollView = current as? UIScrollView, scrollView.refreshControl !== refreshControl {
                scrollView.refreshControl = refreshControl
            }
        }
    }
    
    class ReloadControlUIView: UIView {
        weak var coordinator: Coordinator?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.viewMoved(view: self)
        }
    }
}
